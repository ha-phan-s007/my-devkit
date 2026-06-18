#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# install.sh — symlink the personal configs in local/ into their real homes.
#
# Idempotent: re-running is safe. Any pre-existing real file (not already a
# symlink to this repo) is backed up to <file>.bak-<n> before linking.
#
#   ./install.sh            # apply (create symlinks)
#   ./install.sh --dry-run  # show what would happen, change nothing
# ============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1

# "source-relative-to-local/ : destination"
MAP=(
  "claude/settings.json:$HOME/.claude/settings.json"
  "claude/keybindings.json:$HOME/.claude/keybindings.json"
  "claude/statusline-command.sh:$HOME/.claude/statusline-command.sh"
  "shell/.zshrc:$HOME/.zshrc"
  "shell/.bashrc:$HOME/.bashrc"
  "shell/.bash_profile:$HOME/.bash_profile"
  "shell/.zprofile:$HOME/.zprofile"
  "shell/.gitconfig:$HOME/.gitconfig"
  "terminal/.tmux.conf:$HOME/.tmux.conf"
  "terminal/starship.toml:$HOME/.config/starship.toml"
)

link() {
  local src="$DIR/$1" dst="$2"
  [[ -f "$src" ]] || { echo "⚠️  missing source, skip: $1"; return; }
  # Already linked to us? nothing to do.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "✓ ok    $dst"
    return
  fi
  if [[ $DRY -eq 1 ]]; then
    echo "would link $dst → $src"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  # Back up an existing real file/dir (not one of our links).
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    local n=1; while [[ -e "$dst.bak-$n" ]]; do n=$((n+1)); done
    mv "$dst" "$dst.bak-$n"
    echo "↳ backed up existing → $dst.bak-$n"
  fi
  ln -sf "$src" "$dst"
  echo "🔗 link  $dst → $src"
}

echo "Source: $DIR   Mode: $([[ $DRY -eq 1 ]] && echo DRY-RUN || echo APPLY)"
echo "------------------------------------------------------------"
for pair in "${MAP[@]}"; do
  link "${pair%%:*}" "${pair#*:}"
done
echo "------------------------------------------------------------"
echo "Note: aliases 'ss' (launch) / 'ss-cleanup' (teardown) in .zshrc point at"
echo "      $DIR/terminal/. If you cloned the repo elsewhere, fix those paths."
echo "      tmux plugins are managed by tpm (prefix + I to install)."
