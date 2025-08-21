#!/bin/bash

set -e

# Wrapper for docker compose to support both 'docker compose' and 'docker-compose'

if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
else
    echo "Docker Compose is not installed. Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

exec $COMPOSE "$@"

