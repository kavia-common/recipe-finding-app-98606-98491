#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
# If project already scaffolded, nothing to do
[ -f "$WORKSPACE/package.json" ] && exit 0

export CI=1 BROWSER=none
CREATE_TOOL=${CREATE_TOOL:-cra}
YARN_PREF=0
[ "${YARN:-0}" = "1" ] && YARN_PREF=1
[ -f "$WORKSPACE/yarn.lock" ] && YARN_PREF=1

RETRY=0
MAX_RETRY=2
sleep_backoff(){ sleep $((2**$1)); }
LOG=/tmp/webfrontend_scaffold.log
: > "$LOG"

if [ "$CREATE_TOOL" = "vite" ]; then
  # prefer npm exec (modern) but allow npx fallback
  until (command -v npm >/dev/null 2>&1 && npm exec --yes create-vite@latest -- . -- --template react >/tmp/webfrontend_scaffold.log 2>&1) || (command -v npx >/dev/null 2>&1 && npx --yes create-vite@latest . -- --template react >/tmp/webfrontend_scaffold.log 2>&1); do
    RETRY=$((RETRY+1)) || true
    if [ "$RETRY" -gt "$MAX_RETRY" ]; then
      echo "vite scaffold failed; see $LOG" >&2
      sed -n '1,200p' "$LOG" >&2 || true
      exit 4
    fi
    sleep_backoff "$RETRY"
  done
else
  CRA_VER=${CREATE_REACT_APP_VERSION:-latest}
  # prefer yarn when requested; but we use --use-npm to force npm if needed per original script
  # use npx if available otherwise npm exec
  until (command -v npx >/dev/null 2>&1 && npx --yes create-react-app@${CRA_VER} . --use-npm --skip-install >/tmp/webfrontend_scaffold.log 2>&1) || (command -v npm >/dev/null 2>&1 && npm exec --yes create-react-app@${CRA_VER} -- . --use-npm --skip-install >/tmp/webfrontend_scaffold.log 2>&1); do
    RETRY=$((RETRY+1)) || true
    if [ "$RETRY" -gt "$MAX_RETRY" ]; then
      echo "create-react-app scaffold failed; see $LOG" >&2
      sed -n '1,200p' "$LOG" >&2 || true
      exit 5
    fi
    sleep_backoff "$RETRY"
  done
fi

# Verify package.json was created
if [ ! -f "$WORKSPACE/package.json" ]; then
  echo "scaffold failed: package.json missing" >&2
  sed -n '1,200p' "$LOG" >&2 || true
  exit 6
fi

# Create minimal .env if not present
if [ ! -f "$WORKSPACE/.env" ]; then
  cat > "$WORKSPACE/.env" <<EOF
# Example environment variables
REACT_APP_API_URL=http://localhost:3001
EOF
fi

# Record which tool was used
echo "SCAFFOLD_TOOL=$CREATE_TOOL" > /tmp/webfrontend_scaffold_tool.txt
# Minimal success output
echo "scaffold: OK (tool=$CREATE_TOOL)"
