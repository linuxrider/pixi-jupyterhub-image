#!/bin/bash
set -euo pipefail

IMAGE="${PIXI_HUB_IMAGE:-pixi-jupyterhub}"
ADMIN_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(16))')"
HUB_PORT="$(python3 -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')"
PROXY_API_PORT="$(python3 -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')"
WORK_DIR="$(mktemp -d)"
NETWORK="jhub-test-$$"
HUB_PID=""
_CLEANED=0

cleanup() {
    [ $_CLEANED -eq 1 ] && return; _CLEANED=1
    echo "=== cleanup ==="
    if [ -n "$HUB_PID" ] && kill -0 "$HUB_PID" 2>/dev/null; then
        PGID=$(ps -o pgid= -p "$HUB_PID" 2>/dev/null | tr -d ' ')
        [ -n "$PGID" ] && kill -- -"$PGID" 2>/dev/null || kill "$HUB_PID" 2>/dev/null
        wait "$HUB_PID" 2>/dev/null || true
    fi
    docker ps --filter "label=jhub-network=$NETWORK" -q | xargs -r docker rm -f 2>/dev/null || true
    docker network rm "$NETWORK" 2>/dev/null || true
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

echo "=== Building image: $IMAGE ==="
docker build -t "$IMAGE" -f docker/Dockerfile .

echo "=== Creating Docker network: $NETWORK ==="
docker network create "$NETWORK"
GATEWAY=$(docker network inspect "$NETWORK" --format='{{(index .IPAM.Config 0).Gateway}}')
echo "Gateway: $GATEWAY"

echo "=== Starting JupyterHub on port $HUB_PORT ==="
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
    --db="sqlite:///$WORK_DIR/jhub.db" \
    > "$WORK_DIR/hub.log" 2>&1 &
HUB_PID=$!

echo "=== Waiting for hub ==="
for i in $(seq 1 30); do
    curl -sf "http://localhost:$HUB_PORT/hub/api" \
        -H "Authorization: token $ADMIN_TOKEN" > /dev/null 2>&1 \
        && { echo "Hub ready in ${i}s"; break; }
    kill -0 "$HUB_PID" 2>/dev/null \
        || { echo "Hub died. Log:"; cat "$WORK_DIR/hub.log"; exit 1; }
    sleep 1
    [ "$i" -eq 30 ] && { echo "Hub start timeout. Log:"; cat "$WORK_DIR/hub.log"; exit 1; }
done

echo "=== Creating testuser ==="
curl -sf -X POST "http://localhost:$HUB_PORT/hub/api/users/testuser" \
    -H "Authorization: token $ADMIN_TOKEN" > /dev/null

echo "=== Spawning server ==="
HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "http://localhost:$HUB_PORT/hub/api/users/testuser/server" \
    -H "Authorization: token $ADMIN_TOKEN")
[[ "$HTTP" =~ ^(201|202)$ ]] || { echo "Spawn failed: HTTP $HTTP"; exit 1; }

echo "=== Waiting for server (60s max) ==="
for i in $(seq 1 30); do
    SERVER=$(curl -sf "http://localhost:$HUB_PORT/hub/api/users/testuser" \
        -H "Authorization: token $ADMIN_TOKEN" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('server') or '')" 2>/dev/null)
    [ -n "$SERVER" ] && { echo "Server ready: $SERVER"; break; }
    sleep 2
    [ "$i" -eq 30 ] && { echo "Server start timeout"; exit 1; }
done

echo "=== Verifying server API ==="
curl -sf "http://localhost:$HUB_PORT/user/testuser/api" \
    -H "Authorization: token $ADMIN_TOKEN" > /dev/null
echo "Server API: OK"

echo ""
echo "=== ALL TESTS PASSED ==="
