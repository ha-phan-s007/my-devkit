#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# install-hooks.sh — activate the repo's committed .githooks for THIS clone.
#
# Members run this once after cloning. It points git at the version-controlled
# .githooks/ directory (instead of the local, unshared .git/hooks/).
#
# Usage:
#   ./install-hooks.sh            # activate in the current repo
#   ./install-hooks.sh /path/repo # activate in another repo
# ============================================================================

TARGET="${1:-$(pwd)}"

if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not a git repository: $TARGET"
  exit 1
fi
ROOT=$(git -C "$TARGET" rev-parse --show-toplevel)

if [[ ! -d "$ROOT/.githooks" ]]; then
  echo "❌ No .githooks/ directory in $ROOT — copy the hooks in first."
  exit 1
fi

chmod +x "$ROOT/.githooks/"* 2>/dev/null || true
git -C "$ROOT" config core.hooksPath .githooks

echo "✅ Hooks activated for $ROOT"
echo "   core.hooksPath = $(git -C "$ROOT" config --get core.hooksPath)"
echo "   Active hooks: $(ls "$ROOT/.githooks" | tr '\n' ' ')"
