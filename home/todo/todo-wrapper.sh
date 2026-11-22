#!/usr/bin/env bash

if (( $# == 0 )); then
    echo "For agents extracting todos from Microsoft 365: todo otto-mate help"
    echo "All commands: todo -h"
    set -- ls
fi

exec todo.sh "$@"
