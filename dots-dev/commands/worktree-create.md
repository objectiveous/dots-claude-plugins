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

!CURRENT_BRANCH=$(git branch --show-current)
!REPO_ROOT=$(get_repo_root)
!WORKTREES_DIR=$(get_worktrees_dir)

# Validate arguments
!if [ $# -eq 0 ]; then
  echo "Usage: /dots-dev:worktree-create <branch1> [branch2] [...]"
  echo ""
  echo "Creates worktrees and opens Claude sessions in iTerm tabs."
  echo "Use /dots-dev:worktree-list to see existing worktrees."
  exit 1
fi

!echo "Creating worktrees from branch: $CURRENT_BRANCH"
!echo "Worktrees directory: $WORKTREES_DIR"
!echo "Branches: $@"

# Ensure worktrees directory exists
!ensure_worktrees_dir

# Validate no existing worktrees conflict
!for branch in "$@"; do
  WORKTREE_DIR="$WORKTREES_DIR/$branch"
  if [ -d "$WORKTREE_DIR" ]; then
    echo "ERROR: Worktree directory already exists: $WORKTREE_DIR"
    echo "Use /dots-dev:worktree-delete $branch to remove it first."
    exit 1
  fi
done

# Create worktrees
!for branch in "$@"; do
  BRANCH_NAME="$branch"
  WORKTREE_DIR="$WORKTREES_DIR/$branch"

  echo ""
  echo "Creating worktree: $WORKTREE_DIR"

  # Determine branch source
  BRANCH_STATUS=$(branch_exists "$BRANCH_NAME")

  case "$BRANCH_STATUS" in
    "local")
      echo "Using existing local branch: $BRANCH_NAME"
      git worktree add "$WORKTREE_DIR" "$BRANCH_NAME"
      ;;
    "remote")
      echo "Using existing remote branch: origin/$BRANCH_NAME"
      git worktree add "$WORKTREE_DIR" "$BRANCH_NAME"
      ;;
    *)
      echo "Creating new branch: $BRANCH_NAME (from $CURRENT_BRANCH)"
      git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$CURRENT_BRANCH"
      ;;
  esac

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create worktree for: $branch"
    exit 1
  fi
done

# Open iTerm tabs and register worktrees
!ensure_registry

!for branch in "$@"; do
  WORKTREE_DIR="$WORKTREES_DIR/$branch"
  ABS_PATH="$(cd "$WORKTREE_DIR" && pwd)"

  echo "Opening iTerm tab for: $branch"
  TAB_ID=$(open_iterm_claude_session "$WORKTREE_DIR")

  # Store tab ID locally
  echo "$TAB_ID" > "$WORKTREE_DIR/.claude-tab-id"

  # Register globally
  register_worktree "$ABS_PATH" "$branch" "$TAB_ID"
  echo "Registered worktree: $branch (tab ID: $TAB_ID)"
done

!echo ""
!echo "Worktrees created:"
!git worktree list

!echo ""
!echo "iTerm tabs opened with Claude sessions."
