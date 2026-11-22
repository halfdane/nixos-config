#!/usr/bin/env bash

STALE_AFTER_DAYS=3
TOP_ITEM_COUNT=3
READ_TIMEOUT_SECONDS=1

todo_dir=${1:?usage: greeting.sh TODO_DIR}
no_due_sort_key=9999-99-99
no_priority_sort_key='~'
now=$(date +%s)

read_todo_file() {
    timeout "$READ_TIMEOUT_SECONDS" cat "$todo_dir/$1" 2>/dev/null || true
}

top_items() {
    local line due priority rest word display sequence=0
    local -a words kept
    while IFS= read -r line; do
        [[ -z ${line//[[:space:]]/} || $line == "x "* ]] && continue
        due=$no_due_sort_key
        if [[ $line =~ (^|[[:space:]])due:([0-9]{4}-[0-9]{2}-[0-9]{2})([[:space:]]|$) ]]; then
            due=${BASH_REMATCH[2]}
        fi
        priority=$no_priority_sort_key
        rest=$line
        display=
        if [[ $rest =~ ^\(([A-Z])\)[[:space:]]+(.*)$ ]]; then
            priority=${BASH_REMATCH[1]}
            display="($priority) "
            rest=${BASH_REMATCH[2]}
        fi
        if [[ $rest =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+(.*)$ ]]; then
            rest=${BASH_REMATCH[1]}
        fi
        read -ra words <<< "$rest"
        kept=()
        for word in "${words[@]}"; do
            [[ $word == +* || $word == url:* || $word == due:* ]] || kept+=("$word")
        done
        display+="${kept[*]}"
        [[ $due == "$no_due_sort_key" ]] || display+="  due ${due:8:2}.${due:5:2}."
        sequence=$((sequence + 1))
        printf '%s\t%s\t%06d\t%s\n' "$due" "$priority" "$sequence" "$display"
    done | LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3n | head -n "$TOP_ITEM_COUNT" | cut -f4
}

describe_last_extraction() {
    local modified age_seconds days
    if ! modified=$(timeout "$READ_TIMEOUT_SECONDS" stat -c %Y "$todo_dir/.last-extraction" 2>/dev/null); then
        echo never
        return
    fi
    age_seconds=$((now - modified))
    days=$((age_seconds / 86400))
    case $days in
        0) echo -n "today" ;;
        1) echo -n "1 day ago" ;;
        *) echo -n "$days days ago" ;;
    esac
    if (( age_seconds > STALE_AFTER_DAYS * 86400 )); then
        echo -n " (stale)"
    fi
    echo
}

if ! timeout "$READ_TIMEOUT_SECONDS" test -d "$todo_dir"; then
    echo "todo share not mounted"
    exit 0
fi

mapfile -t top < <(read_todo_file todo.txt | top_items)
if (( ${#top[@]} == 0 )); then
    todo_line="nothing open"
else
    printf -v todo_line '%s | ' "${top[@]}"
    todo_line=${todo_line% | }
fi

inbox_count=$(read_todo_file inbox.txt | grep -c '[^[:space:]]')

echo "todo: $todo_line"
echo "inbox: ${inbox_count}   last extraction: $(describe_last_extraction)"
