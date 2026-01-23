#!/bin/bash
# Reconnect to all worktrees by opening terminal tabs/windows

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Parse flags
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --tab) export SWE_GHOSTTY_MODE=tab ;;
    --window) export SWE_GHOSTTY_MODE=window ;;
    --help|-h)
      echo "Usage: /dots-swe:reconnect [options]"
      echo ""
      echo "Reconnect to ALL worktrees by opening terminal sessions."
      echo ""
      echo "Options:"
      echo "  --dry-run, -n    Show what would happen without doing it"
      echo "  --tab            Open in new Ghostty tabs (default)"
      echo "  --window         Open in new Ghostty windows"
      echo ""
      echo "What this does:"
      echo "  • Finds all git worktrees (excluding main)"
      echo "  • For worktrees with existing sessions: opens tabs to reconnect"
      echo "  • For worktrees without sessions: creates new sessions (no auto-start)"
      echo "  • Opens a terminal tab/window for EACH worktree"
      echo ""
      echo "Use this when:"
      echo "  • You want to open tabs for all your work-in-progress branches"
      echo "  • Terminal sessions were closed and you want to restore them all"
      echo "  • After system restart"
      echo "  • You manually created worktrees and need to connect to them"
      exit 0
      ;;
  esac
done

echo "Reconnecting to All Worktrees"
echo ""

REPO_ROOT=$(get_repo_root)
TERMINAL=$(get_swe_terminal)
ALL_WORKTREES=()
EXISTING_SESSIONS=()
NEW_SESSIONS=()

echo "Scanning worktrees..."
echo ""

# Parse git worktree list
while IFS= read -r line; do
  case "$line" in
    worktree*)
      WORKTREE_PATH="${line#worktree }"
      # Skip main worktree
      if [ "$WORKTREE_PATH" != "$REPO_ROOT" ]; then
        BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "detached")
        BEAD_ID=$(basename "$WORKTREE_PATH")

        # Check if session exists
        HAS_SESSION=false

        if [ "$TERMINAL" = "ghostty" ]; then
          # Check for zmx session
          if [ -f "$WORKTREE_PATH/.zmx-session" ]; then
            SESSION_NAME=$(cat "$WORKTREE_PATH/.zmx-session")
            if zmx_session_exists "$SESSION_NAME"; then
              HAS_SESSION=true
              echo "  ✓ Has session: $BEAD_ID ($BRANCH)"
              EXISTING_SESSIONS+=("$WORKTREE_PATH:$BEAD_ID")
            fi
          fi
        else
          # Check for tmux session
          if [ -f "$WORKTREE_PATH/.tmux-session" ]; then
            SESSION_NAME=$(cat "$WORKTREE_PATH/.tmux-session")
            if tmux_session_exists "$SESSION_NAME"; then
              HAS_SESSION=true
              echo "  ✓ Has session: $BEAD_ID ($BRANCH)"
              EXISTING_SESSIONS+=("$WORKTREE_PATH:$BEAD_ID")
            fi
          fi
        fi

        if [ "$HAS_SESSION" = false ]; then
          echo "  ⚠️  No session: $BEAD_ID ($BRANCH)"
          NEW_SESSIONS+=("$WORKTREE_PATH:$BEAD_ID")
        fi

        ALL_WORKTREES+=("$WORKTREE_PATH:$BEAD_ID:$HAS_SESSION")
      fi
      ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null)

echo ""

if [ ${#ALL_WORKTREES[@]} -eq 0 ]; then
  echo "ℹ️  No worktrees found (only main branch exists)."
  exit 0
fi

TOTAL_COUNT=${#ALL_WORKTREES[@]}
EXISTING_COUNT=${#EXISTING_SESSIONS[@]}
NEW_COUNT=${#NEW_SESSIONS[@]}

echo "Found $TOTAL_COUNT worktree(s):"
echo "  - $EXISTING_COUNT with existing sessions"
echo "  - $NEW_COUNT without sessions (will create new)"
echo ""

# Dry-run mode
if [ "$DRY_RUN" = true ]; then
  MODE="${SWE_GHOSTTY_MODE:-tab}"
  echo "📋 DRY RUN: Would reconnect to all worktrees"
  echo ""

  if [ ${#EXISTING_SESSIONS[@]} -gt 0 ]; then
    echo "Would attach to existing sessions:"
    for entry in "${EXISTING_SESSIONS[@]}"; do
      BEAD_ID="${entry##*:}"
      echo "  $BEAD_ID"
    done
    echo ""
  fi

  if [ ${#NEW_SESSIONS[@]} -gt 0 ]; then
    echo "Would create new sessions (no auto-start):"
    for entry in "${NEW_SESSIONS[@]}"; do
      BEAD_ID="${entry##*:}"
      echo "  $BEAD_ID"
    done
    echo ""
  fi

  if [ "$TERMINAL" = "ghostty" ]; then
    echo "Would open $TOTAL_COUNT Ghostty ${MODE}(s)"
  else
    echo "Would open $TOTAL_COUNT iTerm window(s)"
  fi
  exit 0
fi

# Create new sessions for stranded worktrees
if [ ${#NEW_SESSIONS[@]} -gt 0 ]; then
  echo "Creating new sessions (without auto-start)..."
  echo ""

  for entry in "${NEW_SESSIONS[@]}"; do
    WORKTREE_PATH="${entry%%:*}"
    BEAD_ID="${entry##*:}"

    echo "  Creating session for: $BEAD_ID"

    # Register worktree
    ABS_PATH="$(cd "$WORKTREE_PATH" && pwd)"
    register_worktree "$ABS_PATH" "$BEAD_ID" "$BEAD_ID"

    if [ "$TERMINAL" = "ghostty" ]; then
      # Start zmx session WITHOUT auto-start (no "go!" prompt)
      start_zmx_session_background "$WORKTREE_PATH" "$BEAD_ID" "true"
      echo "$BEAD_ID" > "$WORKTREE_PATH/.zmx-session"
    else
      # Create tmux session
      SESSION_NAME=$(open_tmux_worktree "$WORKTREE_PATH" "$BEAD_ID")
      echo "$SESSION_NAME" > "$WORKTREE_PATH/.tmux-session"
    fi

    echo "    ✓ Session created (awaits human input)"
  done

  echo ""
fi

# Open tabs for ALL worktrees
echo "Opening terminals for all worktrees..."
echo ""

if [ "$TERMINAL" = "ghostty" ]; then
  MODE="${SWE_GHOSTTY_MODE:-tab}"
  echo "Opening $TOTAL_COUNT Ghostty ${MODE}(s)..."

  for entry in "${ALL_WORKTREES[@]}"; do
    IFS=: read -r WORKTREE_PATH BEAD_ID HAS_SESSION <<< "$entry"

    echo "  Opening $MODE for: $BEAD_ID"
    open_ghostty_zmx_session "$WORKTREE_PATH" "$BEAD_ID"
    sleep 0.3  # Small delay to avoid overwhelming Ghostty
  done
else
  echo "Opening iTerm windows..."

  # For iTerm, we use tmux windows - attach to the session
  FIRST_SESSION=""
  for entry in "${ALL_WORKTREES[@]}"; do
    IFS=: read -r WORKTREE_PATH BEAD_ID HAS_SESSION <<< "$entry"

    if [ -f "$WORKTREE_PATH/.tmux-session" ]; then
      SESSION_NAME=$(cat "$WORKTREE_PATH/.tmux-session")
      [ -z "$FIRST_SESSION" ] && FIRST_SESSION="$SESSION_NAME"
    fi
  done

  if [ -n "$FIRST_SESSION" ]; then
    echo "  Attaching to tmux session: $FIRST_SESSION"
    attach_terminal_to_tmux "$FIRST_SESSION"
  fi
fi

echo ""
echo "✅ Reconnected to $TOTAL_COUNT worktree(s)"
echo ""

if [ ${#NEW_SESSIONS[@]} -gt 0 ]; then
  echo "Note: $NEW_COUNT new session(s) created without auto-start."
  echo "      These sessions await human input - Claude won't auto-run."
fi
