#!/usr/bin/env bash
set -euo pipefail
# Install and validate frontend deps non-interactively
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
[ -f package.json ] || { echo "error: package.json missing" >&2; exit 2; }
# Prefer deterministic install when package-lock.json exists
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund || { echo "npm ci failed" >&2; exit 3; }
  echo "deps installed via npm ci"
  exit 0
fi
# Otherwise install and create package-lock.json
npm install --no-audit --no-fund || { echo "npm install failed" >&2; exit 4; }
# Ensure react/react-dom exist (check both dependencies and devDependencies)
node -e "try{const p=require('./package.json'); const deps=Object.assign({},p.dependencies||{},p.devDependencies||{}); if(!deps.react) process.exit(2);}catch(e){process.exit(1)}" || {
  npm i --no-audit --no-fund react@^18.2.0 react-dom@^18.2.0 || { echo 'npm install react failed' >&2; exit 5; }
}
# Ensure vitest (dev dependency) is present
node -e "try{const p=require('./package.json'); const d=p.devDependencies||{}; process.exit(d.vitest?0:1);}catch(e){process.exit(1)}" >/dev/null 2>&1 || npm i --no-audit --no-fund -D vitest jsdom @testing-library/react || { echo 'npm install vitest failed' >&2; exit 6; }
# Detect serve-style scripts and install serve as devDependency if needed
HAS_SERVE_SCRIPT=1
node -e "try{const p=require('./package.json'); const s=p.scripts||{}; process.exit((s.serve||s['serve-build'])?0:2);}catch(e){process.exit(1)}" || HAS_SERVE_SCRIPT=2
if [ "$HAS_SERVE_SCRIPT" -eq 1 ]; then
  npm i --no-audit --no-fund -D serve || { echo 'npm install serve failed' >&2; exit 7; }
fi
# Verify test runner availability
if [ -f node_modules/.bin/vitest ] || command -v jest >/dev/null 2>&1; then
  echo "deps ok"
else
  echo "error: no test runner available" >&2; exit 8
fi
