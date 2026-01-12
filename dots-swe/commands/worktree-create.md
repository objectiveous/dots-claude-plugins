---
allowed-tools: Bash(git:*), Bash(mkdir:*), Bash(source:*), Bash(osascript:*), Bash(cat:*), Bash(jq:*), Bash(date:*)
description: Create git worktrees with Claude sessions in iTerm
execution-mode: atomic-bash
---

<claude-instructions>
CRITICAL: This skill spawns NEW sessions in worktrees. DO NOT work in the current directory.

1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output
4. Report the result to the user and STOP - work happens in the NEW sessions
5. NEVER continue working in the current directory after this skill runs
</claude-instructions>

# Create Git Worktrees

Creates one or more git worktrees in `.worktrees/` directory and spawns Claude sessions in iTerm tabs.

**Usage:** `/dots-swe:worktree-create <branch1> [branch2] [...]`

**Examples:**
```bash
/dots-swe:worktree-create feature/auth
/dots-swe:worktree-create feature/api feature/ui
```

## Context

- Current branch: !`git branch --show-current`
- Repository root: !`git rev-parse --show-toplevel`
- Existing worktrees: !`git worktree list`

## Implementation

!source "*/scripts/swe-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:worktree-create <branch1> [branch2] [...]"
  echo ""
  echo "Create git worktrees in .worktrees/ with Claude sessions in iTerm."
  echo ""
  echo "Examples:"
  echo "  /dots-swe:worktree-create feature/auth"
  echo "  /dots-swe:worktree-create feature/api feature/ui"
  echo ""
  echo "To start work from a bead, use: /dots-swe:work <bead-id>"
  exit 0
fi

# Validate arguments
!if [ $# -eq 0 ]; then
  echo "ERROR: No branch names provided"
  echo ""
  echo "Usage: /dots-swe:worktree-create <branch1> [branch2] [...]"
  echo ""
  echo "Tip: To start work from a bead, use /dots-swe:work <bead-id>"
  exit 1
fi

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                  Creating Worktrees                          ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

# Setup
!REPO_ROOT=$(get_repo_root)
!CURRENT_BRANCH=$(git branch --show-current)
!WORKTREES_DIR=$(get_worktrees_dir)

!echo "Repository: $REPO_ROOT"
!echo "Current branch: $CURRENT_BRANCH"
!echo "Worktrees directory: $WORKTREES_DIR"
!echo ""

# Ensure worktrees directory exists
!ensure_worktrees_dir

# Validate no existing worktrees
!if ! validate_no_existing_worktrees "$WORKTREES_DIR" "$@"; then
  exit 1
fi

# Create worktrees
!if ! create_worktrees "$CURRENT_BRANCH" "$WORKTREES_DIR" "$@"; then
  exit 1
fi

# Open iTerm tabs and register
!open_and_register_worktrees "$WORKTREES_DIR" "$@"

!echo ""
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "✅ Worktrees created and Claude sessions opened"
!echo ""
!echo "Current worktrees:"
!git worktree list
!echo ""
!echo "Tip: Use /dots-swe:worktree-list to see all worktrees"
