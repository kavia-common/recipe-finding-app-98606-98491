#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
mkdir -p "${WORKSPACE}/logs"
cd "${WORKSPACE}"
LOG="${WORKSPACE}/logs/create_react_app.log"
MARKER="${WORKSPACE}/.scaffold_done"
[ -f package.json ] && { echo "package.json exists; skipping scaffolding" >"${LOG}"; touch "$MARKER"; exit 0; }
# Allow common VCS/docs; consider directory non-empty only if unexpected files exist
if find . -maxdepth 1 -mindepth 1 ! -name '.' ! -name 'logs' ! -name '.git' ! -name 'README.md' ! -name '.scaffold_done' -print -quit | grep -q .; then
  echo "workspace contains unexpected files; aborting scaffolding" >"${LOG}" && exit 10
fi
# Prefer global create-react-app
if command -v create-react-app >/dev/null 2>&1; then
  create-react-app . --use-npm >"${LOG}" 2>&1 || { echo "create-react-app failed; see ${LOG}" >&2; tail -n 200 "${LOG}" >&2 || true; exit 11; }
else
  # npx may need network; try to avoid interactive prompts
  npx --yes create-react-app@latest . --use-npm >"${LOG}" 2>&1 || { echo "npx create-react-app failed; see ${LOG}" >&2; tail -n 200 "${LOG}" >&2 || true; exit 12; }
fi
# Ensure CRA scripts exist; backup package.json before edits
if [ -f package.json ]; then cp -a package.json package.json.bak || true; fi
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));p.scripts=p.scripts||{};p.scripts.start=p.scripts.start||'react-scripts start';p.scripts.build=p.scripts.build||'react-scripts build';p.scripts.test=p.scripts.test||'react-scripts test';fs.writeFileSync('package.json',JSON.stringify(p,null,2));"
# Mark scaffold complete
touch "$MARKER"
