#!/usr/bin/env bash
# Fails if files that commonly hold secrets are tracked by git, or if obvious
# key patterns appear in the tree. Used by CI and the pre-commit hook.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

fail=0

# 1) Filenames that should never be committed.
blocked_patterns=(
  "GoogleService-Info.plist"
  "*.p8"
  "*.p12"
  "*.mobileprovision"
  "*.cer"
  "secrets*.json"
  ".env"
)

for pattern in "${blocked_patterns[@]}"; do
  if git ls-files --error-unmatch "$pattern" >/dev/null 2>&1; then
    echo "ERROR: tracked secret-like file matches: $pattern"
    fail=1
  fi
done

# 2) Obvious credential strings in tracked source.
if git grep -nE "(AKIA[0-9A-Z]{16}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)" \
     -- '*.swift' '*.plist' '*.json' '*.yml' 2>/dev/null; then
  echo "ERROR: possible hard-coded credential found above."
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "Secret check failed."
  exit 1
fi

echo "Secret check passed."
