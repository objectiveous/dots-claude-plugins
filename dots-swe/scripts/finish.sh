#!/bin/bash
# Finish work on a bead - verify PR merged, close bead, cleanup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Parse flags
DRY_RUN=false
FORCE=false
BEAD_ID=""
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --force|-f) FORCE=true ;;
    --help|-h) ;; # handled below
    *) BEAD_ID="$arg" ;;
  esac
done

# Help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:finish [options] [bead-id]"
  echo ""
  echo "Finish work on a bead after PR is merged."
  echo ""
  echo "Options:"
  echo "  --dry-run, -n    Show what would happen without doing it"
  echo "  --force, -f      Skip PR merge check (use with caution)"
  echo ""
  echo "What this does:"
  echo "  1. Verifies PR was opened and merged to main"
  echo "  2. Closes the bead"
  echo "  3. Kills the session (zmx/tmux)"
  echo "  4. Deletes the worktree and branch"
  echo ""
  echo "If no bead-id provided, uses current directory's .swe-bead file."
  echo ""
  echo "Examples:"
  echo "  /dots-swe:finish              # Finish current worktree's bead"
  echo "  /dots-swe:finish dots-abc     # Finish specific bead"
  echo "  /dots-swe:finish --dry-run    # Preview what would happen"
  echo ""
  echo "See also:"
  echo "  /dots-swe:start <bead-id>     # Start new work"
  echo "  /dots-swe:continue <bead-id>  # Continue existing work"
  exit 0
fi

# If no bead ID, try to get from current directory
if [ -z "$BEAD_ID" ]; then
  if [ -f ".swe-bead" ]; then
    BEAD_ID=$(cat .swe-bead)
    echo "Using bead from current directory: $BEAD_ID"
  else
    echo "ERROR: No bead ID provided and no .swe-bead file in current directory"
    echo ""
    echo "Usage: /dots-swe:finish [bead-id]"
    exit 1
  fi
fi

WORKTREES_DIR=$(get_worktrees_dir)
WORKTREE_PATH="$WORKTREES_DIR/$BEAD_ID"
TERMINAL=$(get_swe_terminal)

echo "🏁 Finishing work on: $BEAD_ID"
echo ""

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
  echo "⚠️  No worktree found at: $WORKTREE_PATH"
  echo "   Will still try to close bead and cleanup sessions."
  echo ""
fi

# Get branch name (same as bead ID in our workflow)
BRANCH="$BEAD_ID"

# Check for PR
echo "🔍 Checking for PR..."
PR_INFO=$(gh pr list --head "$BRANCH" --state all --json number,state,mergedAt,url 2>/dev/null)

if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "[]" ]; then
  echo "❌ No PR found for branch: $BRANCH"
  if [ "$FORCE" = true ]; then
    echo "   --force specified, continuing anyway..."
  else
    echo ""
    echo "Create a PR first with: /dots-swe:ship"
    echo "Or use --force to skip this check"
    exit 1
  fi
else
  PR_NUMBER=$(echo "$PR_INFO" | jq -r '.[0].number')
  PR_STATE=$(echo "$PR_INFO" | jq -r '.[0].state')
  PR_MERGED=$(echo "$PR_INFO" | jq -r '.[0].mergedAt')
  PR_URL=$(echo "$PR_INFO" | jq -r '.[0].url')

  echo "   PR #$PR_NUMBER: $PR_STATE"
  echo "   $PR_URL"

  if [ "$PR_STATE" = "MERGED" ] || [ "$PR_MERGED" != "null" ]; then
    echo "   ✅ PR is merged"
  elif [ "$PR_STATE" = "CLOSED" ]; then
    echo "   ⚠️  PR was closed without merging"
    if [ "$FORCE" != true ]; then
      echo ""
      echo "Use --force to cleanup anyway"
      exit 1
    fi
  else
    echo "   ❌ PR is still open (state: $PR_STATE)"
    if [ "$FORCE" != true ]; then
      echo ""
      echo "Merge the PR first, or use --force to cleanup anyway"
      exit 1
    fi
    echo "   --force specified, continuing anyway..."
  fi
fi
echo ""

# Dry run - show what would happen
if [ "$DRY_RUN" = true ]; then
  echo "📋 DRY RUN: Here's what would happen"
  echo ""
  echo "  1. Close bead: bd close $BEAD_ID"

  if [ "$TERMINAL" = "ghostty" ]; then
    if zmx_session_exists "$BEAD_ID"; then
      echo "  2. Kill zmx session: zmx kill $BEAD_ID"
    else
      echo "  2. (no zmx session to kill)"
    fi
  else
    if tmux_session_exists "$BEAD_ID"; then
      echo "  2. Kill tmux session: tmux kill-session -t $BEAD_ID"
    else
      echo "  2. (no tmux session to kill)"
    fi
  fi

  if [ -d "$WORKTREE_PATH" ]; then
    echo "  3. Remove worktree: git worktree remove $WORKTREE_PATH --force"
    echo "  4. Delete branch: git branch -D $BRANCH"
  else
    echo "  3. (no worktree to remove)"
    echo "  4. (no branch to delete)"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Run without --dry-run to execute"
  exit 0
fi

# Close the bead
echo "📝 Closing bead..."
if bd close "$BEAD_ID" 2>/dev/null; then
  echo "   ✅ Bead closed"
else
  echo "   ⚠️  Failed to close bead (may already be closed)"
fi

# Kill session
echo "🔌 Killing session..."
if [ "$TERMINAL" = "ghostty" ]; then
  if zmx_session_exists "$BEAD_ID"; then
    kill_zmx_session "$BEAD_ID"
    echo "   ✅ zmx session killed"
  else
    echo "   (no zmx session running)"
  fi
else
  if tmux_session_exists "$BEAD_ID"; then
    tmux kill-session -t "$BEAD_ID" 2>/dev/null
    echo "   ✅ tmux session killed"
  else
    echo "   (no tmux session running)"
  fi
fi

# Remove worktree and branch
if [ -d "$WORKTREE_PATH" ]; then
  echo "🗑️  Removing worktree..."
  git worktree remove "$WORKTREE_PATH" --force 2>/dev/null
  echo "   ✅ Worktree removed"

  echo "🌿 Deleting branch..."
  git branch -D "$BRANCH" 2>/dev/null
  echo "   ✅ Branch deleted"

  # Unregister from registry
  unregister_worktree "$WORKTREE_PATH"
else
  echo "   (no worktree to remove)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Finished: $BEAD_ID"
echo ""
echo "The PR has been merged and all local resources cleaned up."
