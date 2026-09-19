#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$REPO_DIR/scripts/git/git-merged"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/git-merged-test.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

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
cat > "$TEST_ROOT/bin/fzf" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
[[ "${TEST_FZF_STATUS:-0}" -eq 0 ]] || exit "$TEST_FZF_STATUS"
printf '%s\n' "$TEST_SELECTION"
EOF
chmod +x "$TEST_ROOT/bin/fzf"
export PATH="$REPO_DIR/scripts/git:$TEST_ROOT/bin:$PATH"

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
TEST_FZF_STATUS=130 bash "$SCRIPT" --clean main >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
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

printf 'git-merged tests passed\n'
