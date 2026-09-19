#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/picker-test.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT
mkdir "$TEST_ROOT/bin"

cat > "$TEST_ROOT/bin/fzf" <<'EOF'
#!/usr/bin/env bash
input="$(cat)"
[[ "$input" == $'one\ntwo\nthree' ]] || exit 98
[[ " $* " == *' --prompt=Choose>  '* ]] || exit 95
[[ "${FAKE_FZF_STATUS:-0}" -eq 0 ]] || exit "$FAKE_FZF_STATUS"
if [[ "${EXPECTED_MODE:-single}" == multi ]]; then
  [[ " $* " == *' --multi '* ]] || exit 97
  [[ " $* " == *' space:toggle '* ]] || exit 96
  printf 'two\nthree\n'
else
  [[ " $* " != *' --multi '* ]] || exit 97
  [[ " $* " != *' space:toggle '* ]] || exit 96
  [[ " $* " == *' --no-multi '* ]] || exit 94
  printf 'two\n'
fi
EOF
chmod +x "$TEST_ROOT/bin/fzf"
export PATH="$REPO_DIR/scripts/tools:$TEST_ROOT/bin:$PATH"

choices=$'one\ntwo\nthree\n'
output="$(printf '%s' "$choices" | picker --prompt Choose)"
[[ "$output" == two ]] || { printf 'single selection failed\n' >&2; exit 1; }

output="$(printf '%s' "$choices" | EXPECTED_MODE=multi picker --prompt Choose --multi)"
[[ "$output" == $'two\nthree' ]] || { printf 'multiple selection failed\n' >&2; exit 1; }

output="$(printf '%s' "$choices" | DOTFILES_PICKER_BUILTIN=0 picker --prompt Choose)"
[[ "$output" == two ]] || { printf 'forced fzf selection failed\n' >&2; exit 1; }

set +e
printf '%s' "$choices" | FAKE_FZF_STATUS=130 picker --prompt Choose >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
status=$?
set -e
[[ "$status" -eq 130 && ! -s "$TEST_ROOT/output" ]] || {
  printf 'cancellation should return 130 without output\n' >&2
  exit 1
}

set +e
printf '%s' "$choices" | DOTFILES_PICKER_BUILTIN=invalid picker >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
status=$?
set -e
[[ "$status" -eq 2 ]] || { printf 'invalid backend setting should fail\n' >&2; exit 1; }

printf 'picker tests passed\n'
