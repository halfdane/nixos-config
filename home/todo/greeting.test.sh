#!/usr/bin/env bash
set -u

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
greeting=$script_dir/greeting.sh

for constant in STALE_AFTER_DAYS TOP_ITEM_COUNT; do
    eval "$(grep "^$constant=" "$greeting")"
done

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

failures=0
case_number=0

new_case() {
    case_number=$((case_number + 1))
    todo_dir=$workdir/case$case_number/todo
    mkdir -p "$todo_dir"
}

assert_equals() {
    if [[ $2 != "$3" ]]; then
        failures=$((failures + 1))
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$1" "$3" "$2"
    fi
}

greet() {
    "$greeting" "$todo_dir"
}

new_case
cat > "$todo_dir/todo.txt" <<'EOF'
2026-11-18 Servicedesk-Ticket Retro-Moderation +retro
x 2026-11-18 Already finished +done due:2026-11-01
(A) 2026-11-18 Tricorder-Review +tricorder due:2026-11-20 url:https://example.com/a

(B) 2026-11-18 Marketplace anzeigen +marketplace due:2026-11-19 url:https://example.com/b
2026-11-18 Retro nachfassen +retro due:2026-11-23
(A) Ohne Datum +misc
(C) Letztes due:2026-11-23
EOF
expected_order=(
    "(B) Marketplace anzeigen  due 19.11."
    "(A) Tricorder-Review  due 20.11."
    "(C) Letztes  due 23.11."
    "Retro nachfassen  due 23.11."
    "(A) Ohne Datum"
    "Servicedesk-Ticket Retro-Moderation"
)
expected_top=
for ((i = 0; i < TOP_ITEM_COUNT; i++)); do
    expected_top+="${expected_top:+ | }${expected_order[i]}"
done
assert_equals "sorts by due, then priority, then file order; hides done items, projects, urls" \
    "$(greet | sed -n 1p)" "todo: $expected_top"

new_case
printf '(A) Nur eins\n' > "$todo_dir/todo.txt"
assert_equals "single item without due" "$(greet | sed -n 1p)" "todo: (A) Nur eins"

new_case
assert_equals "empty todo list" "$(greet | sed -n 1p)" "todo: nothing open"

new_case
missing_dir=$workdir/does-not-exist
assert_equals "missing directory prints share message" \
    "$("$greeting" "$missing_dir")" "todo share not mounted"

new_case
assert_equals "missing inbox counts zero" "$(greet | sed -n 2p)" "inbox: 0   last extraction: never"

new_case
printf 'one\n\ntwo\n   \nthree\n' > "$todo_dir/inbox.txt"
assert_equals "inbox count ignores blank lines" "$(greet | sed -n 2p | cut -d' ' -f1-2)" "inbox: 3"

new_case
touch "$todo_dir/.last-extraction"
assert_equals "fresh extraction" "$(greet | sed -n 2p)" "inbox: 0   last extraction: today"

new_case
touch -d "$((STALE_AFTER_DAYS * 24 - 1)) hours ago" "$todo_dir/.last-extraction"
assert_equals "extraction just below the threshold is not stale" \
    "$(greet | sed -n 2p | grep -c stale)" "0"

new_case
touch -d "$((STALE_AFTER_DAYS * 24 + 1)) hours ago" "$todo_dir/.last-extraction"
assert_equals "extraction just above the threshold is stale" \
    "$(greet | sed -n 2p)" "inbox: 0   last extraction: $STALE_AFTER_DAYS days ago (stale)"

if ((failures > 0)); then
    printf '%d failure(s)\n' "$failures"
    exit 1
fi
printf 'all %d cases passed\n' "$case_number"
