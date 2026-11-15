#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$REPO_DIR/scripts/git/git-merged"
TEST_TMP_DIR="$(cd -- "${TMPDIR:-/tmp}" && pwd -P)"
TEST_ROOT="$(mktemp -d "$TEST_TMP_DIR/git-merged-test.XXXXXX")"
cleanup() {
  # Keep recursive cleanup confined to the resolved temporary test directory.
  [[ "$TEST_ROOT" == "$TEST_TMP_DIR"/git-merged-test.* && -d "$TEST_ROOT" ]] || return 0
  [[ "$(cd -- "$TEST_ROOT" && pwd -P)" == "$TEST_ROOT" ]] || return 1
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0

git init --bare "$TEST_ROOT/remote.git" >/dev/null 2>&1
git init -b main "$TEST_ROOT/work" >/dev/null 2>&1
git -C "$TEST_ROOT/work" config user.name Test
git -C "$TEST_ROOT/work" config user.email test@example.com
printf 'initial\n' > "$TEST_ROOT/work/file"
git -C "$TEST_ROOT/work" add file
git -C "$TEST_ROOT/work" commit -m initial >/dev/null
git -C "$TEST_ROOT/work" remote add origin "$TEST_ROOT/remote.git"
git -C "$TEST_ROOT/work" push -u origin main >/dev/null 2>&1
git -C "$TEST_ROOT/work" branch merged-a
git -C "$TEST_ROOT/work" branch merged-b
git -C "$TEST_ROOT/work" branch local-only
git -C "$TEST_ROOT/work" push -u origin merged-a >/dev/null 2>&1
git -C "$TEST_ROOT/work" push -u origin merged-b:archived-b >/dev/null 2>&1
git -C "$TEST_ROOT/work" switch -c pending >/dev/null 2>&1
printf 'pending\n' >> "$TEST_ROOT/work/file"
git -C "$TEST_ROOT/work" commit -am pending >/dev/null
git -C "$TEST_ROOT/work" switch main >/dev/null 2>&1

mkdir "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/picker" <<'EOF'
#!/usr/bin/env bash
items="$(cat)"
[[ -z "${TEST_PICKER_INPUT:-}" ]] || printf '%s\n' "$items" > "$TEST_PICKER_INPUT"
[[ " $* " == *' --multi '* ]] || exit 97
[[ "${TEST_PICKER_STATUS:-0}" -eq 0 ]] || exit "$TEST_PICKER_STATUS"
if [[ -n "${TEST_GROUPS:-}" ]]; then
  while IFS= read -r group; do
    while IFS= read -r item; do
      [[ "${item%%$'\t'*}" != "$group" ]] || printf '%s\n' "$item"
    done <<< "$items"
  done <<< "$TEST_GROUPS"
else
  printf '%s\n' "${TEST_SELECTION:-}"
fi
EOF
chmod +x "$TEST_ROOT/bin/picker"
export PATH="$TEST_ROOT/bin:$REPO_DIR/scripts/tools:$REPO_DIR/scripts/git:$PATH"

cd "$TEST_ROOT/work"

actual="$(git merged main)"
expected="$(printf 'local-only\nmerged-a\nmerged-b')"
[[ "$actual" == "$expected" ]] || { printf 'unexpected merged branches: %s\n' "$actual" >&2; exit 1; }
[[ "$(bash "$SCRIPT")" == "$expected" ]] || { printf 'HEAD default failed\n' >&2; exit 1; }
if bash "$SCRIPT" main extra >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  printf 'extra arguments should fail\n' >&2
  exit 1
fi

export TEST_SELECTION=$'merged-a\nmerged-b'
TEST_PICKER_STATUS=130 bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
git show-ref --verify --quiet refs/heads/merged-a
TEST_SELECTION=main
if printf 'y\n' | bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  printf 'invalid selection should fail\n' >&2
  exit 1
fi
export TEST_SELECTION=$'merged-a\nmerged-b'
printf 'n\n' | bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
git show-ref --verify --quiet refs/heads/merged-a
git --git-dir="$TEST_ROOT/remote.git" show-ref --verify --quiet refs/heads/merged-a

printf 'y\n' | bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
if git show-ref --verify --quiet refs/heads/merged-a ||
   git show-ref --verify --quiet refs/heads/merged-b ||
   git --git-dir="$TEST_ROOT/remote.git" show-ref --verify --quiet refs/heads/merged-a ||
   git --git-dir="$TEST_ROOT/remote.git" show-ref --verify --quiet refs/heads/archived-b; then
  printf 'selected local or remote branches remain\n' >&2
  exit 1
fi
git show-ref --verify --quiet refs/heads/local-only
git show-ref --verify --quiet refs/heads/pending

export TEST_SELECTION=local-only
printf 'yes\n' | bash "$SCRIPT" --clean >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
if git show-ref --verify --quiet refs/heads/local-only; then
  printf 'local-only branch remains\n' >&2
  exit 1
fi

git branch untracked main
git push origin untracked >/dev/null 2>&1
export TEST_SELECTION=untracked
printf 'y\n' | bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
if git show-ref --verify --quiet refs/heads/untracked ||
   git --git-dir="$TEST_ROOT/remote.git" show-ref --verify --quiet refs/heads/untracked; then
  printf 'same-named remote branch without upstream remains\n' >&2
  exit 1
fi

git worktree add -b linked "$TEST_ROOT/linked" main >/dev/null 2>&1
export TEST_SELECTION=linked
if printf 'y\n' | bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  printf 'checked-out worktree branch should block deletion\n' >&2
  exit 1
fi
git show-ref --verify --quiet refs/heads/linked
git worktree remove "$TEST_ROOT/linked" >/dev/null 2>&1

git branch divergent main
git push -u origin divergent >/dev/null 2>&1
git push origin pending:divergent >/dev/null 2>&1
export TEST_SELECTION=divergent
if printf 'y\n' | bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  printf 'divergent remote should block deletion\n' >&2
  exit 1
fi
git show-ref --verify --quiet refs/heads/divergent
git --git-dir="$TEST_ROOT/remote.git" show-ref --verify --quiet refs/heads/divergent

git init -b main "$TEST_ROOT/only" >/dev/null 2>&1
git -C "$TEST_ROOT/only" config user.name Test
git -C "$TEST_ROOT/only" config user.email test@example.com
git -C "$TEST_ROOT/only" commit --allow-empty -m initial >/dev/null
[[ -z "$(cd "$TEST_ROOT/only" && bash "$SCRIPT")" ]] || {
  printf 'a repository with one branch should produce no output\n' >&2
  exit 1
}

# Remote comparison has its own fixtures, independent of the legacy cleanup.
git init --bare "$TEST_ROOT/joint-origin.git" >/dev/null 2>&1
git init --bare "$TEST_ROOT/joint-upstream.git" >/dev/null 2>&1
git init -b main "$TEST_ROOT/joint" >/dev/null 2>&1
cd "$TEST_ROOT/joint"
git config user.name Test
git config user.email test@example.com
git commit --allow-empty -m base >/dev/null
base_oid="$(git rev-parse HEAD)"
GIT_AUTHOR_NAME='Remote Author' GIT_COMMITTER_NAME='Merge Bot' \
  GIT_AUTHOR_DATE='2025-02-01T09:30:00+0530' GIT_COMMITTER_DATE='2025-02-02T15:04:00+0530' \
  git commit --allow-empty -m included >/dev/null
included_oid="$(git rev-parse HEAD)"
git remote add origin "$TEST_ROOT/joint-origin.git"
git remote add upstream "$TEST_ROOT/joint-upstream.git"
git push -u origin main >/dev/null 2>&1
git push upstream main >/dev/null 2>&1
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

for name in same different alias-a alias-b local-only slash/topic skip-local shared-good upstream-linked stale changed-target changed-local changed-tracking lease-race new-counterpart; do
  git branch "$name" "$base_oid"
done
git push origin same different:renamed alias-a:shared main:remote-only slash/topic skip-local \
  main:skip-remote shared-good:shared-mixed stale changed-target changed-local changed-tracking lease-race >/dev/null 2>&1
# Both tips are ancestors of main, but do not have to be equal to be deletable.
git push origin main:renamed >/dev/null 2>&1
git branch --set-upstream-to=origin/renamed different >/dev/null
git branch --set-upstream-to=origin/shared alias-a >/dev/null
git branch --set-upstream-to=origin/shared alias-b >/dev/null
git branch --set-upstream-to=origin/shared-mixed shared-good >/dev/null
git push -u upstream upstream-linked:upstream-renamed >/dev/null 2>&1
git push upstream main:upstream-only >/dev/null 2>&1
git push origin upstream-linked >/dev/null 2>&1

git switch -c pending >/dev/null 2>&1
git commit --allow-empty -m pending >/dev/null
pending_oid="$(git rev-parse HEAD)"
git branch skip-remote
git branch shared-bad
git branch --set-upstream-to=origin/shared-mixed shared-bad >/dev/null
git push origin pending:skip-local >/dev/null 2>&1
git switch main >/dev/null 2>&1
git worktree add -b linked-joint "$TEST_ROOT/joint-linked" main >/dev/null 2>&1
git push origin linked-joint >/dev/null 2>&1

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_has() { grep -Fq -- "$2" "$1" || fail "missing '$2' in $1"; }
assert_lacks() { ! grep -Fq -- "$2" "$1" || fail "unexpected '$2' in $1"; }
assert_local() { git show-ref --verify --quiet "refs/heads/$1" || fail "local $1 is missing"; }
assert_no_local() { ! git show-ref --verify --quiet "refs/heads/$1" || fail "local $1 remains"; }
assert_remote() { git --git-dir="$TEST_ROOT/joint-$1.git" show-ref --verify --quiet "refs/heads/$2" || fail "remote $1/$2 is missing"; }
assert_no_remote() { ! git --git-dir="$TEST_ROOT/joint-$1.git" show-ref --verify --quiet "refs/heads/$2" || fail "remote $1/$2 remains"; }
query() { bash "$SCRIPT" "$@" > "$TEST_ROOT/report" 2> "$TEST_ROOT/error"; }
clean_groups() {
  TEST_GROUPS=$1
  export TEST_GROUPS
  shift
  printf 'y\n' | bash "$SCRIPT" "$@" > "$TEST_ROOT/output" 2> "$TEST_ROOT/error"
}
expect_clean_failure() {
  if clean_groups "$@"; then
    fail 'cleanup should fail'
  fi
}

# Log all Git commands and simulate changes after confirmation but before push.
REAL_GIT="$(command -v git)"
export REAL_GIT TEST_GIT_LOG="$TEST_ROOT/git-log" TEST_PICKER_INPUT="$TEST_ROOT/picker-input"
cat > "$TEST_ROOT/bin/git" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_GIT_LOG"
if [[ "$1" == push && -n "${TEST_PUSH_RACE_REF:-}" ]]; then
  "$REAL_GIT" --git-dir="$TEST_RACE_REMOTE" update-ref "$TEST_PUSH_RACE_REF" "$TEST_RACE_OID" || exit 90
fi
exec "$REAL_GIT" "$@"
EOF
chmod +x "$TEST_ROOT/bin/git"
hash -r

query -r
assert_has "$TEST_ROOT/report" "Target: HEAD (${included_oid:0:6})"
assert_has "$TEST_ROOT/report" 'remote: origin'
assert_has "$TEST_ROOT/report" 'different (different: local-only=0 remote-only=1)'
assert_has "$TEST_ROOT/report" "L: different (M, ${base_oid:0:6})"
assert_has "$TEST_ROOT/report" "R: renamed (M, ${included_oid:0:6}, 2025-02-02 15:04 +0530, Remote Author)"
assert_has "$TEST_ROOT/report" 'L: alias-a (M,'
assert_has "$TEST_ROOT/report" 'L: alias-b (M,'
assert_has "$TEST_ROOT/report" 'local only'
assert_has "$TEST_ROOT/report" 'remote only'
assert_has "$TEST_ROOT/report" 'unmerged member'
assert_has "$TEST_ROOT/report" 'skip: comparison target'
assert_has "$TEST_ROOT/report" 'checked out in worktree'
assert_has "$TEST_ROOT/report" 'R: slash/topic (M,'
assert_lacks "$TEST_ROOT/report" 'origin/'
assert_lacks "$TEST_ROOT/report" 'R: HEAD ('
assert_lacks "$TEST_ROOT/report" 'R: upstream-only ('
assert_lacks "$TEST_ROOT/report" 'git fetch'
assert_has "$TEST_ROOT/error" 'git fetch origin --prune'
assert_lacks "$TEST_GIT_LOG" 'ls-remote'
assert_lacks "$TEST_GIT_LOG" 'fetch '

query main -r
assert_has "$TEST_ROOT/report" 'Target: main'
query -r origin main
assert_has "$TEST_ROOT/report" 'Target: main'
query -r origin origin/HEAD
assert_has "$TEST_ROOT/report" 'Target: origin/HEAD'
assert_has "$TEST_ROOT/report" 'skip: comparison target'
query --remote upstream
assert_has "$TEST_ROOT/report" 'remote: upstream'
assert_has "$TEST_ROOT/report" 'R: upstream-renamed (M,'
assert_lacks "$TEST_ROOT/report" 'upstream/'
assert_lacks "$TEST_ROOT/report" 'R: renamed ('
for remote_name in missing main; do
  if query -r "$remote_name"; then fail 'unknown remote accepted'; fi
  assert_has "$TEST_ROOT/error" "remote '$remote_name' does not exist"
done
if query -r origin main extra; then fail 'extra target accepted'; fi

# The picker only offers fully merged, unprotected groups. Cancellation is safe.
TEST_SELECTION= TEST_GROUPS= TEST_PICKER_STATUS=130 query --clean -r
for group in main linked-joint skip-local skip-remote shared-mixed pending; do
  assert_lacks "$TEST_PICKER_INPUT" "$group"$'\t'
done
assert_has "$TEST_PICKER_INPUT" 'renamed'$'\t'
assert_has "$TEST_PICKER_INPUT" "R: renamed (M, ${included_oid:0:6}, 2025-02-02 15:04 +0530, Remote Author)"
assert_has "$TEST_PICKER_INPUT" 'shared'$'\t'
assert_local same
TEST_SELECTION= TEST_GROUPS= TEST_PICKER_STATUS=1 query -r --clean
TEST_SELECTION= TEST_GROUPS= query -r --clean
TEST_GROUPS=same TEST_SELECTION= query -r --clean < /dev/null
TEST_GROUPS=same TEST_SELECTION= bash "$SCRIPT" --clean -r <<< n > "$TEST_ROOT/output" 2> "$TEST_ROOT/error"
assert_local same
assert_remote origin same
if TEST_SELECTION=invalid TEST_GROUPS= query --clean -r; then fail 'invalid group accepted'; fi
expect_clean_failure $'same\nsame' --clean -r
assert_local same
if TEST_PICKER_STATUS=7 query --clean -r; then fail 'picker failure ignored'; fi
assert_has "$TEST_ROOT/error" 'picker failed'

# Live server updates and removals cannot be mistaken for local/remote differences.
git --git-dir="$TEST_ROOT/joint-origin.git" update-ref refs/heads/stale "$included_oid"
expect_clean_failure stale --clean -r
assert_has "$TEST_ROOT/error" 'differs from the remote-tracking snapshot'
assert_local stale
git --git-dir="$TEST_ROOT/joint-origin.git" update-ref -d refs/heads/stale
expect_clean_failure stale --clean -r
assert_local stale
# A branch absent from tracking refs but present on the server also blocks cleanup.
git --git-dir="$TEST_ROOT/joint-origin.git" update-ref refs/heads/new-counterpart "$pending_oid"
expect_clean_failure new-counterpart --clean -r
assert_local new-counterpart

# Wait for the confirmation prompt before changing refs and sending the answer.
confirm_with_change() {
  local group=$1 action=$2 original_oid=$3
  local -a pipe_status
  export TEST_GROUPS=$group
  : > "$TEST_ROOT/error"
  if {
    changed=0
    for ((attempt=0; attempt<1000; attempt++)); do
      if grep -Fq 'Confirm deletion [y/N]:' "$TEST_ROOT/error"; then
        git update-ref "$action" "$included_oid" || exit 90
        changed=1
        break
      fi
      sleep 0.02
    done
    [[ "$changed" -eq 1 ]] || exit 91
    printf 'y\n'
  } | bash "$SCRIPT" --clean -r > "$TEST_ROOT/output" 2> "$TEST_ROOT/error"; then
    fail 'confirmation-time change was accepted'
  else
    pipe_status=("${PIPESTATUS[@]}")
  fi
  [[ "${pipe_status[0]}" -eq 0 ]] || fail 'confirmation prompt was not reached'
  git update-ref "$action" "$original_oid"
  assert_local "$group"
  assert_remote origin "$group"
}
confirm_with_change changed-local refs/heads/changed-local "$base_oid"
assert_has "$TEST_ROOT/error" 'changed or is no longer merged'
confirm_with_change changed-tracking refs/remotes/origin/changed-tracking "$base_oid"
assert_has "$TEST_ROOT/error" 'changed or is no longer merged'
# For the target test, use a different ancestor as the changed target.
git update-ref refs/heads/main "$base_oid"
confirm_with_change changed-target refs/heads/main "$base_oid"
assert_has "$TEST_ROOT/error" 'comparison target'
git update-ref refs/heads/main "$included_oid"

# A server change in the final gap is rejected by the lease; local stays intact.
export TEST_PUSH_RACE_REF=refs/heads/lease-race TEST_RACE_OID=$included_oid TEST_RACE_REMOTE="$TEST_ROOT/joint-origin.git"
expect_clean_failure lease-race --clean -r
unset TEST_PUSH_RACE_REF
assert_local lease-race
assert_remote origin lease-race
assert_has "$TEST_ROOT/error" 'stale info'

# Remove only the selected remote's branches, even with an upstream elsewhere.
: > "$TEST_GIT_LOG"
clean_groups upstream-linked --clean -r
assert_no_local upstream-linked
assert_no_remote origin upstream-linked
assert_remote upstream upstream-renamed
assert_lacks "$TEST_GIT_LOG" 'ls-remote --heads upstream'
assert_lacks "$TEST_GIT_LOG" 'fetch '
assert_lacks "$TEST_GIT_LOG" 'push --force-with-lease=refs/heads/upstream-renamed'

clean_groups $'same\nrenamed\nshared\nlocal-only\nremote-only\nslash/topic' -r --clean
for name in same different alias-a alias-b local-only slash/topic; do assert_no_local "$name"; done
for name in same renamed shared remote-only slash/topic; do assert_no_remote origin "$name"; done
[[ "$(grep -Fc ':refs/heads/shared' "$TEST_GIT_LOG")" -eq 1 ]] || fail 'shared remote deleted more than once'
assert_has "$TEST_ROOT/error" 'different (different: local-only=0 remote-only=1)'
assert_has "$TEST_ROOT/error" 'L: alias-a (M,'
assert_has "$TEST_ROOT/error" 'L: alias-b (M,'
assert_has "$TEST_ROOT/error" "R: renamed (M, ${included_oid:0:6}, 2025-02-02 15:04 +0530, Remote Author)"
for name in main linked-joint skip-local skip-remote shared-good shared-bad; do assert_local "$name"; done
for name in main linked-joint skip-local skip-remote shared-mixed; do assert_remote origin "$name"; done

clean_groups upstream-only --clean -r upstream
assert_no_remote upstream upstream-only
assert_remote upstream main
git worktree remove "$TEST_ROOT/joint-linked" >/dev/null 2>&1

# With only protected or unmerged groups, there is nothing to select.
cd "$TEST_ROOT/only"
git remote add origin "$TEST_ROOT/joint-origin.git"
TEST_PICKER_STATUS=7 query --clean -r
assert_has "$TEST_ROOT/error" 'No merged branch groups eligible for cleanup.'

printf 'git-merged tests passed\n'
