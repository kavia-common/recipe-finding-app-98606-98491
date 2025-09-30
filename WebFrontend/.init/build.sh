#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
LOG_DIR=$(mktemp -d /tmp/webfrontend-logs.XXXX)
BUILD_LOG="$LOG_DIR/build.log"
npm run build >"$BUILD_LOG" 2>&1 || { echo "build failed, see $BUILD_LOG" >&2; tail -n 200 "$BUILD_LOG" >&2 || true; exit 2; }
echo "build ok; logs: $BUILD_LOG"
