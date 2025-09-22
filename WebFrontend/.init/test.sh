#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98491/WebFrontend"
cd "$WORKSPACE"
# Minimal ESLint config (idempotent)
if [ ! -f .eslintrc.json ]; then
  cat >.eslintrc.json <<'EOF'
{ "env": { "browser": true, "es2021": true }, "extends": "eslint:recommended", "parserOptions": { "ecmaVersion": 12, "sourceType": "module" }, "rules": {} }
EOF
fi
# Ensure smoke test (idempotent)
mkdir -p src/__tests__
cat > src/__tests__/smoke.test.js <<'EOF'
test('smoke: true is true', ()=>{ expect(true).toBe(true); });
EOF
ESLINT_BIN="./node_modules/.bin/eslint"
JEST_BIN="./node_modules/.bin/jest"
# If local bins missing, attempt one safe non-interactive install if network reachable
if [ ! -x "$ESLINT_BIN" ] || [ ! -x "$JEST_BIN" ]; then
  if curl -sSf --head https://registry.npmjs.org/ >/dev/null 2>&1; then
    npm install --no-audit --prefer-offline --silent
  else
    echo "local eslint/jest missing and network unavailable. Run deps-01 (install) step or provide offline node_modules tarball." >&2
    exit 14
  fi
fi
# Run lint and tests with local binaries
if [ -x "$ESLINT_BIN" ]; then
  "$ESLINT_BIN" src --max-warnings=0 || { echo 'eslint failed' >&2; exit 13; }
else
  echo 'local eslint missing after install attempt' >&2; exit 14
fi
if [ -x "$JEST_BIN" ]; then
  "$JEST_BIN" --colors --runInBand --ci || { echo 'jest failed' >&2; exit 15; }
else
  echo 'local jest missing after install attempt' >&2; exit 16
fi
