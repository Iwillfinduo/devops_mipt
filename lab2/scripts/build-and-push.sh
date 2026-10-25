#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
IMAGE_NAME=${IMAGE_NAME:-}
IMAGE_TAG=${IMAGE_TAG:-$(git -C "$SCRIPT_DIR/../.." rev-parse --short HEAD 2>/dev/null || printf 'dev')}

if [ -z "$IMAGE_NAME" ]; then
    printf 'Usage: IMAGE_NAME=registry-user/health-service [IMAGE_TAG=1.0.0] %s\n' "$0" >&2
    exit 1
fi

IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

printf 'Building %s\n' "$IMAGE"
docker build --pull -t "$IMAGE" "$SCRIPT_DIR/.."
docker push "$IMAGE"
printf 'Published %s\n' "$IMAGE"
