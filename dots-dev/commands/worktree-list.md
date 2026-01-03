---
description: "List all git worktrees in the current repository"
allowed-tools: ["Bash"]
---

# List Git Worktrees

Shows all git worktrees for the current repository with their status.

**Usage:** `/dots-dev:worktree-list`

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-list"
  echo ""
  echo "List all git worktrees for the current repository."
  echo ""
  echo "Shows:"
  echo "  - Git worktree paths and branches"
  echo "  - Registered worktrees with Claude session info"
  echo "  - Creation timestamps"
  echo ""
  echo "See also: /dots-dev:worktree-status (for detailed dashboard)"
  exit 0
fi

!REGISTRY_FILE=$(get_registry_file)

!echo "Git Worktrees:"
!echo ""
!git worktree list
!echo ""

# Show registry info if available
!if [ -f "$REGISTRY_FILE" ]; then
  REGISTRY_COUNT=$(jq 'length' "$REGISTRY_FILE" 2>/dev/null || echo "0")
  if [ "$REGISTRY_COUNT" -gt 0 ]; then
    echo "Registered worktrees with Claude sessions:"
    echo ""
    jq -r 'to_entries[] | "  \(.value.branch) - created \(.value.created) (tab: \(.value.tab_id))"' "$REGISTRY_FILE" 2>/dev/null
    echo ""
  fi
fi

!echo "Commands:"
!echo "  /dots-dev:worktree-create <branch>  - Create new worktree"
!echo "  /dots-dev:worktree-delete <name>    - Delete worktree"
!echo "  /dots-dev:worktree-cleanup          - Remove stale worktrees"
