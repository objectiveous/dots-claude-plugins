---
description: "Clean up stale worktrees and prune registry"
allowed-tools: ["Bash"]
---

# Cleanup Stale Worktrees

Removes worktrees that no longer exist from the registry, prunes git worktree metadata, and optionally removes merged branches.

**Usage:** `/dots-dev:worktree-cleanup [--prune-merged]`

**Options:**
- `--prune-merged` - Also delete worktrees whose branches have been merged to main

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-cleanup [--prune-merged]"
  echo ""
  echo "Clean up stale worktrees and prune registry."
  echo ""
  echo "Options:"
  echo "  --prune-merged    Also delete worktrees with branches merged to main"
  echo ""
  echo "Actions performed:"
  echo "  1. Prunes stale git worktree metadata"
  echo "  2. Removes registry entries pointing to non-existent paths"
  echo "  3. Optionally removes worktrees with merged branches"
  echo ""
  echo "See also: /dots-dev:doctor (comprehensive health check)"
  exit 0
fi

!PRUNE_MERGED=$(has_flag "--prune-merged" "$@" && echo true || echo false)

!echo "Cleaning up worktrees..."
!echo ""

# Prune git worktree metadata for deleted worktrees
!echo "Pruning stale git worktree references..."
!git worktree prune -v
!echo ""

# Clean up registry entries that point to non-existent paths
!REGISTRY_FILE=$(get_registry_file)

!if [ -f "$REGISTRY_FILE" ]; then
  echo "Checking registry for stale entries..."

  STALE_PATHS=$(jq -r 'keys[]' "$REGISTRY_FILE" 2>/dev/null | while read path; do
    if [ ! -d "$path" ]; then
      echo "$path"
    fi
  done)

  if [ -n "$STALE_PATHS" ]; then
    echo "$STALE_PATHS" | while read path; do
      if [ -n "$path" ]; then
        echo "  Removing stale registry entry: $path"
        unregister_worktree "$path"
      fi
    done
  else
    echo "  No stale registry entries found."
  fi
  echo ""
fi

# Optionally prune merged branches
!if [ "$PRUNE_MERGED" = true ]; then
  echo "Checking for worktrees with merged branches..."

  WORKTREES_DIR=$(get_worktrees_dir)

  if [ -d "$WORKTREES_DIR" ]; then
    for dir in "$WORKTREES_DIR"/*/; do
      if [ -d "$dir" ]; then
        BRANCH_NAME=$(basename "$dir")

        # Check if branch is merged to main
        if git branch --merged main 2>/dev/null | grep -q "^\s*$BRANCH_NAME$"; then
          echo "  Branch '$BRANCH_NAME' is merged to main"
          echo "  Removing worktree..."

          WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_NAME"
          TAB_ID=$(get_worktree_info "$WORKTREE_PATH" "tab_id")

          [ -n "$TAB_ID" ] && close_iterm_tab "$TAB_ID"
          git worktree remove "$WORKTREE_PATH" --force 2>/dev/null
          git branch -d "$BRANCH_NAME" 2>/dev/null
          unregister_worktree "$WORKTREE_PATH"

          echo "  Cleaned up: $BRANCH_NAME"
        fi
      fi
    done
  fi
  echo ""
fi

!echo "Current worktrees:"
!git worktree list
!echo ""
!echo "Cleanup complete."
