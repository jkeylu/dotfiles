#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
PICKER="$REPO_DIR/scripts/tools/picker"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/picker-test.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

fail() {
  printf 'picker test failed: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  [[ "$1" == "$2" ]] || fail "$3 (expected '$2', got '$1')"
}

source "$PICKER"

! grep -Fq 'fzf' "$PICKER" || fail 'picker should not depend on fzf'
! grep -Fq -- '--backend' "$PICKER" || fail 'picker should not expose backend selection'

rendered="$(picker_sanitize_for_display $'[Action] New workspace\\path\t中文\033')"
assert_equal "$rendered" $'[Action] New workspace\\path    中文?' \
  'display sanitizer changed ordinary text or leaked control characters'

assert_equal "$(picker_decode_escape_sequence 0 '' 0 '')" cancel \
  'standalone Esc should cancel'
assert_equal "$(picker_decode_escape_sequence 1 a 0 '')" ignore \
  'Alt chords should be ignored'
assert_equal "$(picker_decode_escape_sequence 1 '[' 0 '')" ignore \
  'incomplete escape sequences should be ignored'
assert_equal "$(picker_decode_escape_sequence 1 '[' 1 A)" up \
  'CSI up should move up'
assert_equal "$(picker_decode_escape_sequence 1 O 1 B)" down \
  'SS3 down should move down'
assert_equal "$(picker_decode_escape_sequence 1 '[' 1 Z)" ignore \
  'unknown escape sequences should be ignored'

picker_selectable_window 0 4 4 2 range_start range_end range_total
assert_equal "$range_start,$range_end,$range_total" '1,2,2' \
  'selection footer should exclude action rows'
picker_selectable_window 0 2 4 2 range_start range_end range_total
assert_equal "$range_start,$range_end,$range_total" '0,0,2' \
  'an action-only viewport should report no selectable rows'
picker_selectable_window 3 4 4 2 range_start range_end range_total
assert_equal "$range_start,$range_end,$range_total" '2,2,2' \
  'scrolled ranges should use selectable-row positions'

picker_items=('action' 'app one' 'app two')
picker_multi=1
picker_action_count=1
picker_cursor=1
picker_selected=(0 0 0)
picker_selected_count=0
assert_equal "$(picker_emit_selection)" 'app one' \
  'Enter should submit the current item when none are checked'
picker_selected=(0 0 1)
picker_selected_count=1
assert_equal "$(picker_emit_selection)" 'app two' \
  'Enter should preserve checked selections'
picker_cursor=0
assert_equal "$(picker_emit_selection)" action \
  'an immediate action should override checked selections'

picker_multi=0
picker_quit_enabled=0
picker_read_action 3<<<j
assert_equal "$picker_action" down 'j should move down'
picker_read_action 3<<<k
assert_equal "$picker_action" up 'k should move up'
picker_read_action 3<<<q
assert_equal "$picker_action" ignore 'q should be ignored unless --quit is enabled'
picker_quit_enabled=1
picker_read_action 3<<<q
assert_equal "$picker_action" quit 'q should quit when --quit is enabled'

picker_reset_state
picker_set_default_hint
assert_equal "$picker_hint" 'Up/Down or j/k: move  Enter: select  Esc: cancel' \
  'single-select hint should describe every navigation key'
picker_reset_state
picker_multi=1
picker_quit_enabled=1
picker_set_default_hint
assert_equal "$picker_hint" \
  'Up/Down or j/k: move  Space: toggle  Enter: confirm  Esc: cancel  q: quit' \
  'multi-select hint should describe selection and quit keys'

picker_reset_state
picker_parse_args --multi --actions=08 --quit --prompt Choose --hint Help
((picker_multi == 1)) || fail '--multi was not parsed'
((picker_action_count == 8)) || fail '--actions should parse leading zeros as decimal'
((picker_quit_enabled == 1)) || fail '--quit was not parsed'
assert_equal "$picker_prompt" Choose '--prompt was not parsed'
assert_equal "$picker_hint" Help '--hint was not parsed'

if picker_parse_args --backend builtin >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  fail 'removed --backend option should fail'
else
  status=$?
  ((status == 2)) || fail 'removed --backend option should return status 2'
fi

if picker_main --actions 1 <<<one >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  fail '--actions without --multi should fail'
else
  status=$?
  ((status == 2)) || fail '--actions without --multi should return status 2'
  grep -Fq -- '--actions requires --multi' "$TEST_ROOT/error" ||
    fail '--actions without --multi should explain the invalid combination'
fi

if picker_main --multi --actions 2 <<<one >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  fail 'an action count larger than the item count should fail'
else
  status=$?
  ((status == 2)) || fail 'excessive action count should return status 2'
fi

if picker_main </dev/null >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"; then
  fail 'empty input should not produce a selection'
else
  status=$?
  ((status == 1)) || fail 'empty input should return status 1'
fi

# A ten-row terminal has room for five items after the three-line header and
# two-line footer. Nine line feeds position the footer on the final row without
# scrolling it out of the alternate screen.
picker_reset_state
picker_items=(one two three four five six)
picker_display_items=(one two three four five six)
picker_display_prompt=Choose
picker_display_hint=Help
picker_cursor=0
picker_offset=0
stty() {
  [[ "${1-}" == size ]] || return 1
  printf '10 20\n'
}
exec 3>"$TEST_ROOT/render"
picker_draw_menu
exec 3>&-
unset -f stty
line_feeds="$(tr -cd '\n' <"$TEST_ROOT/render" | wc -c | tr -d ' ')"
assert_equal "$line_feeds" 9 'full-height rendering should not scroll the terminal'
grep -Fq five "$TEST_ROOT/render" || fail 'last visible item was not rendered'
! grep -Fq six "$TEST_ROOT/render" || fail 'item below the viewport was rendered'
grep -Fq '1 of 6' "$TEST_ROOT/render" || fail 'single-select footer is incorrect'

printf 'picker tests passed\n'
