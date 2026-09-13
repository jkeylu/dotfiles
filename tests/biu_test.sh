#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
BASH_BIN="${BASH:-bash}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/biu-test.XXXXXX")"
FIXTURE_DIR="$TEST_ROOT/repo"
TEST_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
STDERR_FILE="$TEST_ROOT/stderr"
FAILURES=0
ASSERTIONS=0

cleanup() {
  if [[ -n "${TEST_ROOT:-}" && -d "$TEST_ROOT" ]]; then
    rm -rf -- "$TEST_ROOT"
  fi
}
trap cleanup EXIT

pass() {
  ASSERTIONS=$((ASSERTIONS + 1))
}

fail() {
  ASSERTIONS=$((ASSERTIONS + 1))
  FAILURES=$((FAILURES + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

assert_status() {
  local expected="$1"
  local description="$2"
  if [[ "$STATUS" -eq "$expected" ]]; then
    pass
  else
    fail "$description (expected status $expected, got $STATUS)"
  fi
}

assert_equal() {
  local expected="$1"
  local actual="$2"
  local description="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass
  else
    fail "$description (expected '$expected', got '$actual')"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass
  else
    fail "$description (missing '$needle')"
  fi
}

assert_not_exists() {
  local path="$1"
  local description="$2"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    pass
  else
    fail "$description (unexpected path '$path')"
  fi
}

run_command() {
  set +e
  OUTPUT="$("$@" 2>"$STDERR_FILE")"
  STATUS=$?
  set -e
  ERROR_OUTPUT="$(<"$STDERR_FILE")"
}

run_command_with_input() {
  local input="$1"
  shift

  set +e
  OUTPUT="$(printf '%s' "$input" | "$@" 2>"$STDERR_FILE")"
  STATUS=$?
  set -e
  ERROR_OUTPUT="$(<"$STDERR_FILE")"
}

mkdir -p "$FIXTURE_DIR/opener/windows" "$TEST_HOME" "$FAKE_BIN"
cp "$REPO_DIR/biu.sh" "$FIXTURE_DIR/biu.sh"
cp "$REPO_DIR/util.sh" "$FIXTURE_DIR/util.sh"

cat > "$FIXTURE_DIR/opener/mock.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/../util.sh"

install() {
  printf 'mock install\n'
}

uninstall() {
  printf 'mock uninstall\n'
}

echo_args() {
  local arg
  for arg in "$@"; do
    printf '<%s>\n' "$arg"
  done
}

fail_with() {
  return "$1"
}

_private_helper() {
  printf 'private helper must not be exposed\n'
}

run_cmd "$@"
EOF

for file in "$REPO_DIR/biu.sh" "$REPO_DIR/util.sh" "$REPO_DIR"/opener/*.sh "$REPO_DIR/tests/biu_test.sh"; do
  if "$BASH_BIN" -n "$file"; then
    pass
  else
    fail "syntax check for $file"
  fi
done

run_command_with_input $'\n' "$BASH_BIN" -c \
  'source "$1"; if confirm "Continue?" Y; then printf accepted; fi' _ "$REPO_DIR/util.sh"
assert_status 0 "confirm accepts the default answer"
assert_equal accepted "$OUTPUT" "confirm uses the configured default on Enter"

run_command_with_input $'\ny\n' "$BASH_BIN" -c \
  'source "$1"; if confirm "Continue?"; then printf accepted; fi' _ "$REPO_DIR/util.sh"
assert_status 0 "confirm requires an answer when no default is configured"
assert_equal accepted "$OUTPUT" "confirm accepts an answer after Enter without a default"
assert_contains "$ERROR_OUTPUT" 'please enter Y or N' "confirm rejects Enter without a default"

run_command_with_input $'maybe\ny\n' "$BASH_BIN" -c \
  'source "$1"; if confirm "Continue?" N; then printf accepted; fi' _ "$REPO_DIR/util.sh"
assert_status 0 "confirm retries invalid answers"
assert_equal accepted "$OUTPUT" "confirm accepts Y after an invalid answer"
assert_contains "$ERROR_OUTPUT" 'please enter Y or N' "confirm explains invalid answers"

run_command_with_input $'n\n' "$BASH_BIN" -c \
  'source "$1"; if confirm "Continue?" Y; then printf accepted; else printf declined; fi' _ "$REPO_DIR/util.sh"
assert_status 0 "confirm returns false for N"
assert_equal declined "$OUTPUT" "confirm reports a negative answer"

run_command_with_input $'n\n' "$BASH_BIN" -c \
  'source "$1"; confirm "Continue?" Y true; printf continued' _ "$REPO_DIR/util.sh"
assert_status 1 "confirm can terminate on N"
assert_equal '' "$OUTPUT" "confirm does not continue after terminating on N"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" help
assert_status 0 "help shows general help"
assert_contains "$OUTPUT" 'usage:' "general help output"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh"
assert_status 0 "no arguments shows help"
assert_contains "$OUTPUT" 'usage:' "no-argument help output"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" list
assert_status 0 "list lists components"
assert_equal mock "$OUTPUT" "list strips .sh and excludes directories"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" install mock
assert_status 0 "install dispatches install"
assert_equal 'mock install' "$OUTPUT" "install output"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" uninstall mock
assert_status 0 "uninstall dispatches uninstall"
assert_equal 'mock uninstall' "$OUTPUT" "uninstall output"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" run mock echo_args value
assert_status 0 "run dispatches run"
assert_equal '<value>' "$OUTPUT" "run output"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" mock echo_args value
assert_status 0 "component shortcut dispatches run"
assert_equal '<value>' "$OUTPUT" "component shortcut output"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" mock
assert_status 0 "component shortcut defaults to help"
assert_contains "$OUTPUT" 'supported actions:' "component shortcut help output"

for removed_alias in h -h --help l -l --list i -i --install u -u --uninstall x -x --run; do
  run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" "$removed_alias"
  assert_status 2 "$removed_alias alias is removed"
  assert_contains "$ERROR_OUTPUT" 'unknown command' "$removed_alias removal error"
done

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" help mock
assert_status 0 "component help succeeds"
assert_contains "$OUTPUT" 'supported actions:' "component help heading"
assert_contains "$OUTPUT" 'install' "component help discovers install"
assert_contains "$OUTPUT" 'uninstall' "component help discovers uninstall"
assert_contains "$OUTPUT" 'echo_args' "component help discovers custom actions"
if [[ "$OUTPUT" == *'_private_helper'* || "$OUTPUT" == *'backup'* ]]; then
  fail "component help exposes private or util functions"
else
  pass
fi

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" install
assert_status 2 "install requires a component"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" install mock extra
assert_status 2 "install rejects extra arguments"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" uninstall
assert_status 2 "uninstall requires a component"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" run mock
assert_status 2 "run requires an action"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" list extra
assert_status 2 "list rejects arguments"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" help mock extra
assert_status 2 "component help rejects extra arguments"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" install ../mock
assert_status 2 "component path traversal is rejected"
assert_contains "$ERROR_OUTPUT" 'invalid component name' "invalid component error"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" install missing
assert_status 2 "unknown component is rejected"
assert_contains "$ERROR_OUTPUT" 'unknown component' "unknown component error"

for removed_command in service svc -s restore -r; do
  run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" "$removed_command"
  assert_status 2 "$removed_command is removed"
  assert_contains "$ERROR_OUTPUT" 'unknown command' "$removed_command removal error"
done

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" run mock echo_args 'two words' '*.txt' 'semi;colon' '$HOME'
assert_status 0 "run preserves complex arguments"
assert_equal $'<two words>\n<*.txt>\n<semi;colon>\n<$HOME>' "$OUTPUT" "run argument boundaries"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" mock echo_args 'two words' '*.txt' 'semi;colon' '$HOME'
assert_status 0 "component shortcut preserves complex arguments"
assert_equal $'<two words>\n<*.txt>\n<semi;colon>\n<$HOME>' "$OUTPUT" "component shortcut argument boundaries"

DANGER_MARKER="$TEST_ROOT/danger-called"
cat > "$FAKE_BIN/danger" <<EOF
#!/usr/bin/env bash
printf called > "$DANGER_MARKER"
EOF
chmod +x "$FAKE_BIN/danger"
run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" run mock danger
assert_status 2 "unsupported action is rejected"
assert_contains "$ERROR_OUTPUT" 'supported actions:' "unsupported action lists allowed actions"
assert_not_exists "$DANGER_MARKER" "unsupported action does not execute PATH command"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" mock danger
assert_status 2 "component shortcut rejects unsupported action"
assert_contains "$ERROR_OUTPUT" 'supported actions:' "component shortcut lists allowed actions"
assert_not_exists "$DANGER_MARKER" "component shortcut does not execute PATH command"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" run mock _private_helper
assert_status 2 "private helper action is rejected"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" run mock fail_with 23
assert_status 23 "opener failure status is propagated"

run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$FIXTURE_DIR/biu.sh" mock fail_with 24
assert_status 24 "component shortcut propagates opener failure status"

assert_not_exists "$TEST_HOME/.config" "fixture help does not create .config"
assert_not_exists "$TEST_HOME/.bin" "fixture help does not create .bin"
assert_not_exists "$TEST_HOME/.log" "fixture help does not create .log"
assert_not_exists "$TEST_HOME/.dotfiles.bak" "fixture help does not create backup directory"

PORTABLE_HOME="$TEST_ROOT/portable-home"
OUTSIDE_DIR="$TEST_ROOT/outside"
mkdir -p "$PORTABLE_HOME" "$OUTSIDE_DIR"
ORIGINAL_DIR="$PWD"
cd "$OUTSIDE_DIR"
run_command env HOME="$PORTABLE_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$REPO_DIR/biu.sh" help nvm
cd "$ORIGINAL_DIR"
assert_status 0 "component help works outside the repository"
assert_contains "$OUTPUT" 'update' "portable nvm help output"
assert_not_exists "$PORTABLE_HOME/.config" "portable help does not create .config"
assert_not_exists "$PORTABLE_HOME/.bin" "portable help does not create .bin"
assert_not_exists "$PORTABLE_HOME/.log" "portable help does not create .log"
assert_not_exists "$PORTABLE_HOME/.dotfiles.bak" "portable help does not create backup directory"

run_command env HOME="$PORTABLE_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$REPO_DIR/biu.sh" list
assert_status 0 "real component list succeeds"
assert_contains "$OUTPUT" 'miniforge' "real component list includes miniforge"
REAL_COMPONENTS="$OUTPUT"
if [[ "$OUTPUT" == *'.sh'* || "$OUTPUT" == *'windows'* ]]; then
  fail "real component list contains an extension or directory"
else
  pass
fi

while IFS= read -r component; do
  run_command env HOME="$PORTABLE_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$REPO_DIR/biu.sh" help "$component"
  assert_status 0 "real component help succeeds for $component"
done <<< "$REAL_COMPONENTS"

BREW_FIXTURE="$TEST_ROOT/brew-fixture"
mkdir -p "$BREW_FIXTURE/opener"
cp "$REPO_DIR/opener/brew.sh" "$BREW_FIXTURE/opener/brew.sh"
cat > "$BREW_FIXTURE/util.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
error() { printf 'Error: %s\n' "$*" >&2; }
is_osx() { return 1; }
check_command() { printf checked > "$BREW_MARKER"; exit 99; }
ensure_command() { :; }
run_cmd() {
  local action="${1:-help}"
  shift
  "$action" "$@"
}
EOF
BREW_MARKER="$TEST_ROOT/brew-continued"
export BREW_MARKER
run_command env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$BREW_FIXTURE/opener/brew.sh" install
assert_status 1 "brew install fails immediately outside macOS"
assert_contains "$ERROR_OUTPUT" 'only be installed on macOS' "brew platform error"
assert_not_exists "$BREW_MARKER" "brew does not continue after platform error"

VIM_FIXTURE="$TEST_ROOT/vim-fixture"
VIM_HOME="$TEST_ROOT/vim-home"
VIM_TRACE="$TEST_ROOT/vim-backups"
mkdir -p "$VIM_FIXTURE/opener" "$VIM_HOME"
cp "$REPO_DIR/opener/vim.sh" "$VIM_FIXTURE/opener/vim.sh"
cat > "$VIM_FIXTURE/util.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
is_link_file() { return 1; }
backup() { printf '%s\n' "$1" >> "$VIM_TRACE"; }
link_file() { :; }
create_symbolic_link() { :; }
run_cmd() {
  local action="${1:-help}"
  shift
  "$action" "$@"
}
EOF
printf 'existing vimrc\n' > "$VIM_HOME/.vimrc"
export VIM_TRACE
run_command env HOME="$VIM_HOME" PATH="$FAKE_BIN:$PATH" "$BASH_BIN" "$VIM_FIXTURE/opener/vim.sh" install
assert_status 0 "vim fixture install succeeds"
VIM_TRACE_OUTPUT="$(<"$VIM_TRACE")"
assert_equal $'.vim/\n.vimrc' "$VIM_TRACE_OUTPUT" "vim backs up .vimrc as a HOME-relative path"

if ((FAILURES > 0)); then
  printf '%s/%s assertions failed\n' "$FAILURES" "$ASSERTIONS" >&2
  exit 1
fi

printf 'All %s assertions passed\n' "$ASSERTIONS"
