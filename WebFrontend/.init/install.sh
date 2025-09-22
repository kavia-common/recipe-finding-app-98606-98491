#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
[ -f package.json ] || { echo "package.json missing; run scaffold first" >&2; exit 10; }
# Use deterministic install when lockfile present
if [ -f package-lock.json ]; then
  npm ci --no-audit --prefer-offline --silent
else
  npm install --no-audit --prefer-offline --silent
fi
# Add minimal devDependencies only if absent; node prints UPDATED when package.json changed
CHANGED_MARKER=$(node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));p.devDependencies=p.devDependencies||{};let changed=false;const ensure=(k,v)=>{if(!p.devDependencies[k]){p.devDependencies[k]=v;changed=true}};ensure('serve','14.2.0');ensure('eslint','8.0.0');ensure('jest','29.0.0');ensure('browser-image-resizer','0.12.0');if(changed){fs.writeFileSync('package.json',JSON.stringify(p,null,2));console.log('UPDATED')}") || true
if [ "${CHANGED_MARKER}" = "UPDATED" ]; then
  npm install --no-audit --prefer-offline --silent
fi
# Ensure minimal scripts exist (idempotent)
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));p.scripts=p.scripts||{};p.scripts.start=p.scripts.start||'react-scripts start';p.scripts.build=p.scripts.build||'react-scripts build';p.scripts.test=p.scripts.test||'jest --colors';p.scripts['serve:static']=p.scripts['serve:static']||'serve -s build -l \"$PORT\"';fs.writeFileSync('package.json',JSON.stringify(p,null,2));" >/dev/null
# Create dev storage directories (idempotent)
mkdir -p "$WORKSPACE/dev_uploads" "$WORKSPACE/mock_s3"
# Validate required runtime binaries exist locally
if [ ! -x "$WORKSPACE/node_modules/.bin/react-scripts" ]; then
  echo "react-scripts binary missing; re-run npm ci or check package-lock.json" >&2
  exit 11
fi
if [ ! -x "$WORKSPACE/node_modules/.bin/eslint" ] || [ ! -x "$WORKSPACE/node_modules/.bin/jest" ]; then
  echo "eslint or jest not installed locally; they were added to devDependencies and npm install should have installed them" >&2
  exit 12
fi
# Success - print concise confirmation
echo "dependencies installed and dev tools pinned; dev_uploads and mock_s3 ensured"
