---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(osascript:*)
description: Delete git worktrees and clean up branches
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Delete Git Worktrees

Deletes specified worktrees, closes associated iTerm tabs, and cleans up branches.

**Usage:** `/dots-swe:worktree-delete <name1> [name2] [...]`

**Examples:**
```bash
/dots-swe:worktree-delete feature/auth
/dots-swe:worktree-delete feature/api feature/ui
```

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

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
