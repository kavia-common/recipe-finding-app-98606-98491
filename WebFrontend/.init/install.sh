#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
if [ ! -f "$WORKSPACE/package.json" ]; then echo "package.json missing; scaffold-002 must run first" >&2; exit 5; fi
LOG=/tmp/webfrontend_install.log; :>"$LOG"
USE_YARN=0
if [ "${YARN:-0}" = "1" ] || [ -f "$WORKSPACE/yarn.lock" ]; then USE_YARN=1; fi
RETRY=0; MAX_RETRY=2; sleep_backoff(){ sleep $((2**$1)); }
if [ "$USE_YARN" -eq 1 ]; then
  until yarn install --frozen-lockfile --silent >"$LOG" 2>&1; do
    RETRY=$((RETRY+1)) || true
    [ "$RETRY" -gt "$MAX_RETRY" ] && { echo "yarn install failed; see $LOG" >&2; sed -n '1,200p' "$LOG" >&2; exit 6; }
    sleep_backoff "$RETRY"
  done
else
  if [ -f "$WORKSPACE/package-lock.json" ]; then
    until npm ci --no-audit --no-fund --silent >"$LOG" 2>&1; do
      RETRY=$((RETRY+1)) || true
      [ "$RETRY" -gt "$MAX_RETRY" ] && { echo "npm ci failed; see $LOG" >&2; sed -n '1,200p' "$LOG" >&2; exit 7; }
      sleep_backoff "$RETRY"
    done
  else
    until npm i --no-audit --no-fund --silent >"$LOG" 2>&1; do
      RETRY=$((RETRY+1)) || true
      [ "$RETRY" -gt "$MAX_RETRY" ] && { echo "npm install failed; see $LOG" >&2; sed -n '1,200p' "$LOG" >&2; exit 8; }
      sleep_backoff "$RETRY"
    done
  fi
fi
# Verify essential deps present after install
node -e "const p=require('./package.json'); const deps=Object.assign({},p.dependencies||{},p.devDependencies||{}); if(!deps['react']||!deps['react-dom']){console.error('missing react/react-dom'); process.exit(2);} if(!deps['react-scripts']&&!deps['vite']){console.error('neither react-scripts nor vite detected'); process.exit(3);}console.log('deps_ok');" >>"$LOG" 2>&1 || { echo "Dependency verification failed; inspect $LOG" >&2; sed -n '1,200p' "$LOG" >&2; exit 9; }
# Ensure testing libraries exist (install if missing)
node -e "const p=require('./package.json'); const deps=Object.assign({},p.devDependencies||{},p.dependencies||{}); if(!deps.jsdom||!deps['@testing-library/react']||!deps['@testing-library/jest-dom']) process.exit(1); process.exit(0);" >/dev/null 2>&1 || {
  if [ "$USE_YARN" -eq 1 ]; then yarn add --dev @testing-library/react @testing-library/jest-dom jsdom --silent >>"$LOG" 2>&1 || { echo "yarn add dev deps failed; see $LOG" >&2; sed -n '1,200p' "$LOG" >&2; exit 10; }; else npm i --no-audit --no-fund --silent --save-dev @testing-library/react @testing-library/jest-dom jsdom >>"$LOG" 2>&1 || { echo "npm add dev deps failed; see $LOG" >&2; sed -n '1,200p' "$LOG" >&2; exit 11; } fi
}
# TypeScript detection and typings
if [ -f "$WORKSPACE/tsconfig.json" ] || node -e "const p=require('./package.json'); if((p.devDependencies&&p.devDependencies.typescript)||(p.dependencies&&p.dependencies.typescript)) process.exit(0); process.exit(1);" >/dev/null 2>&1; then
  node -e "const p=require('./package.json'); const deps=Object.assign({},p.devDependencies||{},p.dependencies||{}); if(!deps['@types/react']||!deps['@types/react-dom']) process.exit(1); process.exit(0);" >/dev/null 2>&1 || {
    if [ "$USE_YARN" -eq 1 ]; then yarn add --dev @types/react @types/react-dom --silent >>"$LOG" 2>&1 || true; else npm i --no-audit --no-fund --silent --save-dev @types/react @types/react-dom >>"$LOG" 2>&1 || true; fi
  }
fi

# Completion message
echo "install step completed (check $LOG for details)"
