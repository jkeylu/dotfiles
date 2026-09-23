#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
JDEV="${REPO_DIR}/scripts/tools/jdev"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/jdev-test.XXXXXX")"
TEST_HOME="${TEST_ROOT}/user home"
FAKE_BIN="${TEST_ROOT}/bin"
JDK_ROOT="${TEST_ROOT}/jdk installations"
GRADLE_INSTALL="${TEST_ROOT}/gradle home"
EVENTS="${TEST_ROOT}/events"
OUTPUT="${TEST_ROOT}/output"
BASE_PATH="$PATH"
TESTS=0
FAILURES=0
JDEV_PID=""

cleanup() {
  if [[ -n "$JDEV_PID" ]] && kill -0 "$JDEV_PID" 2>/dev/null; then
    kill -TERM "$JDEV_PID" 2>/dev/null || true
    wait "$JDEV_PID" 2>/dev/null || true
  fi
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

pass() { ((TESTS += 1)); }
fail() {
  ((TESTS += 1, FAILURES += 1))
  printf 'FAIL: %s\n' "$1" >&2
  [[ ! -f "$OUTPUT" ]] || cat "$OUTPUT" >&2
}
assert_file() { [[ -f "$1" ]] && pass || fail "$2"; }
assert_absent() { [[ ! -e "$1" ]] && pass || fail "$2"; }
assert_contains() { grep -Fq -- "$2" "$1" && pass || fail "$3"; }
assert_not_contains() { ! grep -Fq -- "$2" "$1" && pass || fail "$3"; }
assert_status() { [[ "$STATUS" -eq "$1" ]] && pass || fail "$2 (exit $STATUS)"; }

event_count() {
  local count
  count="$(grep -Fc -- "$1" "$EVENTS" 2>/dev/null || true)"
  printf '%s' "${count:-0}"
}

wait_for_event() {
  local event="$1" expected="$2" i
  for ((i = 0; i < 100; i++)); do
    if (( $(event_count "$event") >= expected )); then
      pass
      return 0
    fi
    sleep 0.1
  done
  fail "timed out waiting for $expected '$event' events"
  return 1
}

run_once() {
  local directory="$1"
  shift
  set +e
  (cd "$directory" && bash "$JDEV" "$@") >"$OUTPUT" 2>&1
  STATUS=$?
  set -e
}

start_jdev() {
  local directory="$1"
  shift
  : >"$EVENTS"
  : >"$OUTPUT"
  (cd "$directory" && exec bash "$JDEV" --poll 0.1 --delay 0 "$@") >"$OUTPUT" 2>&1 &
  JDEV_PID=$!
  wait_for_event 'java-start|' 1
}

stop_jdev() {
  if [[ -n "$JDEV_PID" ]]; then
    kill -TERM "$JDEV_PID" 2>/dev/null || true
    wait "$JDEV_PID" 2>/dev/null || true
    JDEV_PID=""
  fi
}

make_jdk() {
  local directory="$1" version="$2"
  mkdir -p "$directory/bin"
  printf 'JAVA_VERSION="%s"\n' "$version" >"$directory/release"
  cat >"$directory/bin/java" <<'EOF'
#!/usr/bin/env bash
home="$(cd "$(dirname "$0")/.." && pwd -P)"
version="$(sed -n 's/^JAVA_VERSION="\(.*\)"$/\1/p' "$home/release")"
if [[ "${1-}" == -version ]]; then
  printf 'openjdk version "%s"\n' "$version" >&2
  exit 0
fi
jar=""
previous=""
for argument in "$@"; do
  [[ "$previous" != -jar ]] || jar="$argument"
  previous="$argument"
done
printf 'java-start|%s|%s|%s|%s|%s|%s\n' "$version" "${JAVA_HOME-}" "${SPRING_PROFILES_ACTIVE-}" "${APP_TOKEN-}" "$(cat "$jar")" "$*" >>"$JDEV_FAKE_LOG"
trap 'printf "java-stop|%s\n" "$$" >>"$JDEV_FAKE_LOG"; exit 0' TERM INT
while :; do sleep 0.1; done
EOF
  chmod +x "$directory/bin/java"
}

mkdir -p "$TEST_HOME" "$FAKE_BIN" "$JDK_ROOT" "$GRADLE_INSTALL/bin"
make_jdk "$JDK_ROOT/jdk-17.0.1" 17.0.1
make_jdk "$JDK_ROOT/jdk-17.0.9" 17.0.9
make_jdk "$JDK_ROOT/jdk-21" 21.0.2
JDK_17="$JDK_ROOT/jdk-17.0.9"
JDK_21="$JDK_ROOT/jdk-21"

cat >"$FAKE_BIN/mvn" <<'EOF'
#!/usr/bin/env bash
printf 'maven|%s|%s\n' "${JAVA_HOME-}" "$*" >>"$JDEV_FAKE_LOG"
[[ ! -f build-fail ]] || exit 1
mkdir -p target
printf 'maven-good' >target/app.jar
printf 'maven-original' >target/original-app.jar
EOF
cat >"$FAKE_BIN/gradle" <<'EOF'
#!/usr/bin/env bash
printf 'gradle|%s|%s|%s\n' "$0" "${JAVA_HOME-}" "$*" >>"$JDEV_FAKE_LOG"
[[ ! -f build-fail ]] || exit 1
mkdir -p build/libs
printf 'gradle-good' >build/libs/app.jar
printf 'gradle-plain' >build/libs/app-plain.jar
EOF
cp "$FAKE_BIN/gradle" "$GRADLE_INSTALL/bin/gradle"
cat >"$FAKE_BIN/java" <<'EOF'
#!/usr/bin/env bash
exec "$JDEV_FAKE_PATH_JAVA" "$@"
EOF
chmod +x "$FAKE_BIN/mvn" "$FAKE_BIN/gradle" "$FAKE_BIN/java" "$GRADLE_INSTALL/bin/gradle"
export HOME="$TEST_HOME" JDK_HOME="$JDK_ROOT" JDEV_FAKE_LOG="$EVENTS"
export JDEV_FAKE_PATH_JAVA="$JDK_21/bin/java"
export PATH="$FAKE_BIN:$BASE_PATH"
unset JAVA_HOME MAVEN_HOME GRADLE_HOME SPRING_BOOT_PROJECT_DIR SPRING_BOOT_BUILD_TOOL
: >"$EVENTS"

MAVEN_PROJECT="${TEST_ROOT}/maven app"
GRADLE_PROJECT="${TEST_ROOT}/gradle app"
mkdir -p "$MAVEN_PROJECT/src/main/java" "$GRADLE_PROJECT/src/main/java"
cat >"$MAVEN_PROJECT/pom.xml" <<'EOF'
<project>
  <!-- <java.version>8</java.version> -->
  <properties><java.version>17</java.version></properties>
  <dependency>spring-boot</dependency>
</project>
EOF
printf 'class App {}\n' >"$MAVEN_PROJECT/src/main/java/App.java"
cat >"$GRADLE_PROJECT/build.gradle.kts" <<'EOF'
/* JavaLanguageVersion.of(17) */
java { toolchain { languageVersion.set(JavaLanguageVersion.of(21)) } }
EOF
printf 'class App {}\n' >"$GRADLE_PROJECT/src/main/java/App.java"

bash -n "$JDEV" && pass || fail 'jdev syntax check'
run_once "$TEST_ROOT" init --global
assert_status 0 'global init works outside a project'
assert_file "$TEST_HOME/.jdev.conf" 'global config is created'
if grep -Eq '^[[:space:]]*[^#[:space:]]' "$TEST_HOME/.jdev.conf"; then
  fail 'generated config contains an active setting'
else
  pass
fi
run_once "$TEST_ROOT" init --global
[[ "$STATUS" -ne 0 ]] && pass || fail 'global init protects existing file'
run_once "$TEST_ROOT" init --global --force
assert_status 0 'global init force overwrites'
run_once "$GRADLE_PROJECT" init
assert_status 0 'project init recognizes Gradle'
assert_file "$GRADLE_PROJECT/.jdev.conf" 'project config is created'
rm -f "$TEST_HOME/.jdev.conf" "$GRADLE_PROJECT/.jdev.conf"

start_jdev "$MAVEN_PROJECT"
assert_contains "$EVENTS" 'maven|' 'default Maven build runs'
assert_contains "$EVENTS" '-DskipTests package' 'Maven defaults are used'
assert_contains "$EVENTS" 'java-start|17.0.9|' 'project Java version picks newest matching patch'
assert_contains "$EVENTS" '|maven-good|' 'Maven JAR is selected'
stop_jdev
assert_absent "$MAVEN_PROJECT/target/.spring-boot-dev-run" 'Maven run files are cleaned'

cat >"$TEST_HOME/.jdev.conf" <<'EOF'
spring_profile=global
java_opt=-Dlayer=global
maven_arg=global-build
EOF
printf 'project_dir=%s\n' "$GRADLE_PROJECT" >>"$TEST_HOME/.jdev.conf"
printf 'env_file=global.env\n' >>"$TEST_HOME/.jdev.conf"
printf 'APP_TOKEN=global\n' >"$TEST_HOME/global.env"
cat >"$MAVEN_PROJECT/.jdev.conf" <<'EOF'
spring_profile=project
java_opt=-Dlayer=project
maven_arg=project-build
env_file=vars/project.env
EOF
mkdir -p "$MAVEN_PROJECT/vars"
printf 'APP_TOKEN=project\n' >"$MAVEN_PROJECT/vars/project.env"
start_jdev "$MAVEN_PROJECT"
assert_contains "$EVENTS" 'maven|' 'Maven builds with layered config'
assert_contains "$EVENTS" 'project-build' 'project build args replace global args'
assert_not_contains "$EVENTS" 'global-build' 'global build args are replaced'
assert_contains "$EVENTS" '|project|project|maven-good|-Dlayer=project' 'project scalar and relative path settings take precedence'
stop_jdev

start_jdev "$MAVEN_PROJECT" --profile cli --maven-arg cli-build --java-opt=-Dlayer=cli -- --server.port=9090
assert_contains "$EVENTS" 'cli-build' 'CLI build args replace project args'
assert_not_contains "$EVENTS" 'project-build' 'project build args are replaced by CLI'
assert_contains "$EVENTS" '|cli|project|maven-good|-Dlayer=cli' 'CLI scalar and Java opts win'
assert_contains "$EVENTS" '--server.port=9090' 'application arguments after -- are preserved'
stop_jdev
rm -f "$TEST_HOME/.jdev.conf" "$MAVEN_PROJECT/.jdev.conf"

cat >"$GRADLE_PROJECT/gradlew" <<'EOF'
#!/usr/bin/env bash
printf 'wrapper|%s\n' "$*" >>"$JDEV_FAKE_LOG"
exec "$JDEV_FAKE_GRADLE" "$@"
EOF
chmod +x "$GRADLE_PROJECT/gradlew"
export JDEV_FAKE_GRADLE="$FAKE_BIN/gradle" GRADLE_HOME="$GRADLE_INSTALL"
printf '<project/>\n' >"$GRADLE_PROJECT/pom.xml"
run_once "$GRADLE_PROJECT" --poll 0.1 --delay 0
[[ "$STATUS" -ne 0 ]] && pass || fail 'ambiguous Maven and Gradle project fails'
assert_contains "$OUTPUT" '同时找到 Maven 和 Gradle' 'ambiguous project explains the error'
start_jdev "$GRADLE_PROJECT" --build-tool gradle
assert_contains "$EVENTS" 'wrapper|' 'Gradle wrapper wins over GRADLE_HOME'
assert_contains "$EVENTS" 'build -x test' 'Gradle defaults are used'
assert_contains "$EVENTS" 'java-start|21.0.2|' 'Gradle toolchain version selects JDK'
assert_contains "$EVENTS" '|gradle-good|' 'plain JAR is ignored'
printf 'customProperty=one\n' >"$GRADLE_PROJECT/gradle.properties"
wait_for_event 'java-start|' 2
stop_jdev
assert_absent "$GRADLE_PROJECT/build/.spring-boot-dev-run" 'Gradle run files are cleaned'

start_jdev "$GRADLE_PROJECT" --build-tool gradle --gradle-home "$GRADLE_INSTALL"
assert_not_contains "$EVENTS" 'wrapper|' 'explicit Gradle home overrides wrapper'
assert_contains "$EVENTS" "$GRADLE_INSTALL/bin/gradle" 'explicit Gradle home executable runs'
stop_jdev

mv "$GRADLE_PROJECT/gradlew" "$GRADLE_PROJECT/gradlew.saved"
rm -f "$GRADLE_PROJECT/pom.xml"
start_jdev "$GRADLE_PROJECT"
assert_contains "$EVENTS" "$GRADLE_INSTALL/bin/gradle" 'GRADLE_HOME is used without wrapper'
stop_jdev
unset GRADLE_HOME
start_jdev "$GRADLE_PROJECT"
assert_contains "$EVENTS" "$FAKE_BIN/gradle" 'Gradle runs from PATH without config'
stop_jdev

printf 'java { toolchain { languageVersion.set(JavaLanguageVersion.of(22)) } }\n' >"$GRADLE_PROJECT/build.gradle.kts"
export JAVA_HOME="$JDK_17"
run_once "$GRADLE_PROJECT"
[[ "$STATUS" -ne 0 ]] && pass || fail 'unavailable Java version fails'
assert_contains "$OUTPUT" '未找到 Java 22' 'unavailable Java version is reported'
printf 'java { toolchain { languageVersion.set(JavaLanguageVersion.of(21)) } }\n' >"$GRADLE_PROJECT/build.gradle.kts"
ONLY_17_ROOT="${TEST_ROOT}/only 17"
make_jdk "$ONLY_17_ROOT/jdk-17" 17.0.3
export JDK_HOME="$ONLY_17_ROOT" JAVA_HOME="$JDK_21"
start_jdev "$GRADLE_PROJECT"
assert_contains "$EVENTS" "java-start|21.0.2|$JDK_21|" 'matching JAVA_HOME is accepted for declared version'
stop_jdev
export JDK_HOME="$JDK_ROOT" JAVA_HOME="$JDK_17"
start_jdev "$GRADLE_PROJECT"
assert_contains "$EVENTS" 'java-start|21.0.2|' 'PATH Java is used when JDK_HOME and JAVA_HOME do not match'
stop_jdev

WINDOWS_JDK="$(cygpath -w "$JDK_17")"
start_jdev "$MAVEN_PROJECT" --java-home "$WINDOWS_JDK"
assert_contains "$EVENTS" 'java-start|17.0.9|' 'Windows path with spaces resolves as Java home'
stop_jdev
unset JAVA_HOME

NO_VERSION_PROJECT="${TEST_ROOT}/no version app"
mkdir -p "$NO_VERSION_PROJECT"
printf '<project><dependency>spring-boot</dependency></project>\n' >"$NO_VERSION_PROJECT/pom.xml"
start_jdev "$NO_VERSION_PROJECT"
assert_contains "$EVENTS" 'java-start|21.0.2|' 'PATH Java is used when project has no version'
assert_contains "$OUTPUT" '未识别项目 Java 版本，使用 PATH' 'Java fallback is explained'
stop_jdev

mkdir -p "${TEST_ROOT}/maven home/bin"
cp "$FAKE_BIN/mvn" "${TEST_ROOT}/maven home/bin/mvn"
chmod +x "${TEST_ROOT}/maven home/bin/mvn"
SAVED_PATH="$PATH"
export PATH="/usr/bin:/bin" MAVEN_HOME="${TEST_ROOT}/maven home"
start_jdev "$NO_VERSION_PROJECT"
assert_contains "$EVENTS" "java-start|21.0.2|$JDK_21|" 'highest JDK_HOME version is used as final fallback'
stop_jdev
export PATH="$SAVED_PATH"
unset MAVEN_HOME

printf 'APP_TOKEN=one\n' >"$MAVEN_PROJECT/.env"
start_jdev "$MAVEN_PROJECT"
assert_contains "$EVENTS" '|one|maven-good|' '.env is loaded at start'
printf 'class App { int value = 1; }\n' >"$MAVEN_PROJECT/src/main/java/App.java"
wait_for_event 'java-start|' 2
touch "$MAVEN_PROJECT/build-fail"
printf 'class App { int value = 22; }\n' >"$MAVEN_PROJECT/src/main/java/App.java"
wait_for_event 'maven|' 3
[[ "$(event_count 'java-start|')" -eq 2 ]] && pass || fail 'failed build does not restart service'
[[ "$(event_count 'java-stop|')" -eq 1 ]] && pass || fail 'failed build preserves old service'
rm -f "$MAVEN_PROJECT/build-fail"
printf 'class App { int value = 333; }\n' >"$MAVEN_PROJECT/src/main/java/App.java"
wait_for_event 'java-start|' 3
printf 'APP_TOKEN=two\n' >"$MAVEN_PROJECT/.env"
wait_for_event 'java-start|' 4
assert_contains "$EVENTS" '|two|maven-good|' '.env change is loaded on restart'
stop_jdev
wait_for_event 'java-stop|' 4
assert_absent "$MAVEN_PROJECT/target/.spring-boot-dev-run" 'run files are cleaned on exit'

printf '%d assertions, %d failures\n' "$TESTS" "$FAILURES"
(( FAILURES == 0 ))

# JDK 管理命令使用独立的临时环境，与项目运行测试共用本文件。
run_jdk_tests() (
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
JDEV="${REPO_DIR}/scripts/tools/jdev"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/jdev-jdk-test.XXXXXX")"
TEST_HOME="${TEST_ROOT}/user home"
FAKE_BIN="${TEST_ROOT}/bin"
BASE_PATH="$PATH"
EVENTS="${TEST_ROOT}/events"
OUTPUT_FILE="${TEST_ROOT}/output"
ASSERTIONS=0
FAILURES=0
JDEV_PID=""

cleanup() {
  if [[ -n "$JDEV_PID" ]] && kill -0 "$JDEV_PID" 2>/dev/null; then
    kill -TERM "$JDEV_PID" 2>/dev/null || true
    wait "$JDEV_PID" 2>/dev/null || true
  fi
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

pass() { ((ASSERTIONS += 1)); }
fail() {
  ((ASSERTIONS += 1, FAILURES += 1))
  printf 'FAIL: %s\n' "$1" >&2
  [[ ! -f "$OUTPUT_FILE" ]] || cat "$OUTPUT_FILE" >&2
}
assert_status() { [[ "$STATUS" -eq "$1" ]] && pass || fail "$2 (exit $STATUS)"; }
assert_contains() { [[ "$OUTPUT" == *"$1"* ]] && pass || fail "$2 (missing '$1')"; }
assert_file() { [[ -f "$1" ]] && pass || fail "$2"; }
assert_absent() { [[ ! -e "$1" ]] && pass || fail "$2"; }
assert_requested() { grep -Fq -- "$1" "$MOCK_CURL_LOG" && pass || fail "$2 (missing '$1' in API requests)"; }
assert_not_requested() { ! grep -Fq -- "$1" "$MOCK_CURL_LOG" && pass || fail "$2 (unexpected '$1' in API requests)"; }
assert_no_staging() {
  local staged
  for staged in "$1"/.jdev-install.*; do
    [[ ! -e "$staged" ]] || { fail "$2"; return; }
  done
  pass
}

run_jdev() {
  set +e
  OUTPUT="$(cd "$TEST_ROOT" && bash "$JDEV" "$@" 2>&1)"
  STATUS=$?
  set -e
  printf '%s\n' "$OUTPUT" >"$OUTPUT_FILE"
}

make_java_home() {
  local home="$1" version="$2" suffix="${3-}"
  mkdir -p "$home/bin"
  printf 'JAVA_VERSION="%s"\n' "$version" >"$home/release"
  cat >"$home/bin/java${suffix}" <<'EOF'
#!/usr/bin/env bash
if [[ "${1-}" == -version ]]; then
  printf 'openjdk version "%s"\n' "$(sed -n 's/^JAVA_VERSION="\(.*\)"$/\1/p' "$(dirname "$0")/../release")" >&2
  exit 0
fi
printf '%s\n' "${JAVA_HOME-}" >>"$TEST_JAVA_RUN_LOG"
trap 'exit 0' TERM INT
while :; do sleep 0.1; done
EOF
  chmod +x "$home/bin/java${suffix}"
}

make_zip() {
  local output="$1" payload="$2" top="$3"
  (cd "$payload" && perl -MIO::Compress::Zip -e '
    my ($output, @names) = @ARGV;
    my $first = shift @names;
    my $zip = IO::Compress::Zip->new($output, Name => $first) or die $IO::Compress::Zip::ZipError;
    open my $input, "<", $first or die $!;
    binmode $input; local $/; $zip->print(<$input>); close $input;
    for my $name (@names) {
      $zip->newStream(Name => $name) or die $IO::Compress::Zip::ZipError;
      open my $next, "<", $name or die $!;
      binmode $next; $zip->print(<$next>); close $next;
    }
    $zip->close() or die $IO::Compress::Zip::ZipError;
  ' "$output" "$top/release" "$top/bin/java.exe")
}

make_archive() {
  local type="$1" version="$2" top="$3" output="$4"
  local payload="${TEST_ROOT}/payload-${version}-${type}"
  if [[ "$type" == zip ]]; then
    make_java_home "$payload/$top" "$version" .exe
    make_zip "$output" "$payload" "$top"
  elif [[ "$type" == mac ]]; then
    make_java_home "$payload/$top/Contents/Home" "$version"
    tar -czf "$output" -C "$payload" "$top"
  else
    make_java_home "$payload/$top" "$version"
    tar -czf "$output" -C "$payload" "$top"
  fi
}

mkdir -p "$TEST_HOME" "$FAKE_BIN"
cat >"$FAKE_BIN/uname" <<'EOF'
#!/usr/bin/env bash
case "${1-}" in
  -s)
    case "$MOCK_OS" in
      windows) printf 'MINGW64_NT-10.0\n' ;;
      linux) printf 'Linux\n' ;;
      mac) printf 'Darwin\n' ;;
      *) printf 'Unknown\n' ;;
    esac
    ;;
  -m) printf '%s\n' "$MOCK_ARCH" ;;
  *) /usr/bin/uname "$@" ;;
esac
EOF
cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOCK_CURL_ARGS_LOG"
output=""
url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) output="$2"; shift 2 ;;
    https://*) url="$1"; shift ;;
    *) shift ;;
  esac
done
printf '%s\n' "$url" >>"$MOCK_CURL_LOG"
case "$url" in
  */info/available_releases)
    [[ "${MOCK_LIST_FAIL-0}" != 1 ]] || exit 22
    printf '%s\n' "${MOCK_LTS_JSON-}"
    ;;
  */assets/latest/*)
    [[ "${MOCK_METADATA_FAIL-0}" != 1 ]] || exit 22
    if [[ "${MOCK_BAD_METADATA-0}" == 1 ]]; then
      printf '{"binary":{"package":{}}}\n'
      exit 0
    fi
    if command -v sha256sum >/dev/null 2>&1; then
      hash="$(sha256sum "$MOCK_ARCHIVE" | awk '{print $1}')"
    else
      hash="$(shasum -a 256 "$MOCK_ARCHIVE" | awk '{print $1}')"
    fi
    [[ "${MOCK_BAD_HASH-0}" != 1 ]] || hash="$(printf '%064d' 0)"
    printf '[{"binary":{"package":{"name":"%s","checksum":"%s","link":"https://mock.example/releases/%s"}}}]\n' "$MOCK_ARCHIVE_NAME" "$hash" "$MOCK_ARCHIVE_NAME"
    ;;
  https://mirrors.tuna.tsinghua.edu.cn/Adoptium/*|https://mock.example/releases/*)
    [[ "${MOCK_HTTP_404-0}" != 1 ]] || exit 22
    if [[ "${MOCK_INTERRUPT-0}" == 1 ]]; then
      kill -TERM "$PPID"
      sleep 0.1
      exit 1
    fi
    cp "$MOCK_ARCHIVE" "$output"
    ;;
  *) exit 22 ;;
esac
EOF
chmod +x "$FAKE_BIN/uname" "$FAKE_BIN/curl"
export PATH="$FAKE_BIN:$BASE_PATH" HOME="$TEST_HOME"
export MOCK_OS=windows MOCK_ARCH=x86_64 MOCK_LTS_JSON='{"available_lts_releases":[8,11,17,21,25]}'
export MOCK_CURL_LOG="${TEST_ROOT}/curl.log" MOCK_CURL_ARGS_LOG="${TEST_ROOT}/curl-args.log" TEST_JAVA_RUN_LOG="$EVENTS"
unset JDK_HOME JAVA_HOME
: >"$MOCK_CURL_LOG"
: >"$MOCK_CURL_ARGS_LOG"
: >"$EVENTS"

bash -n "$JDEV" && pass || fail 'JDK command syntax'
run_jdev jdk ls
assert_status 0 'missing default JDK directory is an empty list'
[[ -z "$OUTPUT" ]] && pass || fail 'empty JDK directory produces no rows'

make_java_home "$TEST_HOME/.jdks/custom-17" 17.0.1
make_java_home "$TEST_HOME/.jdks/custom-21/Contents/Home" 21.0.2
make_java_home "$TEST_HOME/.jdks/mismatched" 17.0.1
printf '#!/usr/bin/env bash\nprintf '\''openjdk version "21.0.1"\\n'\'' >&2\n' >"$TEST_HOME/.jdks/mismatched/bin/java"
chmod +x "$TEST_HOME/.jdks/mismatched/bin/java"
mkdir -p "$TEST_HOME/.jdks/invalid"
run_jdev jdk ls
assert_status 0 'local JDK listing succeeds'
assert_contains $'21.0.2\t' 'macOS JDK home is listed'
assert_contains "$TEST_HOME/.jdks/custom-21/Contents/Home" 'macOS JAVA_HOME points to Contents/Home'
assert_contains $'17.0.1\t' 'other installed JDK is listed'
[[ "${OUTPUT%%$'\n'*}" == 21.0.2* ]] && pass || fail 'local JDKs are ordered newest first'
[[ "$OUTPUT" != *invalid* ]] && pass || fail 'invalid child directory is skipped'
[[ "$OUTPUT" != *mismatched* ]] && pass || fail 'release and binary version mismatch is skipped'

export JDK_HOME="${TEST_ROOT}/custom root"
mkdir -p "$JDK_HOME"
make_java_home "$JDK_HOME/custom-8" 1.8.0_502
run_jdev jdk ls
assert_contains $'1.8.0_502\t' 'JDK_HOME overrides the default root'
[[ "$OUTPUT" != *21.0.2* ]] && pass || fail 'default root is not mixed with JDK_HOME'

run_jdev jdk ls-remote
assert_status 0 'remote LTS list succeeds'
[[ "$OUTPUT" == $'8\n11\n17\n21\n25' ]] && pass || fail 'remote list uses LTS field only'
export MOCK_LTS_JSON='{"available_releases":[17],"wrong_field":[21]}'
run_jdev jdk ls-remote
[[ "$STATUS" -ne 0 ]] && pass || fail 'malformed remote list fails'
assert_contains '格式无效' 'malformed remote list explains failure'
export MOCK_LTS_JSON='{"available_lts_releases":[8,11,17,21,25]}' MOCK_LIST_FAIL=1
run_jdev jdk ls-remote
[[ "$STATUS" -ne 0 ]] && pass || fail 'remote network failure fails'
unset MOCK_LIST_FAIL

run_jdev jdk install 17.0.9
[[ "$STATUS" -ne 0 ]] && pass || fail 'patch version is rejected'
run_jdev jdk install 22
[[ "$STATUS" -ne 0 ]] && pass || fail 'non-LTS major is rejected'

ZIP_17="${TEST_ROOT}/jdk-17.zip"
make_archive zip 17.0.9 'jdk-17.0.9+9' "$ZIP_17"
export MOCK_ARCHIVE="$ZIP_17" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.9_9.zip'
run_jdev jdk install 17
assert_status 0 'Windows ZIP installs'
assert_requested '/Adoptium/17/jdk/x64/windows/OpenJDK17U-jdk_x64_windows_hotspot_17.0.9_9.zip' 'Windows x64 artifact is selected from Tsinghua'
grep -Fq -- '--progress-bar' "$MOCK_CURL_ARGS_LOG" && pass || fail 'JDK download shows a progress bar'
assert_not_requested '/binary/latest/' 'old binary download endpoint is unused'
assert_not_requested '.sha256.txt' 'signed download URL is not used for checksum lookup'
DEST_17="$JDK_HOME/temurin-jdk-17.0.9+9"
assert_file "$DEST_17/bin/java.exe" 'Windows JDK is installed under versioned directory'
assert_no_staging "$JDK_HOME" 'successful install cleans staging directory'
run_jdev jdk install 17
assert_status 0 'repeated install succeeds'
assert_contains '已安装' 'repeated install is a no-op'

ZIP_8="${TEST_ROOT}/jdk-8.zip"
make_archive zip 1.8.0_504 'jdk8u504-b01' "$ZIP_8"
export MOCK_ARCHIVE="$ZIP_8" MOCK_ARCHIVE_NAME='OpenJDK8U-jdk_x64_windows_hotspot_8u504b01.zip'
run_jdev jdk install 8
assert_status 0 'JDK 8 installs from the mirror without a checksum sidecar'
assert_requested '/assets/latest/8/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse' 'JDK 8 checksum comes from release metadata'
assert_requested '/Adoptium/8/jdk/x64/windows/OpenJDK8U-jdk_x64_windows_hotspot_8u504b01.zip' 'JDK 8 mirror artifact is requested'
assert_file "$JDK_HOME/temurin-jdk8u504-b01/bin/java.exe" 'JDK 8 archive is installed'
assert_not_requested '.sha256.txt' 'JDK 8 does not request an unavailable checksum file'

run_jdev jdk install 8 --source=invalid
[[ "$STATUS" -ne 0 ]] && pass || fail 'unknown download source is rejected'
assert_contains '下载源必须是' 'unknown download source is explained'
run_jdev jdk install 8 --source
[[ "$STATUS" -ne 0 ]] && pass || fail 'missing source value is rejected'

ZIP_17_OFFICIAL="${TEST_ROOT}/jdk-17-official.zip"
make_archive zip 17.0.13 'jdk-17.0.13+1' "$ZIP_17_OFFICIAL"
export MOCK_ARCHIVE="$ZIP_17_OFFICIAL" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_1.zip'
run_jdev jdk install 17 --source adoptium
assert_status 0 'Adoptium source installs'
assert_requested 'https://mock.example/releases/OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_1.zip' 'Adoptium asset link is downloaded'
assert_file "$JDK_HOME/temurin-jdk-17.0.13+1/bin/java.exe" 'Adoptium source JDK is installed'

ZIP_17_SKIP="${TEST_ROOT}/jdk-17-skip.zip"
make_archive zip 17.0.14 'jdk-17.0.14+1' "$ZIP_17_SKIP"
export MOCK_ARCHIVE="$ZIP_17_SKIP" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.14_1.zip' MOCK_BAD_HASH=1
run_jdev jdk install --no-verify-sha256 17 --source=tsinghua
assert_status 0 'SHA-256 check can be skipped explicitly'
assert_contains '已跳过 SHA-256 校验' 'skip verification is announced'
assert_file "$JDK_HOME/temurin-jdk-17.0.14+1/bin/java.exe" 'JDK installs with verification disabled'
unset MOCK_BAD_HASH

ZIP_17_NEW="${TEST_ROOT}/jdk-17-new.zip"
make_archive zip 17.0.10 'jdk-17.0.10+1' "$ZIP_17_NEW"
export MOCK_ARCHIVE="$ZIP_17_NEW" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.10_1.zip'
run_jdev jdk install 17
assert_status 0 'new patch installs beside old patch'
assert_file "$DEST_17/bin/java.exe" 'old patch remains installed'
assert_file "$JDK_HOME/temurin-jdk-17.0.10+1/bin/java.exe" 'new patch is installed'

ZIP_17_BAD="${TEST_ROOT}/jdk-17-bad.zip"
make_archive zip 17.0.11 'jdk-17.0.11+1' "$ZIP_17_BAD"
export MOCK_ARCHIVE="$ZIP_17_BAD" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.11_1.zip' MOCK_BAD_HASH=1
run_jdev jdk install 17
[[ "$STATUS" -ne 0 ]] && pass || fail 'checksum mismatch fails'
assert_contains 'SHA-256 校验失败' 'checksum mismatch is explained'
assert_absent "$JDK_HOME/temurin-jdk-17.0.11+1" 'checksum mismatch leaves no installation'
assert_no_staging "$JDK_HOME" 'checksum failure cleans staging directory'
unset MOCK_BAD_HASH
export MOCK_BAD_METADATA=1
run_jdev jdk install 17
[[ "$STATUS" -ne 0 ]] && pass || fail 'malformed release metadata fails'
assert_contains '缺少归档文件名' 'malformed release metadata is explained'
assert_no_staging "$JDK_HOME" 'metadata failure cleans staging directory'
unset MOCK_BAD_METADATA
export MOCK_INTERRUPT=1
run_jdev jdk install 17
[[ "$STATUS" -ne 0 ]] && pass || fail 'interrupted install fails'
assert_no_staging "$JDK_HOME" 'interruption cleans staging directory'
unset MOCK_INTERRUPT

BAD_ZIP="${TEST_ROOT}/traversal.zip"
perl -MIO::Compress::Zip -e '
  my $zip = IO::Compress::Zip->new($ARGV[0], Name => "../escape/release") or die $IO::Compress::Zip::ZipError;
  $zip->print("JAVA_VERSION=\"17.0.11\"\n");
  $zip->close() or die $IO::Compress::Zip::ZipError;
' "$BAD_ZIP"
export MOCK_ARCHIVE="$BAD_ZIP" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.11_1.zip'
run_jdev jdk install 17
[[ "$STATUS" -ne 0 ]] && pass || fail 'traversal archive is rejected'
assert_contains '目录结构不安全' 'traversal archive explains rejection'
assert_absent "$TEST_ROOT/escape" 'traversal archive cannot escape staging'
assert_no_staging "$JDK_HOME" 'invalid archive cleans staging directory'

export MOCK_ARCHIVE="$ZIP_17_BAD" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.11_1.zip'
mkdir -p "$JDK_HOME/temurin-jdk-17.0.11+1"
printf 'keep\n' >"$JDK_HOME/temurin-jdk-17.0.11+1/marker"
run_jdev jdk install 17
[[ "$STATUS" -ne 0 ]] && pass || fail 'invalid existing destination is not overwritten'
assert_file "$JDK_HOME/temurin-jdk-17.0.11+1/marker" 'existing destination remains intact'
assert_no_staging "$JDK_HOME" 'collision cleans staging directory'

export MOCK_HTTP_404=1
run_jdev jdk install 17
[[ "$STATUS" -ne 0 ]] && pass || fail 'unavailable platform package fails'
assert_contains '镜像尚未同步' 'missing package error is clear'
assert_no_staging "$JDK_HOME" 'download failure cleans staging directory'
unset MOCK_HTTP_404

LINUX_TAR="${TEST_ROOT}/jdk-21.tar.gz"
make_archive linux 21.0.4 'jdk-21.0.4+1' "$LINUX_TAR"
export MOCK_OS=linux MOCK_ARCH=aarch64 JDK_HOME="${TEST_ROOT}/linux installs"
export MOCK_ARCHIVE="$LINUX_TAR" MOCK_ARCHIVE_NAME='OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.4_1.tar.gz'
run_jdev jdk install 21
assert_status 0 'Linux tar.gz installs'
assert_requested '/Adoptium/21/jdk/aarch64/linux/' 'Linux ARM64 artifact is selected'
assert_file "$JDK_HOME/temurin-jdk-21.0.4+1/bin/java" 'Linux JDK is installed'

MAC_TAR="${TEST_ROOT}/jdk-17-mac.tar.gz"
make_archive mac 17.0.12 'jdk-17.0.12+1' "$MAC_TAR"
export MOCK_OS=mac MOCK_ARCH=arm64 JDK_HOME="${TEST_ROOT}/mac installs"
export MOCK_ARCHIVE="$MAC_TAR" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.12_1.tar.gz'
run_jdev jdk install 17
assert_status 0 'macOS tar.gz installs'
assert_requested '/Adoptium/17/jdk/aarch64/mac/' 'macOS ARM64 artifact is selected'
assert_file "$JDK_HOME/temurin-jdk-17.0.12+1/Contents/Home/bin/java" 'macOS JDK layout is retained'
run_jdev jdk ls
assert_contains "$JDK_HOME/temurin-jdk-17.0.12+1/Contents/Home" 'macOS local list returns actual JAVA_HOME'

unset JDK_HOME
export MOCK_OS=windows MOCK_ARCH=x86_64 MOCK_ARCHIVE="$ZIP_17" MOCK_ARCHIVE_NAME='OpenJDK17U-jdk_x64_windows_hotspot_17.0.9_9.zip'
run_jdev jdk install 17
assert_status 0 'default HOME/.jdks installation works'
cat >"$FAKE_BIN/mvn" <<'EOF'
#!/usr/bin/env bash
mkdir -p target
printf 'test-jar' >target/app.jar
EOF
chmod +x "$FAKE_BIN/mvn"
PROJECT="${TEST_ROOT}/spring app"
mkdir -p "$PROJECT/src/main/java"
printf '<project><properties><java.version>17</java.version></properties><dependency>spring-boot</dependency></project>\n' >"$PROJECT/pom.xml"
: >"$EVENTS"
(cd "$PROJECT" && exec bash "$JDEV" --poll 0.1 --delay 0) >"$OUTPUT_FILE" 2>&1 &
JDEV_PID=$!
for ((i = 0; i < 100; i++)); do
  [[ -s "$EVENTS" ]] && break
  sleep 0.1
done
if [[ -s "$EVENTS" ]]; then
  pass
  [[ "$(cat "$EVENTS")" == "$TEST_HOME/.jdks/temurin-jdk-17.0.9+9"* ]] && pass || fail 'project run selects installed default-root JDK'
else
  fail 'project run starts with installed JDK'
fi
kill -TERM "$JDEV_PID" 2>/dev/null || true
wait "$JDEV_PID" 2>/dev/null || true
JDEV_PID=""

export JDK_HOME="${TEST_ROOT}/mac installs"
: >"$EVENTS"
(cd "$PROJECT" && exec bash "$JDEV" --poll 0.1 --delay 0) >"$OUTPUT_FILE" 2>&1 &
JDEV_PID=$!
for ((i = 0; i < 100; i++)); do
  [[ -s "$EVENTS" ]] && break
  sleep 0.1
done
if [[ -s "$EVENTS" ]]; then
  [[ "$(cat "$EVENTS")" == "$JDK_HOME/temurin-jdk-17.0.12+1/Contents/Home"* ]] && pass || fail 'project run uses installed macOS JAVA_HOME'
else
  fail 'project run starts with installed macOS JDK'
fi
kill -TERM "$JDEV_PID" 2>/dev/null || true
wait "$JDEV_PID" 2>/dev/null || true
JDEV_PID=""

printf '%d assertions, %d failures\n' "$ASSERTIONS" "$FAILURES"
(( FAILURES == 0 ))
)

run_jdk_tests
