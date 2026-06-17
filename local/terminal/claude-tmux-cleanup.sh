#!/bin/bash
# =============================================================================
# claude-tmux-cleanup.sh - Tear down Claude Code tmux sessions
# =============================================================================
# Usage:
#   claude-tmux-cleanup                # kill the default "claude" session
#   claude-tmux-cleanup my-project     # kill a named session
#   claude-tmux-cleanup --all          # kill EVERY tmux session (asks first)
#   claude-tmux-cleanup --list         # just list current sessions
# =============================================================================

if ! command -v tmux &>/dev/null; then
    echo "Error: tmux is not installed."
    exit 1
fi

if ! tmux info &>/dev/null; then
    echo "No tmux server running — nothing to clean up."
    exit 0
fi

case "${1:-}" in
    --list)
        echo "Current tmux sessions:"
        tmux list-sessions
        exit 0
        ;;
    --all)
        echo "Sessions to be killed:"
        tmux list-sessions -F '  - #S'
        printf "Kill ALL tmux sessions? [y/N] "
        read -r reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            tmux kill-server
            echo "✅ All tmux sessions killed."
        else
            echo "Aborted."
        fi
        exit 0
        ;;
esac

SESSION_NAME="${1:-claude}"

if [ -n "$TMUX" ] && [ "$(tmux display-message -p '#S')" = "$SESSION_NAME" ]; then
    echo "Error: you are inside '$SESSION_NAME'. Detach first (prefix + d), then re-run."
    exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux kill-session -t "$SESSION_NAME"
    echo "✅ Killed tmux session: $SESSION_NAME"
else
    echo "No tmux session named '$SESSION_NAME'. Use --list to see what's running."
    exit 1
fi
