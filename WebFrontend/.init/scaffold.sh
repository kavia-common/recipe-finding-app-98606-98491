#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
TS_FLAG=0
[ -f "$WORKSPACE/USE_TYPESCRIPT" ] && TS_FLAG=1
# If package.json exists and has react, skip
if [ -f package.json ]; then
  if node -e "try{const p=require('./package.json'); const deps=Object.assign({},p.dependencies||{},p.devDependencies||{}); if(deps.react) process.exit(0);}catch(e){} process.exit(1)" >/dev/null 2>&1; then
    echo "found existing React project, skipping scaffold"; exit 0
  fi
fi
# If non-empty and not explicitly allowed, fail fast to avoid accidental overwrite
if [ "$(ls -A . | wc -l)" -gt 0 ] && [ ! -f "$WORKSPACE/.allow_inplace_scaffold" ]; then
  echo "error: workspace non-empty and not a React project. To permit deterministic in-place Vite scaffold, create $WORKSPACE/.allow_inplace_scaffold" >&2
  exit 5
fi
# If directory empty and create-react-app is available, use it non-interactively
if [ "$(ls -A . | wc -l)" -eq 0 ] && command -v create-react-app >/dev/null 2>&1; then
  if [ "$TS_FLAG" -eq 1 ]; then
    create-react-app . --template typescript --use-npm
  else
    create-react-app . --use-npm
  fi
  echo "scaffolded with CRA"
  exit 0
fi
# Vite in-place scaffold (deterministic, pins minimal versions and produces package-lock.json)
REACT_VER="^18.2.0"
VITE_VER="^5.0.0"
PLUGIN_REACT_VER="^4.0.0"
VITEST_VER="^1.0.0"
mkdir -p src public
# Create package.json
cat > package.json <<JSON
{
  "name": "webfrontend",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "start": "vite",
    "build": "vite build",
    "test": "vitest"
  }
}
JSON
# Install runtime + dev deps and produce package-lock.json
if [ "$TS_FLAG" -eq 1 ]; then
  npm i --no-audit --no-fund react@"${REACT_VER}" react-dom@"${REACT_VER}" >/dev/null
  npm i --no-audit --no-fund -D vite@"${VITE_VER}" @vitejs/plugin-react@"${PLUGIN_REACT_VER}" typescript >/dev/null
else
  npm i --no-audit --no-fund react@"${REACT_VER}" react-dom@"${REACT_VER}" >/dev/null
  npm i --no-audit --no-fund -D vite@"${VITE_VER}" @vitejs/plugin-react@"${PLUGIN_REACT_VER}" >/dev/null
fi
# Ensure vitest dev deps for tests
npm i --no-audit --no-fund -D vitest@"${VITEST_VER}" jsdom @testing-library/react >/dev/null
# Create source files
if [ "$TS_FLAG" -eq 1 ]; then
  cat > src/main.tsx <<'TS'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
const root = document.getElementById('root')
if (root) createRoot(root).render(<App />)
TS
  cat > src/App.tsx <<'TS'
export default function App(){return <div>Hello</div>}
TS
else
  cat > src/main.jsx <<'JS'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
const root = document.getElementById('root')
if (root) createRoot(root).render(<App />)
JS
  cat > src/App.jsx <<'JS'
export default function App(){return <div>Hello</div>}
JS
fi
# index.html uses relative path (no leading slash)
if [ "$TS_FLAG" -eq 1 ]; then ENTRY="src/main.tsx"; else ENTRY="src/main.jsx"; fi
cat > index.html <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>WebFrontend</title>
</head>
<body>
<div id="root"></div>
<script type="module" src="${ENTRY}"></script>
</body>
</html>
HTML
# vite.config.js tuned for container (host 0.0.0.0)
cat > vite.config.js <<'JS'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({plugins:[react()], server:{host:'0.0.0.0', port:5173}})
JS
# tsconfig.json if TS
if [ "$TS_FLAG" -eq 1 ]; then
  cat > tsconfig.json <<JSON
{
  "compilerOptions": {
    "target": "ES2019",
    "module": "ESNext",
    "jsx": "react-jsx",
    "strict": false,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
JSON
fi
# Final verification
node -e "const f=require('fs'); const p=JSON.parse(f.readFileSync('package.json')); if(!(p.scripts&& (p.scripts.start||p.scripts.build))) process.exit(1)" || { echo "scaffold failed to produce start/build scripts" >&2; exit 6; }
echo "scaffold ready"
