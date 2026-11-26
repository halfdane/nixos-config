#!/usr/bin/env bash

PRUNE_AFTER_DAYS=7
MAX_SINCE_DAYS=7

fail() {
    echo "otto-mate: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
    otto-mate help
    otto-mate since
    otto-mate add "LINE"
    otto-mate finish
    otto-mate inbox
    otto-mate accept N
    otto-mate reject N
EOF
}

print_since() {
    local earliest modified
    earliest=$(($(date +%s) - MAX_SINCE_DAYS * 86400))
    modified=$(stat -c %Y "$todo_dir/.last-extraction" 2>/dev/null) || modified=$earliest
    (( modified < earliest )) && modified=$earliest
    date -u -d "@$modified" +%Y-%m-%dT%H:%M:%SZ
}

add_candidate() {
    local line=$1 priority= rest date text entry
    (( $# == 1 )) || fail 'usage: otto-mate add "LINE"'
    [[ $line != *$'\n'* ]] || fail "line must be a single line"
    line=${line#"${line%%[![:space:]]*}"}
    line=${line%"${line##*[![:space:]]}"}
    [[ -n $line ]] || fail "line is empty"
    [[ $line != "x "* ]] || fail "line is a done item"
    rest=$line
    if [[ $line =~ ^(\([A-Z]\))([[:space:]]+(.*))?$ ]]; then
        priority="${BASH_REMATCH[1]} "
        rest=${BASH_REMATCH[3]}
    fi
    date=$(date +%F)
    text=$rest
    if [[ $rest =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})([[:space:]]+(.*))?$ ]]; then
        date=${BASH_REMATCH[1]}
        text=${BASH_REMATCH[3]}
    fi
    [[ -n $text ]] || fail "line has no text"
    entry="$priority$date $text"
    local inbox=$todo_dir/inbox.txt
    if [[ -s $inbox && -n $(tail -c1 "$inbox") ]]; then
        echo >> "$inbox" || fail "cannot write $inbox"
    fi
    printf '%s\n' "$entry" >> "$inbox" || fail "cannot write $inbox"
    echo "added: $entry"
}

finish_extraction() {
    local inbox=$todo_dir/inbox.txt cutoff line tmp pruned=0
    cutoff=$(date -d "$PRUNE_AFTER_DAYS days ago" +%F)
    if [[ -f $inbox ]]; then
        tmp=$(mktemp)
        while IFS= read -r line || [[ -n $line ]]; do
            if [[ $line =~ ^(\([A-Z]\)[[:space:]]+)?([0-9]{4}-[0-9]{2}-[0-9]{2})([[:space:]]|$) && ${BASH_REMATCH[2]} < $cutoff ]]; then
                pruned=$((pruned + 1))
            else
                printf '%s\n' "$line" >> "$tmp"
            fi
        done < "$inbox"
        if (( pruned > 0 )); then
            cat "$tmp" > "$inbox" || fail "cannot write $inbox"
        fi
        rm -f "$tmp"
    fi
    touch "$todo_dir/.last-extraction" || fail "cannot touch .last-extraction"
    echo "pruned $pruned inbox lines"
}

print_inbox() {
    local inbox=$todo_dir/inbox.txt
    [[ -f $inbox ]] || return 0
    awk 'NF { print NR, $0 }' "$inbox"
}

require_line_number() {
    [[ ${1:-} =~ ^[1-9][0-9]*$ ]] || fail "usage: otto-mate $2 N"
}

case ${1:-} in
    usage | shorthelp)
        usage
        exit 0
        ;;
esac

shift
subcommand=${1:-}
shift

if [[ $subcommand == help ]]; then
    cat "$(dirname "$0")/otto-mate-guide.md"
    exit 0
fi

todo_dir=${TODO_DIR:?TODO_DIR is not set}

case $subcommand in
    since)
        print_since
        ;;
    add)
        add_candidate "$@"
        ;;
    finish)
        finish_extraction
        ;;
    inbox)
        print_inbox
        ;;
    accept)
        require_line_number "${1:-}" accept
        "${TODO_FULL_SH:?TODO_FULL_SH is not set}" -f move "$1" todo.txt inbox.txt
        ;;
    reject)
        require_line_number "${1:-}" reject
        TODO_FILE=$todo_dir/inbox.txt "${TODO_FULL_SH:?TODO_FULL_SH is not set}" -f del "$1"
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
