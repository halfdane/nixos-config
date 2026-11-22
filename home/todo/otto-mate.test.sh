#!/usr/bin/env bash
set -u

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
addon=$script_dir/otto-mate.sh
guide=$script_dir/otto-mate-guide.md
wrapper=$script_dir/todo-wrapper.sh

for constant in PRUNE_AFTER_DAYS MAX_SINCE_DAYS; do
    eval "$(grep "^$constant=" "$addon")"
done

if ! command -v todo.sh > /dev/null; then
    echo "todo.sh is not in PATH"
    exit 1
fi

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

failures=0
case_number=0
tolerance_seconds=5

new_case() {
    case_number=$((case_number + 1))
    case_dir=$workdir/case$case_number
    todo_dir=$case_dir/todo
    actions_dir=$case_dir/actions
    config=$case_dir/config
    mkdir -p "$todo_dir" "$actions_dir/otto-mate"
    install -m755 "$addon" "$actions_dir/otto-mate/otto-mate"
    install -m644 "$guide" "$actions_dir/otto-mate/otto-mate-guide.md"
    printf 'export TODO_DIR=%s\nexport TODO_ACTIONS_DIR=%s\n' "$todo_dir" "$actions_dir" > "$config"
}

assert_equals() {
    if [[ $2 != "$3" ]]; then
        failures=$((failures + 1))
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$1" "$3" "$2"
    fi
}

assert_succeeds() {
    local description=$1
    shift
    if ! "$@" > /dev/null 2>&1; then
        failures=$((failures + 1))
        printf 'FAIL: %s\n  command failed: %s\n' "$description" "$*"
    fi
}

assert_fails() {
    local description=$1
    shift
    if "$@" > /dev/null 2>&1; then
        failures=$((failures + 1))
        printf 'FAIL: %s\n  command succeeded: %s\n' "$description" "$*"
    fi
}

todo() {
    TODOTXT_CFG_FILE=$config todo.sh "$@"
}

days_ago() {
    date -d "$1 days ago" +%F
}

assert_near_epoch() {
    local actual_epoch
    actual_epoch=$(date -u -d "$2" +%s)
    if (( actual_epoch < $3 - tolerance_seconds || actual_epoch > $3 + tolerance_seconds )); then
        failures=$((failures + 1))
        printf 'FAIL: %s\n  expected epoch near: %s\n  actual: %s (%s)\n' "$1" "$3" "$2" "$actual_epoch"
    fi
}

new_case
assert_equals "help prints the guide" "$(todo otto-mate help)" "$(cat "$guide")"

new_case
assert_equals "help works from any directory" "$(cd / && todo otto-mate help | head -n 1)" "$(head -n 1 "$guide")"

new_case
assert_near_epoch "since without file is the cap" "$(todo otto-mate since)" "$(($(date +%s) - MAX_SINCE_DAYS * 86400))"

new_case
touch -d "2 hours ago" "$todo_dir/.last-extraction"
assert_equals "since with fresh file is the file time" \
    "$(todo otto-mate since)" "$(date -u -d "@$(stat -c %Y "$todo_dir/.last-extraction")" +%Y-%m-%dT%H:%M:%SZ)"

new_case
touch -d "$((MAX_SINCE_DAYS + 23)) days ago" "$todo_dir/.last-extraction"
assert_near_epoch "since with old file is capped" "$(todo otto-mate since)" "$(($(date +%s) - MAX_SINCE_DAYS * 86400))"

new_case
assert_equals "since prints ISO 8601 UTC" \
    "$(todo otto-mate since | grep -cE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$')" "1"

new_case
todo otto-mate add "Plain item +retro url:https://example.com/a" > /dev/null
assert_equals "add appends a valid line and adds the date" \
    "$(cat "$todo_dir/inbox.txt")" "$(date +%F) Plain item +retro url:https://example.com/a"

new_case
todo otto-mate add "(B) Prio item" > /dev/null
assert_equals "add keeps the priority" "$(cat "$todo_dir/inbox.txt")" "(B) $(date +%F) Prio item"

new_case
todo otto-mate add "(B) 2026-11-01 Dated item" > /dev/null
assert_equals "add keeps an existing date" "$(cat "$todo_dir/inbox.txt")" "(B) 2026-11-01 Dated item"

new_case
printf 'first' > "$todo_dir/inbox.txt"
todo otto-mate add "Second" > /dev/null
assert_equals "add keeps existing lines apart" "$(sed -n 1p "$todo_dir/inbox.txt")" "first"

new_case
assert_fails "add rejects an empty line" todo otto-mate add ""
assert_fails "add rejects a blank line" todo otto-mate add "   "
assert_fails "add rejects a done item" todo otto-mate add "x 2026-11-18 Finished"
assert_fails "add rejects a priority without text" todo otto-mate add "(A)"
assert_fails "add rejects a date without text" todo otto-mate add "2026-11-18"
assert_fails "add rejects a multi-line value" todo otto-mate add $'one\ntwo'
assert_fails "add rejects no argument" todo otto-mate add
assert_equals "rejected lines write nothing" "$([[ -e $todo_dir/inbox.txt ]] && echo exists)" ""

new_case
mkdir "$todo_dir/inbox.txt"
failed_add_output=$(todo otto-mate add "Unwritable" 2>&1)
failed_add_status=$?
assert_equals "add exits non-zero when the write fails" "$((failed_add_status != 0))" "1"
assert_equals "add prints no added line when the write fails" \
    "$(printf '%s\n' "$failed_add_output" | grep -c '^added:')" "0"

new_case
{
    printf '%s Old item\n' "$(days_ago $((PRUNE_AFTER_DAYS + 1)))"
    printf '(A) %s Old prio item\n' "$(days_ago $((PRUNE_AFTER_DAYS + 3)))"
    printf '%s Recent item\n' "$(days_ago $((PRUNE_AFTER_DAYS - 1)))"
    printf '%s Boundary item\n' "$(days_ago "$PRUNE_AFTER_DAYS")"
    printf 'Undated item\n'
} > "$todo_dir/inbox.txt"
todo otto-mate finish > /dev/null
assert_equals "finish prunes old lines and keeps recent, boundary and undated lines" \
    "$(cat "$todo_dir/inbox.txt")" \
    "$(printf '%s Recent item\n%s Boundary item\nUndated item' "$(days_ago $((PRUNE_AFTER_DAYS - 1)))" "$(days_ago "$PRUNE_AFTER_DAYS")")"
assert_succeeds "finish touches .last-extraction" test -e "$todo_dir/.last-extraction"

new_case
assert_succeeds "finish works without an inbox" todo otto-mate finish
assert_succeeds "finish creates .last-extraction without an inbox" test -e "$todo_dir/.last-extraction"

new_case
touch -d "3 days ago" "$todo_dir/.last-extraction"
todo otto-mate finish > /dev/null
assert_equals "finish refreshes .last-extraction" \
    "$(find "$todo_dir/.last-extraction" -mmin -1 | wc -l)" "1"

new_case
printf 'one\ntwo\nthree\n' > "$todo_dir/inbox.txt"
printf 'open\n' > "$todo_dir/todo.txt"
todo otto-mate accept 2 > /dev/null
assert_equals "accept appends line to todo.txt" "$(cat "$todo_dir/todo.txt")" "$(printf 'open\ntwo')"
assert_equals "accept leaves a blank line in inbox.txt" "$(cat "$todo_dir/inbox.txt")" "$(printf 'one\n\nthree')"

new_case
printf 'one\n' > "$todo_dir/inbox.txt"
: > "$todo_dir/todo.txt"
assert_fails "accept rejects a missing line number" todo otto-mate accept 5
assert_fails "accept rejects a non-number" todo otto-mate accept abc
assert_fails "accept rejects no argument" todo otto-mate accept
assert_equals "failed accept changes nothing" "$(cat "$todo_dir/inbox.txt")|$(cat "$todo_dir/todo.txt")" "one|"

new_case
printf 'one\ntwo\nthree\n' > "$todo_dir/inbox.txt"
printf 'open\n' > "$todo_dir/todo.txt"
todo otto-mate reject 2 > /dev/null
assert_equals "reject deletes line from inbox.txt" "$(cat "$todo_dir/inbox.txt")" "$(printf 'one\n\nthree')"
assert_equals "reject leaves todo.txt alone" "$(cat "$todo_dir/todo.txt")" "open"
assert_fails "reject rejects a missing line number" todo otto-mate reject 9
assert_fails "reject rejects a non-number" todo otto-mate reject abc

new_case
printf 'Open item +retro\n' > "$todo_dir/todo.txt"
bare_output=$(TODOTXT_CFG_FILE=$config bash "$wrapper")
assert_equals "bare todo prints the hint above the list" "$(printf '%s\n' "$bare_output" | sed -n 1,2p)" \
    "$(printf 'For agents extracting todos from Microsoft 365: todo otto-mate help\nAll commands: todo -h')"
assert_equals "bare todo prints the list after the hint" "$(printf '%s\n' "$bare_output" | sed -n 3p)" "1 Open item +retro"

new_case
printf 'Open item\n' > "$todo_dir/todo.txt"
assert_equals "todo with arguments prints no hint" "$(TODOTXT_CFG_FILE=$config bash "$wrapper" ls | sed -n 1p)" "1 Open item"

new_case
assert_equals "todo -h lists the add-on" "$(todo -h | grep -c 'otto-mate help')" "1"

if ((failures > 0)); then
    printf '%d failure(s)\n' "$failures"
    exit 1
fi
printf 'all %d cases passed\n' "$case_number"
