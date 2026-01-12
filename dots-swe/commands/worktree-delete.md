---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(osascript:*)
description: Delete git worktrees and clean up branches
---

# Delete Git Worktrees

Deletes specified worktrees, closes associated iTerm tabs, and cleans up branches.

**Usage:** `/dots-swe:worktree-delete <name1> [name2] [...]`

**Examples:**
```bash
/dots-swe:worktree-delete feature/auth
/dots-swe:worktree-delete feature/api feature/ui
```

## Implementation

!source "*/scripts/swe-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:worktree-delete <name1> [name2] [...]"
  echo ""
  echo "Deletes worktrees, closes iTerm tabs, and removes branches."
  echo ""
  echo "Examples:"
  echo "  /dots-swe:worktree-delete feature/auth"
  echo "  /dots-swe:worktree-delete feature/api feature/ui"
  exit 0
fi

# Validate arguments
!if [ $# -eq 0 ]; then
  echo "ERROR: No worktree names provided"
  echo ""
  echo "Usage: /dots-swe:worktree-delete <name1> [name2] [...]"
  echo ""
  echo "Available worktrees:"
  git worktree list
  exit 1
fi

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                  Deleting Worktrees                          ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

# Delete worktrees using library function
!delete_worktrees "$@"

!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Remaining worktrees:"
!echo ""
!git worktree list
