#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${ROOT}/MixStack.xcodeproj"
SIM_IPHONE="${SIM_IPHONE:-iPhone 17}"
SIM_IPAD="${SIM_IPAD:-iPad (A16)}"
MCP="${MCP:-npx -y xcodebuildmcp@latest}"

cd "${ROOT}"
xcodegen generate

echo "::group::SwiftLint"
swiftlint --strict
echo "::endgroup::"

run_test() {
  local scheme="$1"
  local sim="$2"
  echo "::group::${scheme} (${sim})"
  ${MCP} simulator test \
    --project-path "${PROJECT}" \
    --scheme "${scheme}" \
    --simulator-name "${sim}" \
    --style minimal
  echo "::endgroup::"
}

run_test MixStackCI "${SIM_IPHONE}"
run_test MixStackUISmoke "${SIM_IPHONE}"
run_test MixStackUILandscape "${SIM_IPHONE}"
run_test MixStackUIAccessibility "${SIM_IPHONE}"
run_test MixStackUIPad "${SIM_IPAD}"

echo "✅ All verification gates passed."
