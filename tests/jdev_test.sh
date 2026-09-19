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
