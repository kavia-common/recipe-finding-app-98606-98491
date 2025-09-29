#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
mkdir -p src/__tests__ || true
cat > src/__tests__/smoke.test.js <<'TEST'
test('smoke-basic', ()=>{ expect(2+2).toBe(4); });
TEST
export CI=1
if npm test --silent -- --runInBand --watchAll=false; then
  exit 0
else
  if command -v npx >/dev/null 2>&1; then
    npx --yes jest --runInBand --watchAll=false || (echo "ERROR: jest tests failed" >&2 && exit 3)
  else
    echo "ERROR: No way to run project-local jest (npx missing)" >&2 && exit 4
  fi
fi
