#!/usr/bin/env bash

set -u

if [[ $# -ne 2 ]]; then
    echo "Использование: $0 <лог-файл> <ключевое слово>" >&2
    exit 2
fi

log_file=$1
keyword=$2
result_file="${log_file}.matches"

if [[ ! -f "$log_file" ]]; then
    echo "Ошибка: файл не найден: $log_file" >&2
    exit 1
fi

if [[ -z "$keyword" ]]; then
    echo "Ошибка: ключевое слово не может быть пустым" >&2
    exit 2
fi

: > "$result_file"
count=$(awk -v keyword="$keyword" -v output="$result_file" '
    index($0, keyword) {
        print > output
        found++
    }
    END {
        close(output)
        print found + 0
    }
' "$log_file")

echo "Найдено строк: $count"
echo "Результат сохранён в: $result_file"
