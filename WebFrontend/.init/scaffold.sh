#!/usr/bin/env bash
set -euo pipefail
# Scaffold CRA core template into authoritative workspace (idempotent)
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
mkdir -p "$WORKSPACE"
# If already scaffolded, exit cleanly
if [ -f "$WORKSPACE/package.json" ] && [ -d "$WORKSPACE/src" ]; then
  exit 0
fi
TMPDIR=$(mktemp -d)
LOG="$WORKSPACE/.scaffold.log"
cd "$TMPDIR"
# Prefer installed create-react-app
if command -v create-react-app >/dev/null 2>&1; then
  create-react-app . --use-npm >"$LOG" 2>&1 || { tail -n 200 "$LOG" >&2; rm -rf "$TMPDIR"; exit 7; }
else
  # attempt pinned npx fallback but fail fast if network unavailable
  if curl -sSf --head https://www.npmjs.com/ >/dev/null 2>&1; then
    npx --yes create-react-app@5.0.1 . --use-npm >"$LOG" 2>&1 || { tail -n 200 "$LOG" >&2; rm -rf "$TMPDIR"; exit 8; }
  else
    echo "create-react-app not available and network unreachable for npx fallback" >&2
    rm -rf "$TMPDIR"
    exit 9
  fi
fi
# Validate react-scripts presence using node (avoid jq dependency)
node -e "const p=require('./package.json'); if(!((p.dependencies&&p.dependencies['react-scripts'])||(p.devDependencies&&p.devDependencies['react-scripts']))){console.error('react-scripts missing in generated package.json'); process.exit(1);}"
# Move into workspace, preserve existing files, exclude .git
rsync -a --exclude='.git' --delete ./ "$WORKSPACE/"
rm -rf "$TMPDIR"
cd "$WORKSPACE"
# Initialize git if missing
if [ ! -d .git ]; then
  GIT_NAME=${GIT_COMMITTER_NAME:-"autobot"}
  GIT_EMAIL=${GIT_COMMITTER_EMAIL:-"autobot@example.com"}
  git init >/dev/null 2>&1 || true
  git config user.name "$GIT_NAME" || true
  git config user.email "$GIT_EMAIL" || true
  git add -A >/dev/null 2>&1 || true
  git commit -m "scaffold: initial CRA" >/dev/null 2>&1 || true
fi
