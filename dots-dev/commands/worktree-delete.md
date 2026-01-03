---
description: "Delete git worktrees by name"
allowed-tools: ["Bash"]
---

# Delete Git Worktrees

Deletes specified worktrees, closes associated iTerm tabs, and cleans up branches.

**Usage:** `/dots-dev:worktree-delete <name1> [name2] [...]`

If no names provided, shows available worktrees.

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Show available worktrees if no args
!if [ $# -eq 0 ]; then
  echo "Available worktrees:"
  echo ""
  git worktree list
  echo ""
  echo "Usage: /dots-dev:worktree-delete <name1> [name2] [...]"
  exit 0
fi

# Process each worktree
!for WORKTREE_NAME in "$@"; do
  echo "Processing worktree: $WORKTREE_NAME"

  # Find worktree path
  WORKTREE_PATH=$(find_worktree_path "$WORKTREE_NAME")

  if [ -z "$WORKTREE_PATH" ]; then
    echo "ERROR: Worktree '$WORKTREE_NAME' not found"
    git worktree list
    continue
  fi

  # Get branch name
  BRANCH_NAME=$(get_worktree_branch "$WORKTREE_PATH")

  # Get tab ID from registry
  TAB_ID=$(get_worktree_info "$WORKTREE_PATH" "tab_id")

  echo "  Branch: $BRANCH_NAME"
  echo "  Path: $WORKTREE_PATH"
  echo "  Tab ID: ${TAB_ID:-none}"

  # Close terminal tab if we have a tab ID
  if [ -n "$TAB_ID" ]; then
    echo "  Closing terminal tab..."
    close_iterm_tab "$TAB_ID"
  fi

  # Remove git worktree
  echo "  Removing git worktree..."
  git worktree remove "$WORKTREE_PATH" --force

  # Delete branch
  echo "  Deleting branch: $BRANCH_NAME"
  git branch -D "$BRANCH_NAME" 2>/dev/null || echo "  Warning: Branch $BRANCH_NAME not found"

  # Remove from registry
  unregister_worktree "$WORKTREE_PATH"
  echo "  Removed from registry"

  echo ""
  echo "Worktree '$WORKTREE_NAME' deleted."
  echo ""
done

!echo "Remaining worktrees:"
!git worktree list
