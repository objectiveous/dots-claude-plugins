---
description: "Create git worktrees with parallel Claude sessions in iTerm"
allowed-tools: ["Bash"]
---

# Create Git Worktrees

Creates one or more git worktrees in `.worktrees/` directory and opens Claude sessions in iTerm tabs.

**Usage:** `/dots-dev:worktree-create <branch1> [branch2] [...]`

**Behavior:**
- Uses existing branch if found (local or origin)
- Creates new branch from current branch if not found
- Opens iTerm tab with Claude session for each worktree
- Registers worktrees in global registry for tracking

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-create <branch1> [branch2] [...]"
  echo ""
  echo "Create git worktrees and open Claude sessions in iTerm tabs."
  echo ""
  echo "Arguments:"
  echo "  <branch>    Branch name(s) to create worktrees for"
  echo ""
  echo "Behavior:"
  echo "  - Uses existing branch if found (local or origin)"
  echo "  - Creates new branch from current branch if not found"
  echo "  - Opens iTerm tab with Claude session for each worktree"
  echo "  - Registers worktrees in ~/.claude/worktree-registry.json"
  echo ""
  echo "Examples:"
  echo "  /dots-dev:worktree-create feature/auth"
  echo "  /dots-dev:worktree-create feature/api feature/ui"
  echo ""
  echo "See also: /dots-dev:worktree-from-bead, /dots-dev:worktree-list"
  exit 0
fi

!CURRENT_BRANCH=$(git branch --show-current)
!REPO_ROOT=$(get_repo_root)
!WORKTREES_DIR=$(get_worktrees_dir)

# Validate arguments
!if [ $# -eq 0 ]; then
  echo "Usage: /dots-dev:worktree-create <branch1> [branch2] [...]"
  echo ""
  echo "Creates worktrees and opens Claude sessions in iTerm tabs."
  echo "Use --help for more information."
  exit 1
fi

!echo "Creating worktrees from branch: $CURRENT_BRANCH"
!echo "Worktrees directory: $WORKTREES_DIR"
!echo "Branches: $@"

# Ensure worktrees directory exists
!ensure_worktrees_dir

# Validate no existing worktrees conflict
!validate_no_existing_worktrees "$WORKTREES_DIR" "$@" || exit 1

# Create worktrees
!create_worktrees "$CURRENT_BRANCH" "$WORKTREES_DIR" "$@" || exit 1

# Open iTerm tabs and register worktrees
!open_and_register_worktrees "$WORKTREES_DIR" "$@"

!echo ""
!echo "Worktrees created:"
!git worktree list

!echo ""
!echo "iTerm tabs opened with Claude sessions."
