#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
# If repo already has obvious app files, do not scaffold
if [ -d src ] || [ -d public ] || [ -f index.html ] || ( [ -f package.json ] && node -e "const p=require('./package.json'); process.exit(p.scripts&&Object.keys(p.scripts).length?0:1)" >/dev/null 2>&1 ); then
  exit 0
fi
mkdir -p .scaffold_backup || true
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
stash_fail(){ tar -czf ".scaffold_backup/partial_$TIMESTAMP.tar.gz" . --exclude .scaffold_backup || true; }
SCAFFOLD_TYPE=""
LOG=/tmp/webfrontend_scaffold.log
# Try local CRA
if command -v create-react-app >/dev/null 2>&1; then
  if create-react-app . --use-npm --no-analytics --silent >"$LOG" 2>&1; then SCAFFOLD_TYPE="cra"; fi
fi
# Fallback to npx --yes create-react-app
if [ -z "$SCAFFOLD_TYPE" ] && command -v npx >/dev/null 2>&1; then
  if npx --yes create-react-app . --use-npm --no-analytics --silent >"$LOG" 2>&1; then SCAFFOLD_TYPE="cra"; fi
fi
# Vite fallback: prefer npm create if available
if [ -z "$SCAFFOLD_TYPE" ]; then
  if command -v npm >/dev/null 2>&1 && npm create vite@latest . -- --template react --yes >"$LOG" 2>&1; then SCAFFOLD_TYPE="vite"; fi
  if [ -z "$SCAFFOLD_TYPE" ]; then
    if command -v npm >/dev/null 2>&1 && npm init vite@latest . -- --template react --yes >"$LOG" 2>&1; then SCAFFOLD_TYPE="vite"; fi
  fi
fi
if [ -z "$SCAFFOLD_TYPE" ]; then
  stash_fail || true
  echo "ERROR: scaffolding failed; see $LOG" >&2
  exit 6
fi
# Create minimal Upload component
mkdir -p src/components || true
cat > src/components/Upload.jsx <<'COMP'
import React from 'react';
export default function Upload(){
  return (<input type="file" accept="image/*" data-testid="file-input"/>);
}
COMP
# Small README
cat > README.md <<MD
# WebFrontend
Scaffold: ${SCAFFOLD_TYPE}
Headless: use HOST=0.0.0.0 PORT and NODE_ENV environment variables. Start with: npm start (CRA) or npm run dev (Vite).
MD

# Success
exit 0
