#!/usr/bin/env bash
# Installs the repo's git hooks. Run once after cloning:
#   bash Scripts/install-hooks.sh
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
hook=".git/hooks/pre-commit"

cat > "$hook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
bash Scripts/check-secrets.sh
EOF

chmod +x "$hook"
echo "Installed pre-commit hook (secret scan)."
