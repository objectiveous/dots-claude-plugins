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
  echo "  /dots-swe:dispatch <bead-id>       # Start new work"
  echo "  /dots-swe:code-integrate <bead-id> # Integrate after merge"
  exit 0
fi

# Parse arguments
FORMAT="text"
BEAD_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --format=json)
      FORMAT="json"
      shift
      ;;
    *)
      BEAD_ID="$1"
      shift
      ;;
  esac
done

TERMINAL=$(get_swe_terminal)
WORKTREES_DIR=$(get_worktrees_dir)

# If no bead specified, list available sessions
if [ -z "$BEAD_ID" ]; then
  # Collect session data
  sessions_json="["
  first_session=true

  if [ "$TERMINAL" = "ghostty" ]; then
    # List zmx sessions (format: session_name=xxx\tpid=xxx\tclients=xxx)
    SESSIONS=$(zmx list 2>/dev/null)
    if [ -n "$SESSIONS" ]; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue

        # Parse session name and PID
        session=$(echo "$line" | cut -f1 | cut -d= -f2)
        pid=$(echo "$line" | cut -f2 | cut -d= -f2)

        # Get working directory from process PID
        worktree_path=$(lsof -p "$pid" 2>/dev/null | grep cwd | awk '{print $9}')

        bead_id=""
        title=""
        has_worktree="false"

        if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
          has_worktree="true"
          # Get bead info if available
          if [ -f "$worktree_path/.swe-bead" ]; then
            bead_id=$(cat "$worktree_path/.swe-bead")
            title=$(bd show "$bead_id" 2>/dev/null | head -2 | tail -1 | sed 's/^[[:space:]]*//')
          fi
        fi

        # Add to JSON array
        if [ "$first_session" = true ]; then
          first_session=false
        else
          sessions_json+=","
        fi

        # Escape double quotes in title
        title_escaped=$(echo "$title" | sed 's/"/\\"/g')

        sessions_json+="{\"session\":\"$session\",\"bead\":\"$bead_id\",\"title\":\"$title_escaped\",\"has_worktree\":$has_worktree}"
      done <<< "$SESSIONS"
    fi
  else
    # List tmux sessions (get session name and pane PID)
    SESSIONS=$(tmux list-sessions -F "#{session_name} #{pane_pid}" 2>/dev/null)
    if [ -n "$SESSIONS" ]; then
      while IFS= read -r session pid; do
        [ -z "$session" ] && continue

        # Get working directory from process PID
        worktree_path=$(lsof -p "$pid" 2>/dev/null | grep cwd | awk '{print $9}')

        bead_id=""
        title=""
        has_worktree="false"

        if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
          has_worktree="true"
          # Get bead info if available
          if [ -f "$worktree_path/.swe-bead" ]; then
            bead_id=$(cat "$worktree_path/.swe-bead")
            title=$(bd show "$bead_id" 2>/dev/null | head -2 | tail -1 | sed 's/^[[:space:]]*//')
          fi
        fi

        # Add to JSON array
        if [ "$first_session" = true ]; then
          first_session=false
        else
          sessions_json+=","
        fi

        # Escape double quotes in title
        title_escaped=$(echo "$title" | sed 's/"/\\"/g')

        sessions_json+="{\"session\":\"$session\",\"bead\":\"$bead_id\",\"title\":\"$title_escaped\",\"has_worktree\":$has_worktree}"
      done <<< "$SESSIONS"
    fi
  fi

  sessions_json+="]"

  # Output based on format
  if [ "$FORMAT" = "json" ]; then
    echo "$sessions_json"
  else
    # Text format output
    echo "📋 Available sessions to continue:"
    echo ""

    count=$(echo "$sessions_json" | grep -o '"session"' | wc -l)

    if [ "$count" -eq 0 ]; then
      echo "  (no active sessions)"
      echo ""
      echo "Start new work with: /dots-swe:dispatch <bead-id>"
    else
      # Parse and display sessions
      echo "$sessions_json" | grep -o '{[^}]*}' | while read -r obj; do
        session=$(echo "$obj" | grep -o '"session":"[^"]*"' | cut -d'"' -f4)
        title=$(echo "$obj" | grep -o '"title":"[^"]*"' | cut -d'"' -f4)
        has_worktree=$(echo "$obj" | grep -o '"has_worktree":[^,}]*' | cut -d':' -f2)

        if [ "$has_worktree" = "true" ] && [ -n "$title" ]; then
          echo "  • $session"
          echo "    $title"
        elif [ "$has_worktree" = "true" ]; then
          echo "  • $session"
        else
          echo "  • $session (no worktree)"
        fi
      done

      echo ""
      echo "Continue with: /dots-swe:continue <session-name>"
    fi
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
      echo "Start new work with: /dots-swe:dispatch $BEAD_ID"
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
      echo "Start new work with: /dots-swe:dispatch $BEAD_ID"
      exit 1
    fi
  fi
fi
