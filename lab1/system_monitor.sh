#!/usr/bin/env bash

set -u

DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PID_FILE="$DIR/.system_monitor.pid"
LOCK_FILE="$DIR/.system_monitor.lock"
INTERVAL=600

running() {
    [[ -s "$PID_FILE" ]] || return 1
    local pid
    pid=$(<"$PID_FILE")
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

collect() {
    local timestamp report total free memory cpu disk load
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    report="$DIR/system_report_$(date '+%Y-%m-%d').csv"

    read -r total free < <(awk '
        $1 == "MemTotal:" { total=$2 }
        $1 == "MemAvailable:" { free=$2 }
        END { print total, free }
    ' /proc/meminfo)
    memory=$(awk -v total="$total" -v free="$free" \
        'BEGIN { printf "%.2f", (total - free) * 100 / total }')

    cpu=$(awk '
        NR == 1 { idle1=$5+$6; total1=$2+$3+$4+$5+$6+$7+$8+$9 }
        NR == 2 { idle2=$5+$6; total2=$2+$3+$4+$5+$6+$7+$8+$9
            printf "%.2f", (1-(idle2-idle1)/(total2-total1))*100 }
    ' <(head -1 /proc/stat) <(sleep 1; head -1 /proc/stat))
    disk=$(df -P / | awk 'NR == 2 { sub(/%/, "", $5); print $5 }')
    load=$(awk '{ print $1 }' /proc/loadavg)

    [[ -e "$report" ]] ||
        printf 'timestamp;all_memory;free_memory;%%memory_used;%%cpu_used;%%disk_used;load_average_1m\n' \
        > "$report"
    printf '%s;%s;%s;%s;%s;%s;%s\n' \
        "$timestamp" "$total" "$free" "$memory" "$cpu" "$disk" "$load" >> "$report"
}

monitor() {
    exec 9>"$LOCK_FILE"
    flock -n 9 || exit 1
    printf '%s\n' "$BASHPID" > "$PID_FILE"
    local sleep_pid=
    cleanup() {
        [[ -n "$sleep_pid" ]] && kill "$sleep_pid" 2>/dev/null
        rm -f "$PID_FILE"
    }
    trap cleanup EXIT
    trap 'exit 0' TERM INT

    while :; do
        collect
        sleep "$INTERVAL" &
        sleep_pid=$!
        wait "$sleep_pid"
        sleep_pid=
    done
}

case "${1:-}" in
    START)
        if running; then
            echo "Уже запущен (PID $(<"$PID_FILE"))" >&2
            exit 1
        fi
        rm -f "$PID_FILE"
        monitor >/dev/null 2>&1 &
        for _ in {1..20}; do
            running && { echo "$(<"$PID_FILE")"; exit 0; }
            sleep 0.05
        done
        echo "Не удалось запустить мониторинг" >&2
        exit 1
        ;;
    STATUS)
        if running; then
            echo "запущен (PID $(<"$PID_FILE"))"
        else
            rm -f "$PID_FILE"
            echo "не запущен"
        fi
        ;;
    STOP)
        if ! running; then
            rm -f "$PID_FILE"
            echo "не запущен"
            exit 0
        fi
        pid=$(<"$PID_FILE")
        kill "$pid"
        echo "остановлен (PID $pid)"
        ;;
    *)
        echo "Использование: $0 START|STOP|STATUS" >&2
        exit 2
        ;;
esac
