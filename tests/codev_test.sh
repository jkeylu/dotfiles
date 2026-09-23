#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CODEV="$REPO_DIR/scripts/tools/codev"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codev-test.XXXXXX")"
CODE_DIR="$TEST_ROOT/code"
WORKSPACE_DIR="$TEST_ROOT/workspaces"
FAKE_BIN="$TEST_ROOT/bin"
OUTPUT="$TEST_ROOT/output"
TESTS=0
FAILURES=0

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

pass() { ((TESTS += 1)); }
fail() {
  ((TESTS += 1, FAILURES += 1))
  printf 'FAIL: %s\n' "$1" >&2
  [[ ! -f "$OUTPUT" ]] || cat "$OUTPUT" >&2
}
assert_status() { [[ "$STATUS" -eq "$1" ]] && pass || fail "$2 (exit $STATUS)"; }
assert_dir() { [[ -d "$1" && ! -L "$1" ]] && pass || fail "$2"; }
assert_file() { [[ -f "$1" && ! -L "$1" ]] && pass || fail "$2"; }
assert_absent() { [[ ! -e "$1" && ! -L "$1" ]] && pass || fail "$2"; }
assert_contains() { grep -Fq -- "$2" "$1" && pass || fail "$3"; }

assert_link_points_to() {
  local link=$1 target=$2 message=$3 resolved expected
  if [[ -L "$link" ]] &&
     resolved="$(cd -P -- "$link" && pwd -P)" &&
     expected="$(cd -P -- "$target" && pwd -P)" &&
     [[ "$resolved" == "$expected" ]]; then
    pass
  else
    fail "$message"
  fi
}

assert_workspace() {
  local file=$1 expected=$2 message=$3 actual
  actual="$(cat -- "$file")"
  [[ "$actual" == "$expected" ]] && pass || fail "$message"
}

run_create() {
  local name=$1 input=${2-}
  set +e
  printf '%s' "$input" | bash "$CODEV" create "$name" >"$OUTPUT" 2>&1
  STATUS=$?
  set -e
}

mkdir -p -- "$CODE_DIR/group/app one/.git" "$CODE_DIR/app-two/.git" \
  "$CODE_DIR/app-three/.git" "$CODE_DIR/中文应用/.git" \
  "$CODE_DIR/reserved/RELEASE/.git" \
  "$WORKSPACE_DIR" "$FAKE_BIN"
printf '%s\n' 'group/app one' 'app-two' 'app-three' '中文应用' \
  'reserved/RELEASE' >"$CODE_DIR/.codev-repos"

cat >"$FAKE_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
status=${PICK_STATUS:-0}
((status == 0)) || exit "$status"
[[ -z "${PICK_SELECTION:-}" ]] || printf '%s\n' "$PICK_SELECTION"
EOF
chmod +x "$FAKE_BIN/fzf"

export PATH="$FAKE_BIN:$PATH"
export CODEV_CODE_DIR="$CODE_DIR"
export CODEV_WORKSPACE_DIR="$WORKSPACE_DIR"
export DOTFILES_PICKER_BUILTIN=0

bash -n "$CODEV" && pass || fail 'codev syntax check'

export PICK_SELECTION=$'group/app one\napp-two'
unset PICK_STATUS
run_create demo
assert_status 0 'fresh workspace creation succeeds'
assert_link_points_to "$WORKSPACE_DIR/demo/app one" "$CODE_DIR/group/app one" 'first project link is created'
assert_link_points_to "$WORKSPACE_DIR/demo/app-two" "$CODE_DIR/app-two" 'second project link is created'
assert_dir "$WORKSPACE_DIR/demo/RELEASE" 'RELEASE directory is created'
assert_file "$WORKSPACE_DIR/demo/demo.code-workspace" 'VS Code workspace file is created'
expected=$'{\n  "folders": [\n    { "path": "app one" },\n    { "path": "app-two" },\n    { "path": "RELEASE" }\n  ]\n}'
assert_workspace "$WORKSPACE_DIR/demo/demo.code-workspace" "$expected" 'workspace preserves selected project order and includes RELEASE'

export PICK_SELECTION='中文应用'
run_create unicode
assert_status 0 'workspace creation supports a Unicode project name'
assert_link_points_to "$WORKSPACE_DIR/unicode/中文应用" "$CODE_DIR/中文应用" 'Unicode project link is created'
expected=$'{\n  "folders": [\n    { "path": "中文应用" },\n    { "path": "RELEASE" }\n  ]\n}'
assert_workspace "$WORKSPACE_DIR/unicode/unicode.code-workspace" "$expected" 'workspace JSON preserves a Unicode project name'

printf '{ "folders": [], "settings": { "old": true } }\n' >"$WORKSPACE_DIR/demo/demo.code-workspace"
export PICK_SELECTION=app-three
run_create demo $'\n'
assert_status 0 'adding a project to an existing workspace succeeds'
assert_link_points_to "$WORKSPACE_DIR/demo/app-three" "$CODE_DIR/app-three" 'new project link is added'
expected=$'{\n  "folders": [\n    { "path": "app one" },\n    { "path": "app-two" },\n    { "path": "app-three" },\n    { "path": "RELEASE" }\n  ]\n}'
assert_workspace "$WORKSPACE_DIR/demo/demo.code-workspace" "$expected" 'regenerated workspace keeps existing links and adds the new project'
if grep -Fq -- '"settings"' "$WORKSPACE_DIR/demo/demo.code-workspace"; then
  fail 'managed workspace file should not preserve manual settings'
else
  pass
fi

mkdir -p -- "$WORKSPACE_DIR/release-conflict"
printf 'keep\n' >"$WORKSPACE_DIR/release-conflict/RELEASE"
export PICK_SELECTION=app-two
run_create release-conflict $'\n'
[[ "$STATUS" -ne 0 ]] && pass || fail 'a RELEASE file conflict fails'
assert_contains "$OUTPUT" 'RELEASE path is not a regular directory' 'RELEASE conflict is explained'
assert_absent "$WORKSPACE_DIR/release-conflict/app-two" 'RELEASE conflict creates no project link'
assert_absent "$WORKSPACE_DIR/release-conflict/release-conflict.code-workspace" 'RELEASE conflict creates no workspace file'

mkdir -p -- "$WORKSPACE_DIR/workspace-conflict/workspace-conflict.code-workspace"
run_create workspace-conflict $'\n'
[[ "$STATUS" -ne 0 ]] && pass || fail 'a workspace directory conflict fails'
assert_contains "$OUTPUT" 'workspace path is not a regular file' 'workspace conflict is explained'
assert_absent "$WORKSPACE_DIR/workspace-conflict/app-two" 'workspace conflict creates no project link'
assert_absent "$WORKSPACE_DIR/workspace-conflict/RELEASE" 'workspace conflict creates no RELEASE directory'

export PICK_SELECTION='reserved/RELEASE'
run_create reserved-name
[[ "$STATUS" -ne 0 ]] && pass || fail 'a project named RELEASE is rejected'
assert_contains "$OUTPUT" 'reserved workspace name: RELEASE' 'reserved project name is explained'
assert_absent "$WORKSPACE_DIR/reserved-name" 'reserved project name creates no destination'

export PICK_SELECTION=app-two PICK_STATUS=130
run_create cancelled
assert_status 0 'picker cancellation is a successful no-op'
assert_absent "$WORKSPACE_DIR/cancelled" 'picker cancellation creates no destination'

printf '%d assertions, %d failures\n' "$TESTS" "$FAILURES"
((FAILURES == 0))
