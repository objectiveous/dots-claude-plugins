---
description: "Merge a completed worktree branch back to main"
allowed-tools: ["Bash"]
---

# Merge Worktree to Main

Merges a completed worktree's branch back to main, then optionally cleans up the worktree.

**Usage:** `/dots-dev:worktree-merge <worktree-name> [--cleanup]`

**Options:**
- `--cleanup` - Delete the worktree after successful merge

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-merge <worktree-name> [--cleanup]"
  echo ""
  echo "Merge a completed worktree's branch back to main."
  echo ""
  echo "Arguments:"
  echo "  <worktree-name>    Name of the worktree to merge"
  echo ""
  echo "Options:"
  echo "  --cleanup          Delete worktree after successful merge"
  echo ""
  echo "Requirements:"
  echo "  - Worktree must have no uncommitted changes"
  echo ""
  echo "Actions performed:"
  echo "  1. Checks for uncommitted changes"
  echo "  2. Updates main branch"
  echo "  3. Merges branch into main (--no-ff)"
  echo "  4. Pushes main to origin"
  echo "  5. Cleans up worktree (if --cleanup)"
  echo ""
  echo "Examples:"
  echo "  /dots-dev:worktree-merge feature/auth"
  echo "  /dots-dev:worktree-merge dots-abc --cleanup"
  exit 0
fi

!WORKTREE_NAME=$(get_positional_arg "$@")
!CLEANUP=$(has_flag "--cleanup" "$@" && echo true || echo false)

!if [ -z "$WORKTREE_NAME" ]; then
  echo "Usage: /dots-dev:worktree-merge <worktree-name> [--cleanup]"
  echo "Use --help for more information."
  echo ""
  echo "Available worktrees:"
  git worktree list
  exit 1
fi

!REPO_ROOT=$(get_repo_root)
!WORKTREES_DIR=$(get_worktrees_dir)
!WORKTREE_PATH=$(find_worktree_path "$WORKTREE_NAME")

!if [ -z "$WORKTREE_PATH" ]; then
  WORKTREE_PATH="$WORKTREES_DIR/$WORKTREE_NAME"
fi

!if [ ! -d "$WORKTREE_PATH" ]; then
  echo "ERROR: Worktree '$WORKTREE_NAME' not found"
  echo ""
  echo "Available worktrees:"
  git worktree list
  exit 1
fi

!BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current)
!echo "Merging worktree: $WORKTREE_NAME"
!echo "Branch: $BRANCH"
!echo "Path: $WORKTREE_PATH"
!echo ""

# Check for uncommitted changes in the worktree
!CHANGES=$(git -C "$WORKTREE_PATH" status --porcelain | wc -l | tr -d ' ')
!if [ "$CHANGES" -gt 0 ]; then
  echo "❌ ERROR: Worktree has uncommitted changes:"
  git -C "$WORKTREE_PATH" status --short
  echo ""
  echo "Commit or stash changes before merging."
  exit 1
fi

# Check for unpushed commits
!UNPUSHED=$(git -C "$WORKTREE_PATH" log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
!if [ "$UNPUSHED" -gt 0 ]; then
  echo "⚠️  Warning: $UNPUSHED unpushed commits in worktree"
  echo ""
fi

# Switch to main in the main repo and pull latest
!echo "Updating main branch..."
!git -C "$REPO_ROOT" checkout main
!git -C "$REPO_ROOT" pull origin main

# Merge the branch
!echo ""
!echo "Merging $BRANCH into main..."
!if git -C "$REPO_ROOT" merge "$BRANCH" --no-ff -m "Merge branch '$BRANCH'"; then
  echo ""
  echo "✅ Successfully merged $BRANCH into main"
else
  echo ""
  echo "❌ Merge failed - conflicts detected"
  echo ""
  echo "Resolve conflicts in: $REPO_ROOT"
  echo "Then run: git commit"
  echo "Or abort: git merge --abort"
  exit 1
fi

# Push main
!echo ""
!echo "Pushing main to origin..."
!git -C "$REPO_ROOT" push origin main

# Cleanup if requested
!if [ "$CLEANUP" = true ]; then
  echo ""
  echo "Cleaning up worktree..."

  # Get tab ID from registry
  TAB_ID=$(get_worktree_info "$WORKTREE_PATH" "tab_id")

  # Close terminal tab if we have a tab ID
  if [ -n "$TAB_ID" ]; then
    echo "Closing terminal tab..."
    close_iterm_tab "$TAB_ID"
  fi

  # Remove git worktree
  git worktree remove "$WORKTREE_PATH" --force

  # Delete branch
  git branch -d "$BRANCH" 2>/dev/null || echo "Note: Branch $BRANCH not deleted (may have diverged)"

  # Remove from registry
  unregister_worktree "$WORKTREE_PATH"

  echo "✅ Worktree cleaned up"
fi

!echo ""
!echo "Done! Main is now up to date with $BRANCH"
