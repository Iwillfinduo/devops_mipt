#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Использование: $0 <URL репозитория> <ветка 1> <ветка 2>" >&2
    exit 1
fi

repo=$1
branch1=$2
branch2=$3

report="$PWD/diff_report_${branch1//\//_}_vs_${branch2//\//_}.txt"

tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

git init -q "$tmp_dir"
git -C "$tmp_dir" remote add origin "$repo"

git -C "$tmp_dir" fetch -q --depth=1 --no-tags origin \
    "refs/heads/$branch1:refs/compare/branch1" \
    "refs/heads/$branch2:refs/compare/branch2"

git -C "$tmp_dir" diff --no-renames --name-status -z \
    refs/compare/branch1 refs/compare/branch2 -- > "$tmp_dir/changes"

total=0
added=0
deleted=0
modified=0

{
    printf 'Отчет о различиях между ветками\n\n'
    printf '================================\n'
    printf 'Репозиторий:     %s\n' "$repo"
    printf 'Ветка 1:        %s\n' "$branch1"
    printf 'Ветка 2:        %s\n' "$branch2"
    printf 'Дата генерации: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '================================\n\n'
    printf 'СПИСОК ИЗМЕНЕННЫХ ФАЙЛОВ:\n'

    while IFS= read -r -d '' status; do
        IFS= read -r -d '' file

        printf '%s\t%s\n' "$status" "$file"
        total=$((total + 1))

        case "$status" in
            A) added=$((added + 1)) ;;
            D) deleted=$((deleted + 1)) ;;
            M) modified=$((modified + 1)) ;;
        esac
    done < "$tmp_dir/changes"

    if [[ "$total" -eq 0 ]]; then
        printf 'Различий нет.\n'
    fi

    printf '\nСТАТИСТИКА:\n'
    printf 'Всего измененных файлов: %d\n' "$total"
    printf 'Добавлено (A): %d\n' "$added"
    printf 'Удалено (D):   %d\n' "$deleted"
    printf 'Изменено (M):  %d\n' "$modified"
} > "$report"

printf 'Отчет сформирован: %s\n' "$report"