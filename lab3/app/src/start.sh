#!/usr/bin/env sh
set -eu

env_file=${APP_ENV_FILE:-/etc/health-app.env}
if [ -f "$env_file" ]; then
    set -a
    . "$env_file"
    set +a
fi

nohup python3 /opt/health-app/app.py >/var/log/health-app.log 2>&1 &
echo "$!" >/run/health-app.pid
