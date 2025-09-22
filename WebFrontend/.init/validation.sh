#!/usr/bin/env bash
set -euo pipefail
# Build, serve built bundle, health-check and clean stop (validation step)
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
# Build using local react-scripts
if [ ! -f package.json ]; then echo "package.json missing in workspace: $WORKSPACE" >&2; exit 11; fi
# run build
npm run build --silent || { echo "npm run build failed" >&2; exit 20; }
[ -d build ] || { echo "build directory missing" >&2; exit 21; }
# pick ephemeral port
PORT=$(python3 - <<'PY'
import socket
s=socket.socket()
s.bind(('127.0.0.1',0))
port=s.getsockname()[1]
s.close()
print(port)
PY
)
# ensure local serve binary exists, install locally if absent
if [ -x ./node_modules/.bin/serve ]; then
  SERVE_BIN=./node_modules/.bin/serve
else
  npm install --no-audit --prefer-offline --silent serve@14.2.0 || { echo "npm install serve failed" >&2; exit 22; }
  SERVE_BIN=./node_modules/.bin/serve
fi
# create workspace-scoped temp files
LOG=$(mktemp -p "$WORKSPACE" .serve_log.XXXX)
RESP=$(mktemp -p "$WORKSPACE" .resp.XXXX)
HEADER=$(mktemp -p "$WORKSPACE" .hdr.XXXX)
SERVER_PID=0
cleanup(){
  if [ "$SERVER_PID" -ne 0 ] 2>/dev/null; then kill "$SERVER_PID" >/dev/null 2>&1 || true; fi
  rm -f "$LOG" "$RESP" "$HEADER" 2>/dev/null || true
}
trap cleanup EXIT INT TERM
# start server
( "$SERVE_BIN" -s build -l "$PORT" >"$LOG" 2>&1 ) &
SERVER_PID=$!
# wait for 2xx/3xx with exponential backoff
RETRIES=0
MAX_RETRIES=7
while true; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/" 2>/dev/null || echo 000)
  if [ "$STATUS" != "000" ] && [ "$STATUS" -ge 200 ] && [ "$STATUS" -lt 400 ]; then break; fi
  if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then echo "server failed to return 2xx/3xx; see $LOG" >&2; tail -n 200 "$LOG" >&2; exit 23; fi
  SLEEP_SEC=$(( RETRIES<5 ? (1<<RETRIES) : 32 ))
  sleep "$SLEEP_SEC"
  RETRIES=$((RETRIES+1))
done
# fetch response and headers
curl -sS -D "$HEADER" -o "$RESP" "http://127.0.0.1:$PORT/"
CT=$(tr -d '\r' <"$HEADER" | grep -i '^Content-Type:' || true)
if ! echo "$CT" | grep -qi 'html' && ! grep -qi '<html' "$RESP" >/dev/null 2>&1; then
  echo "validation: served content not HTML" >&2
  cat "$RESP" >&2
  exit 24
fi
# evidence
echo "build_size_bytes: $(du -sb build | cut -f1)"
echo "serve_log_tail:"
tail -n 50 "$LOG" || true
# cleanup handled by trap
