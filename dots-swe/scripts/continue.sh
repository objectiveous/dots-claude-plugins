#!/bin/bash
# Continue work on an existing bead - reattach to session

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  TERMINAL=$(get_swe_terminal)

  echo "Usage: /dots-swe:continue [bead-id]"
  echo ""
  echo "Continue work on an existing bead by reattaching to its session."
  echo ""
  echo "Without arguments, lists available sessions to continue."
  echo "With a bead ID, opens that session."
  echo ""
  echo "Current terminal: $TERMINAL"
  if [ "$TERMINAL" = "ghostty" ]; then
    echo "  Sessions managed by: zmx"
    echo "  Detach: ctrl+\\"
  else
    echo "  Sessions managed by: tmux"
  fi
  echo ""
  echo "Examples:"
  echo "  /dots-swe:continue              # List available sessions"
  echo "  /dots-swe:continue dots-abc     # Continue work on dots-abc"
  echo ""
  echo "See also:"
  echo "  /dots-swe:start <bead-id>   # Start new work"
  echo "  /dots-swe:finish <bead-id>  # Finish and cleanup"
  exit 0
fi

BEAD_ID="$1"
TERMINAL=$(get_swe_terminal)
WORKTREES_DIR=$(get_worktrees_dir)

# If no bead specified, list available sessions
if [ -z "$BEAD_ID" ]; then
  echo "📋 Available sessions to continue:"
  echo ""

  FOUND=0

  if [ "$TERMINAL" = "ghostty" ]; then
    # List zmx sessions (format: session_name=xxx\tpid=xxx\tclients=xxx)
    SESSIONS=$(zmx list 2>/dev/null | cut -f1 | cut -d= -f2)
    if [ -n "$SESSIONS" ]; then
      while IFS= read -r session; do
        [ -z "$session" ] && continue
        FOUND=$((FOUND + 1))

        # Check if there's a worktree for this session
        WORKTREE_PATH="$WORKTREES_DIR/$session"
        if [ -d "$WORKTREE_PATH" ]; then
          # Get bead info if available
          if [ -f "$WORKTREE_PATH/.swe-bead" ]; then
            BEAD=$(cat "$WORKTREE_PATH/.swe-bead")
            TITLE=$(bd show "$BEAD" 2>/dev/null | head -2 | tail -1 | sed 's/^[[:space:]]*//')
            echo "  • $session"
            [ -n "$TITLE" ] && echo "    $TITLE"
          else
            echo "  • $session"
          fi
        else
          echo "  • $session (no worktree)"
        fi
      done <<< "$SESSIONS"
    fi
  else
    # List tmux sessions
    SESSIONS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
    if [ -n "$SESSIONS" ]; then
      while IFS= read -r session; do
        [ -z "$session" ] && continue
        FOUND=$((FOUND + 1))
        echo "  • $session"
      done <<< "$SESSIONS"
    fi
  fi

  if [ $FOUND -eq 0 ]; then
    echo "  (no active sessions)"
    echo ""
    echo "Start new work with: /dots-swe:start <bead-id>"
  else
    echo ""
    echo "Continue with: /dots-swe:continue <session-name>"
  fi
  exit 0
fi

# Continue specific session
WORKTREE_PATH="$WORKTREES_DIR/$BEAD_ID"

echo "🔄 Continuing work on: $BEAD_ID"
echo ""

if [ "$TERMINAL" = "ghostty" ]; then
  # Check if zmx session exists
  if zmx_session_exists "$BEAD_ID"; then
    echo "Reattaching to zmx session..."
    open_ghostty_zmx_session "$WORKTREE_PATH" "$BEAD_ID"
    echo "✅ Session opened"
  else
    # No session, but maybe worktree exists
    if [ -d "$WORKTREE_PATH" ]; then
      echo "Session not running, but worktree exists."
      echo "Starting new session..."
      open_ghostty_zmx_session "$WORKTREE_PATH" "$BEAD_ID"
      echo "✅ Session opened"
    else
      echo "❌ No session or worktree found for: $BEAD_ID"
      echo ""
      echo "Start new work with: /dots-swe:start $BEAD_ID"
      exit 1
    fi
  fi
else
  # tmux/iTerm
  if tmux_session_exists "$BEAD_ID"; then
    echo "Reattaching to tmux session..."
    attach_iterm_to_tmux "$BEAD_ID"
    echo "✅ Session opened"
  else
    if [ -d "$WORKTREE_PATH" ]; then
      echo "Session not running, but worktree exists."
      echo "Starting new session..."
      open_worktree_session "$WORKTREE_PATH" "$BEAD_ID"
      echo "✅ Session opened"
    else
      echo "❌ No session or worktree found for: $BEAD_ID"
      echo ""
      echo "Start new work with: /dots-swe:start $BEAD_ID"
      exit 1
    fi
  fi
fi
