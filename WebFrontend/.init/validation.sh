#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
LOG_DIR=$(mktemp -d /tmp/webfrontend-logs.XXXX)
BUILD_LOG="$LOG_DIR/build.log"
# build
npm run build >"$BUILD_LOG" 2>&1 || { echo "build failed, see $BUILD_LOG" >&2; tail -n 200 "$BUILD_LOG" >&2 || true; exit 2; }
# determine candidate ports
PORT=${WEB_FRONTEND_PORT:-}
if [ -z "$PORT" ]; then CAND_PORTS=(5000 5173 3000); else CAND_PORTS=("$PORT"); fi
# choose serve if available
SERVE_CMD=""
if [ -f node_modules/serve/bin/serve.js ]; then SERVE_CMD="node node_modules/serve/bin/serve.js -s build -l"; elif [ -x node_modules/.bin/serve ]; then SERVE_CMD="node node_modules/.bin/serve -s build -l"; fi
# start server under setsid and capture logs
if [ -n "$SERVE_CMD" ]; then P=${WEB_FRONTEND_PORT:-5000}; setsid sh -c "$SERVE_CMD $P" >"$LOG_DIR/serve.out" 2>"$LOG_DIR/serve.err" & PID=$!; sleep 0.3; else setsid npm run start >"$LOG_DIR/dev.out" 2>"$LOG_DIR/dev.err" & PID=$!; sleep 0.8; fi
PGID=$(ps -o pgid= "$PID" | tr -d ' ' || true)
# Keep WEB_FRONTEND_LOG_DIR for stop script
export WEB_FRONTEND_LOG_DIR="$LOG_DIR"
echo "STARTED_PID=$PID" >"$LOG_DIR/pid.info"
echo "STARTED_PGID=${PGID:-}" >>"$LOG_DIR/pid.info"
UP=1
for i in $(seq 1 60); do
  for p in "${CAND_PORTS[@]}"; do
    [ -z "$p" ] && continue
    if curl -sSf "http://127.0.0.1:${p}/" >/dev/null 2>&1; then UP=0; break 2; fi
  done
  sleep 1
done
if [ "$UP" -ne 0 ]; then
  echo "validation failed: server did not respond" >&2; echo "logs: $LOG_DIR" >&2; tail -n 200 "$LOG_DIR"/* 2>/dev/null || true
  [ -n "$PGID" ] && kill -- -"$PGID" 2>/dev/null || true
  [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
  exit 3
fi
echo "validation ok; server responded. logs: $LOG_DIR"
# cleanup
[ -n "$PGID" ] && kill -- -"$PGID" 2>/dev/null || true
[ -n "$PID" ] && kill "$PID" 2>/dev/null || true
