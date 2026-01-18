#!/bin/bash
# Reconnect to stranded worktrees (worktrees without active sessions)

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
      echo "Reconnect to stranded worktrees by opening new terminal sessions."
      echo ""
      echo "Options:"
      echo "  --dry-run, -n    Show what would happen without doing it"
      echo "  --tab            Open in new Ghostty tabs (default)"
      echo "  --window         Open in new Ghostty windows"
      echo ""
      echo "What this does:"
      echo "  • Finds all git worktrees (excluding main)"
      echo "  • Checks which ones don't have active sessions"
      echo "  • Opens new terminal sessions for stranded worktrees"
      echo ""
      echo "Use this when:"
      echo "  • Terminal sessions were closed or lost"
      echo "  • Worktrees were created manually without sessions"
      echo "  • After system restart"
      exit 0
      ;;
  esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Reconnecting to Stranded Worktrees              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

REPO_ROOT=$(get_repo_root)
TERMINAL=$(get_swe_terminal)
STRANDED_WORKTREES=()

echo "Scanning for stranded worktrees..."
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
            fi
          fi
        else
          # Check for tmux session
          if [ -f "$WORKTREE_PATH/.tmux-session" ]; then
            SESSION_NAME=$(cat "$WORKTREE_PATH/.tmux-session")
            if tmux_session_exists "$SESSION_NAME"; then
              HAS_SESSION=true
            fi
          fi
        fi

        if [ "$HAS_SESSION" = false ]; then
          echo "  ⚠️  Stranded: $BEAD_ID ($BRANCH)"
          STRANDED_WORKTREES+=("$WORKTREE_PATH:$BEAD_ID")
        else
          echo "  ✓ Active: $BEAD_ID ($BRANCH)"
        fi
      fi
      ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null)

echo ""

if [ ${#STRANDED_WORKTREES[@]} -eq 0 ]; then
  echo "✅ No stranded worktrees found. All worktrees have active sessions."
  exit 0
fi

echo "Found ${#STRANDED_WORKTREES[@]} stranded worktree(s)"
echo ""

# Dry-run mode
if [ "$DRY_RUN" = true ]; then
  MODE="${SWE_GHOSTTY_MODE:-tab}"
  echo "📋 DRY RUN: Would reconnect to:"
  echo ""
  for entry in "${STRANDED_WORKTREES[@]}"; do
    WORKTREE_PATH="${entry%%:*}"
    BEAD_ID="${entry##*:}"
    echo "  $BEAD_ID"
    echo "    Path: $WORKTREE_PATH"
  done
  echo ""
  if [ "$TERMINAL" = "ghostty" ]; then
    echo "Would open Ghostty ${MODE}s with zmx sessions"
  else
    echo "Would open iTerm windows with tmux sessions"
  fi
  exit 0
fi

# Reconnect to stranded worktrees
echo "Reconnecting to stranded worktrees..."
echo ""

FIRST_SESSION=""
for entry in "${STRANDED_WORKTREES[@]}"; do
  WORKTREE_PATH="${entry%%:*}"
  BEAD_ID="${entry##*:}"

  echo "Opening session for: $BEAD_ID"

  # Register and open session
  ABS_PATH="$(cd "$WORKTREE_PATH" && pwd)"
  register_worktree "$ABS_PATH" "$BEAD_ID" "$BEAD_ID"

  if [ "$TERMINAL" = "ghostty" ]; then
    # Start zmx session in background
    start_zmx_session_background "$WORKTREE_PATH" "$BEAD_ID"
    echo "$BEAD_ID" > "$WORKTREE_PATH/.zmx-session"
    [ -z "$FIRST_SESSION" ] && FIRST_SESSION="$BEAD_ID"
  else
    # Create tmux session
    SESSION_NAME=$(open_tmux_worktree "$WORKTREE_PATH" "$BEAD_ID")
    echo "$SESSION_NAME" > "$WORKTREE_PATH/.tmux-session"
    [ -z "$FIRST_SESSION" ] && FIRST_SESSION="$SESSION_NAME"
  fi

  echo "  ✓ Session created"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Reconnected to ${#STRANDED_WORKTREES[@]} worktree(s)"
echo ""

# Attach to first session
if [ -n "$FIRST_SESSION" ]; then
  if [ "$TERMINAL" = "ghostty" ]; then
    MODE="${SWE_GHOSTTY_MODE:-tab}"
    echo "Opening Ghostty $MODE for first session: $FIRST_SESSION"
    echo "(Other sessions running in background - use 'zmx attach <name>' to switch)"
    # Find the worktree path for the first session
    for entry in "${STRANDED_WORKTREES[@]}"; do
      BEAD_ID="${entry##*:}"
      if [ "$BEAD_ID" = "$FIRST_SESSION" ]; then
        WORKTREE_PATH="${entry%%:*}"
        open_ghostty_zmx_session "$WORKTREE_PATH" "$FIRST_SESSION"
        break
      fi
    done
  else
    echo "Attaching to tmux session: $FIRST_SESSION"
    attach_terminal_to_tmux "$FIRST_SESSION"
  fi
fi
