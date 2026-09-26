#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CODEV_SOURCE="$REPO_DIR/scripts/tools/codev"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codev-test.XXXXXX")"
CODE_DIR="$TEST_ROOT/code"
WORKSPACE_DIR="$TEST_ROOT/workspaces"
FAKE_BIN="$TEST_ROOT/bin"
CODEV_BIN="$TEST_ROOT/codev-bin"
CODEV="$CODEV_BIN/codev"
OUTPUT="$TEST_ROOT/output"
GIT_BIN="$(command -v git)"
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
assert_not_contains() { ! grep -Fq -- "$2" "$1" && pass || fail "$3"; }
assert_empty() { [[ ! -s "$1" ]] && pass || fail "$2"; }

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
  local name_suffix=$1 confirm_input=${2-}
  local picker_status=${PICK_STATUS:-0} picker_selection=${PICK_SELECTION:-}

  start_picker_sequence
  queue_picker 0 '+ New workspace'
  queue_picker "$picker_status" "$picker_selection"
  queue_picker 0 q
  run_manage "$name_suffix"$'\n'"$confirm_input"
  export PICK_SELECTION="$picker_selection" PICK_STATUS="$picker_status"
}

mkdir -p -- "$CODE_DIR/group/app one/.git" "$CODE_DIR/app-two/.git" \
  "$CODE_DIR/app-three/.git" "$CODE_DIR/中文应用/.git" \
  "$CODE_DIR/reserved/RELEASE/.git" \
  "$CODE_DIR/worktree-origin" "$WORKSPACE_DIR" "$FAKE_BIN" "$CODEV_BIN"
"$GIT_BIN" -C "$CODE_DIR/app-two" init -q
"$GIT_BIN" -C "$CODE_DIR/app-three" init -q
"$GIT_BIN" -C "$CODE_DIR/app-two" symbolic-ref HEAD refs/heads/main
"$GIT_BIN" -C "$CODE_DIR/app-three" symbolic-ref HEAD refs/heads/feature/menu-branch
"$GIT_BIN" -C "$CODE_DIR/app-three" -c user.name=codev-test \
  -c user.email=codev-test.invalid commit --allow-empty -qm fixture
"$GIT_BIN" -C "$CODE_DIR/worktree-origin" init -q
"$GIT_BIN" -C "$CODE_DIR/worktree-origin" -c user.name=codev-test \
  -c user.email=codev-test.invalid commit --allow-empty -qm fixture
"$GIT_BIN" -C "$CODE_DIR/worktree-origin" worktree add -qb feature/worktree \
  "$CODE_DIR/app-worktree"
printf '%s\n' 'group/app one' 'app-two' 'app-three' '中文应用' \
  'reserved/RELEASE' >"$CODE_DIR/.codev-repos"
cp -- "$CODEV_SOURCE" "$CODEV"

cat >"$CODEV_BIN/picker" <<'EOF'
#!/usr/bin/env bash
input="$(cat)"
if [[ -n "${PICK_SEQUENCE_DIR:-}" ]]; then
  index=0
  [[ ! -f "$PICK_SEQUENCE_DIR/index" ]] || read -r index <"$PICK_SEQUENCE_DIR/index"
  ((index += 1))
  printf '%d\n' "$index" >"$PICK_SEQUENCE_DIR/index"
  printf '%s\n' "$input" >"$PICK_SEQUENCE_DIR/$index.input"
  printf '%s\n' "$*" >"$PICK_SEQUENCE_DIR/$index.args"
  status="$(cat "$PICK_SEQUENCE_DIR/$index.status")"
  ((status == 0)) || exit "$status"
  selection=''
  [[ ! -f "$PICK_SEQUENCE_DIR/$index.output" ]] || selection="$(cat "$PICK_SEQUENCE_DIR/$index.output")"
  if [[ "$selection" == q && " $* " == *' --quit '* ]]; then exit 131; fi
  [[ -z "$selection" ]] || printf '%s\n' "$selection"
  exit "$status"
fi
status=${PICK_STATUS:-0}
((status == 0)) || exit "$status"
selection=${PICK_SELECTION:-}
if [[ "$selection" == q && " $* " == *' --quit '* ]]; then exit 131; fi
[[ -z "$selection" ]] || printf '%s\n' "$selection"
EOF
chmod +x "$CODEV_BIN/picker"

ACTION_LOG="$TEST_ROOT/actions"
export ACTION_LOG
for command_name in explorer.exe open xdg-open; do
  cat >"$FAKE_BIN/$command_name" <<'EOF'
#!/usr/bin/env bash
if [[ "${0##*/}" == open && "${1-}" == -a && "${2-}" == Terminal ]]; then
  printf 'terminal-window' >>"$ACTION_LOG"
  printf '\t%s' "$@" >>"$ACTION_LOG"
  printf '\n' >>"$ACTION_LOG"
else
  printf 'folder\t%s\n' "$1" >>"$ACTION_LOG"
fi
EOF
  chmod +x "$FAKE_BIN/$command_name"
done
for command_name in wt.exe gnome-terminal; do
  cat >"$FAKE_BIN/$command_name" <<'EOF'
#!/usr/bin/env bash
printf 'terminal-window' >>"$ACTION_LOG"
printf '\t%s' "$@" >>"$ACTION_LOG"
printf '\n' >>"$ACTION_LOG"
EOF
  chmod +x "$FAKE_BIN/$command_name"
done
cat >"$FAKE_BIN/code" <<'EOF'
#!/usr/bin/env bash
printf 'vscode\t%s\n' "$1" >>"$ACTION_LOG"
EOF
chmod +x "$FAKE_BIN/code"
cat >"$FAKE_BIN/codev-test-shell" <<'EOF'
#!/usr/bin/env bash
printf 'terminal\t%s\t%s\n' "$PWD" "$*" >>"$ACTION_LOG"
EOF
chmod +x "$FAKE_BIN/codev-test-shell"
cat >"$FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
printf 'git\t%s\n' "$*" >>"$ACTION_LOG"
exit 97
EOF
chmod +x "$FAKE_BIN/git"

SEQUENCE_COUNT=0
start_picker_sequence() {
  PICK_SEQUENCE_DIR="$TEST_ROOT/picker-sequence"
  rm -rf -- "$PICK_SEQUENCE_DIR"
  mkdir -- "$PICK_SEQUENCE_DIR"
  printf '0\n' >"$PICK_SEQUENCE_DIR/index"
  SEQUENCE_COUNT=0
  export PICK_SEQUENCE_DIR
  unset PICK_SELECTION PICK_STATUS
}

queue_picker() {
  local status=$1 selection=${2-}
  ((SEQUENCE_COUNT += 1))
  printf '%s\n' "$status" >"$PICK_SEQUENCE_DIR/$SEQUENCE_COUNT.status"
  printf '%s' "$selection" >"$PICK_SEQUENCE_DIR/$SEQUENCE_COUNT.output"
}

stop_picker_sequence() {
  unset PICK_SEQUENCE_DIR
}

run_manage() {
  local input=${1-}
  set +e
  printf '%s' "$input" | bash "$CODEV" >"$OUTPUT" 2>&1
  STATUS=$?
  set -e
}

create_test_link() {
  local source=$1 link=$2
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      MSYS_NO_PATHCONV=1 cmd.exe /c mklink /J \
        "$(cygpath -w "$link")" "$(cygpath -w "$source")" >/dev/null
      ;;
    *) ln -s -- "$source" "$link" ;;
  esac
}

export PATH="$FAKE_BIN:$PATH"
export SHELL="$FAKE_BIN/codev-test-shell"
export CODEV_CODES_PATH="$CODE_DIR"
export CODEV_WORKSPACES_PATH="$WORKSPACE_DIR"
WORKSPACE_NAME_PREFIX="$(date +%Y%m%d)-"

bash -n "$CODEV" && pass || fail 'codev syntax check'

set +e
bash "$CODEV" --help >"$OUTPUT" 2>&1
STATUS=$?
set -e
assert_status 0 'codev --help succeeds'
assert_not_contains "$OUTPUT" 'create <name>' 'help does not advertise the removed create command'
assert_not_contains "$OUTPUT" 'refresh-repos' 'help does not advertise the removed refresh command'

for removed_command in 'create demo' 'refresh-repos' 'help' '-h' '--version' '--help extra'; do
  set +e
  # shellcheck disable=SC2086 # Each fixture intentionally represents argv.
  bash "$CODEV" $removed_command >"$OUTPUT" 2>&1
  STATUS=$?
  set -e
  [[ "$STATUS" -eq 2 ]] && pass || fail "removed command is rejected: $removed_command"
done

printf 'stale\n' >"$CODE_DIR/.codev-repos"
start_picker_sequence
queue_picker 0 '+ Refresh Repos'
queue_picker 0 q
run_manage
assert_status 0 'application index refresh runs from the manager'
assert_contains "$CODE_DIR/.codev-repos" 'app-two' 'manager refresh rewrites the application index'
assert_not_contains "$CODE_DIR/.codev-repos" 'stale' 'manager refresh replaces stale index content'
assert_contains "$PICK_SEQUENCE_DIR/2.input" '+ Refresh Repos' 'manager remains open after refreshing repositories'

export PICK_SELECTION=$'group/app one\napp-two'
unset PICK_STATUS
run_create demo
demo_name="$WORKSPACE_NAME_PREFIX"demo
assert_status 0 'fresh workspace creation succeeds'
assert_link_points_to "$WORKSPACE_DIR/$demo_name/app one" "$CODE_DIR/group/app one" 'first project link is created'
assert_link_points_to "$WORKSPACE_DIR/$demo_name/app-two" "$CODE_DIR/app-two" 'second project link is created'
assert_dir "$WORKSPACE_DIR/$demo_name/RELEASE" 'RELEASE directory is created'
assert_file "$WORKSPACE_DIR/$demo_name/$demo_name.code-workspace" 'VS Code workspace file is created'
expected=$'{\n  "folders": [\n    { "path": "app one" },\n    { "path": "app-two" },\n    { "path": "RELEASE" }\n  ]\n}'
assert_workspace "$WORKSPACE_DIR/$demo_name/$demo_name.code-workspace" "$expected" 'workspace preserves selected project order and includes RELEASE'

export PICK_SELECTION='中文应用'
run_create unicode
unicode_name="$WORKSPACE_NAME_PREFIX"unicode
assert_status 0 'workspace creation supports a Unicode project name'
assert_link_points_to "$WORKSPACE_DIR/$unicode_name/中文应用" "$CODE_DIR/中文应用" 'Unicode project link is created'
expected=$'{\n  "folders": [\n    { "path": "中文应用" },\n    { "path": "RELEASE" }\n  ]\n}'
assert_workspace "$WORKSPACE_DIR/$unicode_name/$unicode_name.code-workspace" "$expected" 'workspace JSON preserves a Unicode project name'

printf '{ "folders": [], "settings": { "old": true } }\n' >"$WORKSPACE_DIR/$demo_name/$demo_name.code-workspace"
export PICK_SELECTION=app-three
run_create demo $'\n'
assert_status 0 'adding a project to an existing workspace succeeds'
assert_link_points_to "$WORKSPACE_DIR/$demo_name/app-three" "$CODE_DIR/app-three" 'new project link is added'
expected=$'{\n  "folders": [\n    { "path": "app one" },\n    { "path": "app-two" },\n    { "path": "app-three" },\n    { "path": "RELEASE" }\n  ]\n}'
assert_workspace "$WORKSPACE_DIR/$demo_name/$demo_name.code-workspace" "$expected" 'regenerated workspace keeps existing links and adds the new project'
if grep -Fq -- '"settings"' "$WORKSPACE_DIR/$demo_name/$demo_name.code-workspace"; then
  fail 'managed workspace file should not preserve manual settings'
else
  pass
fi

release_conflict_name="$WORKSPACE_NAME_PREFIX"release-conflict
mkdir -p -- "$WORKSPACE_DIR/$release_conflict_name"
printf 'keep\n' >"$WORKSPACE_DIR/$release_conflict_name/RELEASE"
export PICK_SELECTION=app-two
run_create release-conflict $'\n'
[[ "$STATUS" -ne 0 ]] && pass || fail 'a RELEASE file conflict fails'
assert_contains "$OUTPUT" 'RELEASE path is not a regular directory' 'RELEASE conflict is explained'
assert_absent "$WORKSPACE_DIR/$release_conflict_name/app-two" 'RELEASE conflict creates no project link'
assert_absent "$WORKSPACE_DIR/$release_conflict_name/$release_conflict_name.code-workspace" 'RELEASE conflict creates no workspace file'

workspace_conflict_name="$WORKSPACE_NAME_PREFIX"workspace-conflict
mkdir -p -- "$WORKSPACE_DIR/$workspace_conflict_name/$workspace_conflict_name.code-workspace"
run_create workspace-conflict $'\n'
[[ "$STATUS" -ne 0 ]] && pass || fail 'a workspace directory conflict fails'
assert_contains "$OUTPUT" 'workspace path is not a regular file' 'workspace conflict is explained'
assert_absent "$WORKSPACE_DIR/$workspace_conflict_name/app-two" 'workspace conflict creates no project link'
assert_absent "$WORKSPACE_DIR/$workspace_conflict_name/RELEASE" 'workspace conflict creates no RELEASE directory'

export PICK_SELECTION='reserved/RELEASE'
run_create reserved-name
reserved_name="$WORKSPACE_NAME_PREFIX"reserved-name
[[ "$STATUS" -ne 0 ]] && pass || fail 'a project named RELEASE is rejected'
assert_contains "$OUTPUT" 'reserved workspace name: RELEASE' 'reserved project name is explained'
assert_absent "$WORKSPACE_DIR/$reserved_name" 'reserved project name creates no destination'

export PICK_SELECTION=app-two PICK_STATUS=130
run_create cancelled
assert_status 0 'picker cancellation is a successful no-op'
cancelled_name="$WORKSPACE_NAME_PREFIX"cancelled
assert_absent "$WORKSPACE_DIR/$cancelled_name" 'picker cancellation creates no destination'

MANAGE_DIR="$TEST_ROOT/manage"
mkdir -p -- "$MANAGE_DIR/.hidden" "$MANAGE_DIR/alpha/ordinary" \
  "$MANAGE_DIR/empty" "$MANAGE_DIR/worktree" "$MANAGE_DIR/zeta" \
  "$MANAGE_DIR/新建工作目录"
printf 'not a workspace\n' >"$MANAGE_DIR/plain-file"
printf 'not an application\n' >"$MANAGE_DIR/alpha/plain-file"
create_test_link "$CODE_DIR/app-two" "$MANAGE_DIR/alpha/linked app"
create_test_link "$CODE_DIR/app-three" "$MANAGE_DIR/alpha/中文链接"
create_test_link "$CODE_DIR/reserved/RELEASE" "$MANAGE_DIR/alpha/RELEASE"
create_test_link "$CODE_DIR/app-worktree" "$MANAGE_DIR/worktree/linked worktree"
printf '{ "folders": [] }\n' >"$MANAGE_DIR/alpha/alpha.code-workspace"
export CODEV_WORKSPACES_PATH="$MANAGE_DIR"

start_picker_sequence
queue_picker 130
run_manage
assert_status 0 'manager exits successfully when the workspace list is cancelled'
assert_workspace "$PICK_SEQUENCE_DIR/1.input" $'+ New workspace\n+ Refresh Repos\n  .hidden\n  alpha\n  empty\n  worktree\n  zeta\n  新建工作目录' 'manager lists fixed actions first and all workspace directories in name order'
assert_not_contains "$PICK_SEQUENCE_DIR/1.input" '  plain-file' 'manager ignores regular files in the workspace root'
assert_not_contains "$PICK_SEQUENCE_DIR/1.args" '--backend' 'codev uses picker without backend selection'
assert_contains "$PICK_SEQUENCE_DIR/1.args" '--prompt Workspaces' 'workspace list uses the concise English title'
assert_contains "$PICK_SEQUENCE_DIR/1.args" 'Up/Down: move  Enter: open  Esc/q: quit' 'workspace list shows context-specific English help'

start_picker_sequence
queue_picker 0 q
run_manage
assert_status 0 'q exits directly from the workspace list'
[[ "$(cat "$PICK_SEQUENCE_DIR/index")" -eq 1 ]] && pass || fail 'root q does not open another menu'

start_picker_sequence
queue_picker 0 '  worktree'
queue_picker 130
queue_picker 130
run_manage
assert_contains "$PICK_SEQUENCE_DIR/2.input" '  linked worktree  [feature/worktree]' 'application branches are read through a worktree .git pointer'

start_picker_sequence
queue_picker 0 '  alpha'
queue_picker 0 '+ Open workspace folder'
queue_picker 0 '+ Open VS Code workspace'
queue_picker 0 $'  linked app  [main]\n  中文链接  [feature/menu-branch]'
queue_picker 0 '+ Open terminal / linked app'
queue_picker 130
queue_picker 130
queue_picker 130
run_manage
assert_status 0 'manager supports application selection and nested back navigation'
application_menu_expected=$'+ Open workspace folder\n+ Open VS Code workspace\n  linked app  [main]\n  中文链接  [feature/menu-branch]'
assert_workspace "$PICK_SEQUENCE_DIR/2.input" "$application_menu_expected" 'workspace actions and linked applications show current branches in one menu'
assert_not_contains "$PICK_SEQUENCE_DIR/2.input" 'ordinary' 'application list excludes regular directories'
assert_not_contains "$PICK_SEQUENCE_DIR/2.input" 'plain-file' 'application list excludes regular files'
assert_contains "$PICK_SEQUENCE_DIR/2.args" '--multi' 'application list enables multiple selection'
assert_contains "$PICK_SEQUENCE_DIR/2.args" '--actions 2' 'workspace actions render as immediate action rows'
assert_workspace "$PICK_SEQUENCE_DIR/3.input" "$application_menu_expected" 'folder action returns to the same application menu'
assert_workspace "$PICK_SEQUENCE_DIR/4.input" "$application_menu_expected" 'VS Code action returns to the same application menu'
application_actions_expected=$'+ Open terminal / linked app\n+ Open terminal / 中文链接'
assert_contains "$PICK_SEQUENCE_DIR/5.args" 'Actions / 2 selected' 'application action screen reports the selected count'
assert_workspace "$PICK_SEQUENCE_DIR/5.input" "$application_actions_expected" 'multiple selections expose an explicit terminal target per application'
assert_workspace "$PICK_SEQUENCE_DIR/6.input" "$application_actions_expected" 'opening a terminal window returns to the application action screen'
assert_contains "$ACTION_LOG" 'alpha' 'file-manager action opens the workspace directory'
[[ "$(grep -Fc $'folder\t' "$ACTION_LOG")" -eq 1 ]] && pass || fail 'file-manager action opens exactly one workspace window'
assert_not_contains "$ACTION_LOG" 'linked app' 'file-manager action does not open selected application folders'
assert_not_contains "$ACTION_LOG" '中文链接' 'file-manager action does not open selected application folders'
assert_contains "$ACTION_LOG" $'vscode\t' 'VS Code action invokes the code command'
assert_contains "$ACTION_LOG" 'alpha.code-workspace' 'VS Code action opens the current workspace file'
assert_contains "$ACTION_LOG" $'terminal-window\t' 'terminal action launches a new terminal window'
assert_contains "$ACTION_LOG" 'app-two' 'new terminal starts in the chosen application repository'
assert_contains "$ACTION_LOG" 'codev-test-shell' 'new terminal runs the configured shell'
assert_contains "$ACTION_LOG" $'\t-i' 'new terminal requests an interactive shell'
assert_not_contains "$ACTION_LOG" $'terminal\t' 'terminal action does not run a shell in the codev process'
assert_workspace "$PICK_SEQUENCE_DIR/7.input" "$application_menu_expected" 'returning from actions rescans the application list'
assert_contains "$PICK_SEQUENCE_DIR/8.input" '  alpha' 'cancelling the application list returns to the workspace list'
assert_empty "$OUTPUT" 'application actions do not leak selected paths to command output'

"$GIT_BIN" -C "$CODE_DIR/app-three" checkout --detach -q
start_picker_sequence
queue_picker 0 '  alpha'
queue_picker 130
queue_picker 130
run_manage
assert_contains "$PICK_SEQUENCE_DIR/2.input" '  中文链接  [detached]' 'detached HEAD is identified in the application list'
assert_not_contains "$ACTION_LOG" $'git\t' 'building application menus does not launch Git subprocesses'

start_picker_sequence
queue_picker 0 '  alpha'
queue_picker 0 '  linked app  [main]'
queue_picker 130
queue_picker 130
queue_picker 130
run_manage
assert_workspace "$PICK_SEQUENCE_DIR/3.input" '+ Open terminal' 'a single application uses the concise terminal action label'

start_picker_sequence
queue_picker 0 '  alpha'
queue_picker 0 q
run_manage
assert_status 0 'q exits directly from a child menu'
[[ "$(cat "$PICK_SEQUENCE_DIR/index")" -eq 2 ]] && pass || fail 'child q does not return to the workspace list'

start_picker_sequence
queue_picker 0 '  empty'
queue_picker 130
queue_picker 130
run_manage
assert_status 0 'workspace without applications returns to the workspace list'
assert_workspace "$PICK_SEQUENCE_DIR/2.input" $'+ Open workspace folder\n+ Open VS Code workspace' 'empty workspace keeps its actions without a redundant back item'
assert_contains "$PICK_SEQUENCE_DIR/2.args" 'Applications / empty' 'empty workspace uses the English application title'

start_picker_sequence
queue_picker 0 '+ New workspace'
queue_picker 0 'app-three'
queue_picker 130
run_manage $'managed-new\n'
assert_status 0 'manager can create a workspace and return to its workspace list'
managed_name="$(date +%Y%m%d)-managed-new"
assert_link_points_to "$MANAGE_DIR/$managed_name/app-three" "$CODE_DIR/app-three" 'manager creation reuses application link creation'
assert_dir "$MANAGE_DIR/$managed_name/RELEASE" 'manager creation includes the RELEASE directory'
assert_file "$MANAGE_DIR/$managed_name/$managed_name.code-workspace" 'manager creation includes the VS Code workspace file'
assert_contains "$PICK_SEQUENCE_DIR/3.input" "  $managed_name" 'workspace list is rescanned after manager creation'
assert_contains "$OUTPUT" 'Workspace name (blank to cancel):' 'manager uses the concise English workspace-name prompt'

start_picker_sequence
queue_picker 0 '+ New workspace'
queue_picker 130
run_manage $'\n'
assert_status 0 'blank manager workspace name cancels creation and returns to the list'
[[ "$(cat "$PICK_SEQUENCE_DIR/index")" -eq 2 ]] && pass || fail 'blank workspace name does not open the application picker'
stop_picker_sequence

printf '%d assertions, %d failures\n' "$TESTS" "$FAILURES"
((FAILURES == 0))
