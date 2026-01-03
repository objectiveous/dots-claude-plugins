---
description: "Pull latest changes from main into a worktree"
allowed-tools: ["Bash"]
---

# Sync Worktree with Main

Pulls latest changes from main branch into the current or specified worktree.

**Usage:** `/dots-dev:worktree-sync [worktree-name]`

If no worktree name provided, syncs the current worktree.

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-sync [worktree-name]"
  echo ""
  echo "Pull latest changes from main into a worktree via rebase."
  echo ""
  echo "Arguments:"
  echo "  [worktree-name]    Optional. If omitted, syncs current worktree."
  echo ""
  echo "Behavior:"
  echo "  - Fetches origin/main"
  echo "  - Stashes uncommitted changes if present"
  echo "  - Rebases onto origin/main"
  echo "  - Restores stashed changes"
  echo ""
  echo "Examples:"
  echo "  /dots-dev:worktree-sync              # Sync current worktree"
  echo "  /dots-dev:worktree-sync feature/auth # Sync specific worktree"
  exit 0
fi

!WORKTREE_NAME="$1"
!REPO_ROOT=$(get_repo_root)
!WORKTREES_DIR=$(get_worktrees_dir)

# Determine which worktree to sync
!if [ -n "$WORKTREE_NAME" ]; then
  WORKTREE_PATH=$(find_worktree_path "$WORKTREE_NAME")
  if [ -z "$WORKTREE_PATH" ]; then
    WORKTREE_PATH="$WORKTREES_DIR/$WORKTREE_NAME"
  fi
  if [ ! -d "$WORKTREE_PATH" ]; then
    echo "ERROR: Worktree '$WORKTREE_NAME' not found"
    echo ""
    echo "Available worktrees:"
    git worktree list
    exit 1
  fi
else
  WORKTREE_PATH=$(pwd)
  # Check if we're in a worktree (not main repo)
  if [ "$WORKTREE_PATH" = "$REPO_ROOT" ]; then
    echo "ERROR: You're in the main repository, not a worktree."
    echo "Either specify a worktree name or run from within a worktree."
    echo ""
    echo "Usage: /dots-dev:worktree-sync [worktree-name]"
    exit 1
  fi
fi

!BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current)
!echo "Syncing worktree: $WORKTREE_PATH"
!echo "Branch: $BRANCH"
!echo ""

# First, fetch latest from origin
!echo "Fetching from origin..."
!git -C "$WORKTREE_PATH" fetch origin main

# Check for uncommitted changes
!CHANGES=$(git -C "$WORKTREE_PATH" status --porcelain | wc -l | tr -d ' ')
!if [ "$CHANGES" -gt 0 ]; then
  echo ""
  echo "⚠️  You have uncommitted changes:"
  git -C "$WORKTREE_PATH" status --short
  echo ""
  echo "Stashing changes before rebase..."
  git -C "$WORKTREE_PATH" stash push -m "Auto-stash before sync $(date +%Y-%m-%d_%H:%M:%S)"
  STASHED=true
else
  STASHED=false
fi

# Rebase onto main
!echo ""
!echo "Rebasing $BRANCH onto origin/main..."
!if git -C "$WORKTREE_PATH" rebase origin/main; then
  echo ""
  echo "✅ Successfully rebased onto main"
else
  echo ""
  echo "❌ Rebase failed - conflicts detected"
  echo ""
  echo "Resolve conflicts in: $WORKTREE_PATH"
  echo "Then run: git rebase --continue"
  echo "Or abort: git rebase --abort"
  exit 1
fi

# Restore stashed changes if any
!if [ "$STASHED" = true ]; then
  echo ""
  echo "Restoring stashed changes..."
  if git -C "$WORKTREE_PATH" stash pop; then
    echo "✅ Stashed changes restored"
  else
    echo "⚠️  Conflict applying stashed changes"
    echo "Your stash is preserved. Resolve manually with: git stash pop"
  fi
fi

!echo ""
!echo "Sync complete for: $BRANCH"
