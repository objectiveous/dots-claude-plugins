---
allowed-tools: Bash(tmux:*), Bash(osascript:*), Bash(source:*)
description: Re-attach iTerm2 to existing tmux sessions
---

# Re-attach to Worktree Sessions

Re-attaches iTerm2 to existing tmux sessions after restart.

**Usage:** `/dots-swe:worktree-attach [session-name]`

**Examples:**
```bash
/dots-swe:worktree-attach              # List available sessions
/dots-swe:worktree-attach yap-tsd      # Attach to specific session
```

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/swe-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:worktree-attach [session-name]"
  echo ""
  echo "Re-attach iTerm2 to existing tmux sessions."
  echo ""
  echo "Without arguments, lists available tmux sessions."
  echo "With a session name, attaches iTerm2 to that session."
  echo ""
  echo "Examples:"
  echo "  /dots-swe:worktree-attach              # List sessions"
  echo "  /dots-swe:worktree-attach yap-tsd      # Attach to yap-tsd"
  exit 0
fi

# List or attach
!if [ -n "$1" ]; then
  SESSION="$1"
  if tmux_session_exists "$SESSION"; then
    echo "Attaching iTerm2 to tmux session: $SESSION"
    attach_iterm_to_tmux "$SESSION"
    echo ""
    echo "Session windows:"
    tmux list-windows -t "$SESSION" 2>/dev/null
  else
    echo "ERROR: Session '$SESSION' not found"
    echo ""
    echo "Available sessions:"
    tmux list-sessions 2>/dev/null || echo "  (no tmux sessions running)"
    exit 1
  fi
else
  echo "Available tmux sessions:"
  echo ""
  tmux list-sessions 2>/dev/null || echo "  (no tmux sessions running)"
  echo ""
  echo "Usage: /dots-swe:worktree-attach <session-name>"
fi
