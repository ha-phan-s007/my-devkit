#!/bin/bash
# =============================================================================
# claude-tmux.sh - Launch Claude Code inside tmux for agent team support
# =============================================================================
# Usage:
#   claude-tmux [session-name] [working-directory]
#
# Examples:
#   claude-tmux                     # Default session "claude", current dir
#   claude-tmux my-project          # Named session, current dir
#   claude-tmux my-project ~/code   # Named session, specific dir
# =============================================================================

SESSION_NAME="${1:-claude}"
WORK_DIR="${2:-$(pwd)}"

# Check dependencies
if ! command -v tmux &>/dev/null; then
    echo "Error: tmux is not installed. Install with: brew install tmux"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo "Error: claude CLI is not installed."
    exit 1
fi

# Check if already inside tmux
if [ -n "$TMUX" ]; then
    echo "Already inside tmux session. Launching Claude Code directly..."
    echo "Agent team panes will auto-split in this session."
    cd "$WORK_DIR" && claude
    exit 0
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Attaching to existing tmux session: $SESSION_NAME"
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# Create new tmux session and launch Claude Code
echo "Starting tmux session '$SESSION_NAME' in $WORK_DIR..."
tmux new-session -d -s "$SESSION_NAME" -c "$WORK_DIR"

# Set session-specific options for Claude agent teams
tmux set-option -t "$SESSION_NAME" remain-on-exit off
tmux set-option -t "$SESSION_NAME" mouse on

# Send the claude command to the session
tmux send-keys -t "$SESSION_NAME" "claude" Enter

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
