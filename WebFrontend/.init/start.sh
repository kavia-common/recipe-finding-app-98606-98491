#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
LOG_DIR=$(mktemp -d /tmp/webfrontend-logs.XXXX)
export WEB_FRONTEND_LOG_DIR="$LOG_DIR"
PORT=${WEB_FRONTEND_PORT:-}
if [ -z "$PORT" ]; then CAND_PORTS=(5000 5173 3000); else CAND_PORTS=("$PORT"); fi
SERVE_CMD=""
if [ -f node_modules/serve/bin/serve.js ]; then SERVE_CMD="node node_modules/serve/bin/serve.js -s build -l"; elif [ -x node_modules/.bin/serve ]; then SERVE_CMD="node node_modules/.bin/serve -s build -l"; fi
if [ -n "$SERVE_CMD" ]; then P=${WEB_FRONTEND_PORT:-5000}; setsid sh -c "$SERVE_CMD $P" >"$LOG_DIR/serve.out" 2>"$LOG_DIR/serve.err" & PID=$!; sleep 0.3; else setsid npm run start >"$LOG_DIR/dev.out" 2>"$LOG_DIR/dev.err" & PID=$!; sleep 0.8; fi
PGID=$(ps -o pgid= "$PID" | tr -d ' ' || true)
echo "STARTED_PID=$PID" >"$LOG_DIR/pid.info"
echo "STARTED_PGID=${PGID:-}" >>"$LOG_DIR/pid.info"
echo "$LOG_DIR"
