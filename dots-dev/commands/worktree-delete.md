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

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-delete <name1> [name2] [...]"
  echo ""
  echo "Delete git worktrees, close associated iTerm tabs, and clean up branches."
  echo ""
  echo "Arguments:"
  echo "  <name>    Worktree name(s) to delete"
  echo ""
  echo "Actions performed:"
  echo "  - Closes iTerm tab if registered"
  echo "  - Removes git worktree"
  echo "  - Deletes the branch"
  echo "  - Removes from registry"
  echo ""
  echo "Examples:"
  echo "  /dots-dev:worktree-delete feature/auth"
  echo "  /dots-dev:worktree-delete dots-abc dots-def"
  exit 0
fi

# Show available worktrees if no args
!if [ $# -eq 0 ]; then
  echo "Available worktrees:"
  echo ""
  git worktree list
  echo ""
  echo "Usage: /dots-dev:worktree-delete <name1> [name2] [...]"
  echo "Use --help for more information."
  exit 0
fi

# Process each worktree
!delete_worktrees "$@"

!echo "Remaining worktrees:"
!git worktree list
