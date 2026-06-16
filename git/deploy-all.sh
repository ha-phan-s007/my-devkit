#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# deploy-all.sh — roll the standard .githooks out to MANY repos at once.
#
# For each git repo found under BASE_DIR it will:
#   1. copy this toolkit's .githooks/ into the repo (overwriting old copies),
#   2. set core.hooksPath=.githooks for that clone.
#
# It does NOT commit. Review & commit the .githooks/ in each repo yourself so
# the hooks are shared with the whole team.
#
# Usage:
#   ./deploy-all.sh                      # dry-run over ~/workspaces (default)
#   ./deploy-all.sh --apply              # actually deploy under ~/workspaces
#   ./deploy-all.sh --apply /path/base   # deploy under a custom base dir
#   DEPTH=3 ./deploy-all.sh --apply      # search deeper (default maxdepth 2)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/.githooks"
GITIGNORE_TPL="$SCRIPT_DIR/gitignore.common"

# Append any missing lines from the template into the repo's .gitignore.
# Idempotent: never overwrites, only adds lines that aren't already present.
merge_gitignore() {
  local repo="$1" target="$repo/.gitignore" added=0
  [[ -f "$GITIGNORE_TPL" ]] || return 0
  [[ -f "$target" ]] || : > "$target"
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    grep -qxF "$line" "$target" || { printf '%s\n' "$line" >> "$target"; added=1; }
  done < "$GITIGNORE_TPL"
  [[ $added -eq 1 ]] && echo "   ↳ .gitignore updated (missing entries appended)"
  # If .claude/ is already tracked, untrack it (keeps the working copy).
  if git -C "$repo" ls-files --error-unmatch .claude >/dev/null 2>&1; then
    git -C "$repo" rm -r --cached --quiet .claude 2>/dev/null || true
    echo "   ↳ .claude/ untracked (was committed) — commit to finish removing"
  fi
}

APPLY=0
BASE_DIR="$HOME/workspaces"
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    *) BASE_DIR="$arg" ;;
  esac
done
DEPTH="${DEPTH:-2}"

[[ -d "$SRC" ]] || { echo "❌ Source hooks not found: $SRC"; exit 1; }
[[ -d "$BASE_DIR" ]] || { echo "❌ Base dir not found: $BASE_DIR"; exit 1; }

# This toolkit's own repo root — skip it so the devkit never deploys onto itself.
SELF_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")"

echo "Source hooks : $SRC"
echo "Base dir     : $BASE_DIR (maxdepth $DEPTH)"
echo "Mode         : $([[ $APPLY -eq 1 ]] && echo APPLY || echo DRY-RUN)"
echo "------------------------------------------------------------"

count=0
while IFS= read -r gitdir; do
  repo="$(dirname "$gitdir")"
  # Skip this toolkit's own repo.
  [[ -n "$SELF_ROOT" && "$repo" -ef "$SELF_ROOT" ]] && continue
  count=$((count + 1))
  if [[ $APPLY -eq 1 ]]; then
    mkdir -p "$repo/.githooks"
    cp "$SRC"/* "$repo/.githooks/"
    chmod +x "$repo/.githooks/"*
    git -C "$repo" config core.hooksPath .githooks
    echo "✅ $repo"
    merge_gitignore "$repo"
  else
    echo "would deploy → $repo"
  fi
done < <(find "$BASE_DIR" -maxdepth "$DEPTH" -name .git -type d 2>/dev/null | sort)

echo "------------------------------------------------------------"
echo "$count repo(s) $([[ $APPLY -eq 1 ]] && echo processed || echo "would be processed")."
if [[ $APPLY -eq 0 ]]; then
  echo "Re-run with --apply to deploy. Then review & commit .githooks/ in each repo."
fi
