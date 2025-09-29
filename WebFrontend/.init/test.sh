#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/src"
# create minimal app only if missing
if [ ! -f "$WORKSPACE/src/App.js" ] && [ ! -f "$WORKSPACE/src/App.tsx" ]; then
  cat > "$WORKSPACE/src/App.js" <<'EOF'
import React from 'react'
export default function App(){return (<div data-testid="app-root">App</div>)}
EOF
fi
# create test file if none exists or FORCE_TESTS=1
TEST_FILES=$(ls -1 $WORKSPACE/src/*test*.js $WORKSPACE/src/*test*.jsx $WORKSPACE/src/*test*.ts $WORKSPACE/src/*test*.tsx 2>/dev/null || true)
if [ "${FORCE_TESTS:-0}" = "1" ] || [ -z "$TEST_FILES" ]; then
  cat > "$WORKSPACE/src/App.test.js" <<'EOF'
import React from 'react'
import { render, screen } from '@testing-library/react'
import '@testing-library/jest-dom'
import App from './App'

test('renders app root', () => {
  render(<App />)
  expect(screen.getByTestId('app-root')).toHaveTextContent('App')
})
EOF
fi
# Ensure test script exists in package.json
node -e "const f='package.json'; const p=require('./'+f); p.scripts=p.scripts||{}; if(!p.scripts.test) p.scripts.test='react-scripts test --watchAll=false'; require('fs').writeFileSync(f,JSON.stringify(p,null,2));" >/dev/null 2>&1 || true
export CI=1 BROWSER=none
LOG=/tmp/webfrontend_test.log; :>"$LOG"
npm test --silent -- --watchAll=false >"$LOG" 2>&1 || { echo "tests failed; see $LOG" >&2; tail -n 200 "$LOG" >&2; exit 6; }
