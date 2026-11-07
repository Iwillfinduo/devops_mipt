#!/usr/bin/env sh
set -eu

timeout=${DEPLOYMENT_TIMEOUT:-300}
elapsed=0

while [ "$elapsed" -lt "$timeout" ]; do
    status=$(docker compose ps -q ansible-master | xargs -r docker inspect \
        --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}starting{{end}}')

    case "$status" in
        healthy)
            echo "Ansible deployment completed."
            exit 0
            ;;
        unhealthy)
            docker compose logs --no-color ansible-master
            echo "Ansible deployment failed." >&2
            exit 1
            ;;
    esac

    sleep 3
    elapsed=$((elapsed + 3))
done

docker compose logs --no-color ansible-master
echo "Timed out waiting for Ansible deployment." >&2
exit 1
