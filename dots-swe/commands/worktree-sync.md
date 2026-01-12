---
allowed-tools: Bash(git:*)
description: Pull latest changes from main into a worktree
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Sync Worktree with Main

Pulls latest changes from main branch into the current or specified worktree via rebase.

**Usage:** `/dots-swe:worktree-sync [worktree-name]`

If no worktree name provided, syncs the current worktree.

## Implementation

!source "*/scripts/swe-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:worktree-sync [worktree-name]"
  echo ""
  echo "Pulls latest changes from main into a worktree via rebase."
  echo "If no name provided, syncs the current worktree."
  exit 0
fi

# Determine target worktree
!WORKTREE_PATH=""
!if [ -n "$1" ]; then
  # Name provided - find the worktree
  WORKTREE_PATH=$(find_worktree_path "$1")
  if [ -z "$WORKTREE_PATH" ]; then
    echo "ERROR: Worktree '$1' not found"
    echo ""
    echo "Available worktrees:"
    git worktree list
    exit 1
  fi
else
  # No name - use current directory
  WORKTREE_PATH=$(pwd)
  REPO_ROOT=$(get_repo_root)
  if [ "$WORKTREE_PATH" = "$REPO_ROOT" ]; then
    echo "ERROR: You're in the main repository root, not a worktree"
    echo ""
    echo "Usage: /dots-swe:worktree-sync <worktree-name>"
    echo ""
    echo "Available worktrees:"
    git worktree list
    exit 1
  fi
fi

!BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current)
!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                  Syncing Worktree                            ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""
!echo "Worktree: $WORKTREE_PATH"
!echo "Branch: $BRANCH"
!echo ""

# Fetch latest
!echo "Fetching latest from origin/main..."
!git -C "$WORKTREE_PATH" fetch origin main

# Check for uncommitted changes
!STASHED=false
!CHANGES=$(git -C "$WORKTREE_PATH" status --porcelain | wc -l | tr -d ' ')
!if [ "$CHANGES" -gt 0 ]; then
  echo ""
  echo "Uncommitted changes detected:"
  git -C "$WORKTREE_PATH" status --short
  echo ""
  echo "Stashing changes..."
  git -C "$WORKTREE_PATH" stash push -m "Auto-stash before sync"
  STASHED=true
fi

# Rebase onto main
!echo ""
!echo "Rebasing onto origin/main..."
!if git -C "$WORKTREE_PATH" rebase origin/main; then
  echo "✅ Rebase successful"
else
  echo "❌ Rebase failed - conflicts detected"
  echo ""
  echo "To resolve:"
  echo "  cd $WORKTREE_PATH"
  echo "  # Fix conflicts in the files"
  echo "  git add <fixed-files>"
  echo "  git rebase --continue"
  echo ""
  echo "Or abort:"
  echo "  git rebase --abort"
  exit 1
fi

# Restore stashed changes
!if [ "$STASHED" = true ]; then
  echo ""
  echo "Restoring stashed changes..."
  if git -C "$WORKTREE_PATH" stash pop; then
    echo "✅ Stash applied"
  else
    echo "⚠️  Conflicts applying stash - resolve manually"
    echo "   Stash is still saved, use: git stash list"
  fi
fi

!echo ""
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "✅ Worktree synced: $BRANCH"
