#!/bin/bash
set -euo pipefail

IMAGE="${PIXI_HUB_IMAGE:-pixi-jupyterhub}"
ADMIN_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(16))')"
WORK_DIR="$(mktemp -d)"
NETWORK="jhub-serve-$$"
HUB_PORT=8000
PROXY_API_PORT="$(python3 -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')"
HUB_PID=""
_CLEANED=0

cleanup() {
    [ $_CLEANED -eq 1 ] && return; _CLEANED=1
    echo ""
    echo "=== cleanup ==="
    if [ -n "$HUB_PID" ] && kill -0 "$HUB_PID" 2>/dev/null; then
        kill "$HUB_PID" 2>/dev/null || true
        pkill -P "$HUB_PID" 2>/dev/null || true
        sleep 1
        kill -9 "$HUB_PID" 2>/dev/null || true
        pkill -9 -P "$HUB_PID" 2>/dev/null || true
        wait "$HUB_PID" 2>/dev/null || true
    fi
    pkill -9 -f 'bin/jupyterhub' 2>/dev/null || true
    pkill -9 -f 'configurable-http-proxy' 2>/dev/null || true
    docker ps --filter "label=jhub-network=$NETWORK" -q | xargs -r docker rm -f 2>/dev/null || true
    docker network rm "$NETWORK" 2>/dev/null || true
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

echo "=== Killing any stray hub processes ==="
pkill -9 -f 'bin/jupyterhub' 2>/dev/null || true
pkill -9 -f 'configurable-http-proxy' 2>/dev/null || true

echo "=== Building image: $IMAGE ==="
docker build -t "$IMAGE" -f docker/Dockerfile .

echo "=== Creating Docker network: $NETWORK ==="
docker network create "$NETWORK"
GATEWAY=$(docker network inspect "$NETWORK" --format='{{(index .IPAM.Config 0).Gateway}}')

echo ""
echo "=== JupyterHub starting on http://localhost:$HUB_PORT ==="
echo "    Login: any username, password: localtest"
echo "    Press Ctrl+C to stop"
echo ""

JHUB_TEST_NETWORK="$NETWORK" \
JHUB_TEST_GATEWAY="$GATEWAY" \
JHUB_TEST_TOKEN="$ADMIN_TOKEN" \
JHUB_TEST_IMAGE="$IMAGE" \
JHUB_WORK_DIR="$WORK_DIR" \
JHUB_PROXY_API_PORT="$PROXY_API_PORT" \
jupyterhub \
    --config="$(pwd)/tests/jupyterhub_test_config.py" \
    --ip=0.0.0.0 \
    --port="$HUB_PORT" \
    --db="sqlite:///$WORK_DIR/jhub.db" &
HUB_PID=$!

# Open browser once hub is ready
(
    for i in $(seq 1 30); do
        curl -sf "http://localhost:$HUB_PORT/hub/login" > /dev/null 2>&1 \
            && { xdg-open "http://localhost:$HUB_PORT" 2>/dev/null; break; }
        sleep 1
    done
) &

wait "$HUB_PID"
