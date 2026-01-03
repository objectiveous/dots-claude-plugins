---
description: "Create a worktree from a bead ID with auto-context"
allowed-tools: ["Bash"]
---

# Create Worktree from Bead

Creates a worktree named after a bead, claims the bead, and sets up context for the servus agent.

**Usage:** `/dots-dev:worktree-from-bead <bead-id>`

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-from-bead <bead-id>"
  echo ""
  echo "Create a worktree from a bead with automatic context setup."
  echo ""
  echo "Arguments:"
  echo "  <bead-id>    The bead ID (e.g., dots-abc)"
  echo ""
  echo "Actions performed:"
  echo "  1. Verifies bead exists"
  echo "  2. Creates worktree with branch named after bead"
  echo "  3. Stores bead ID in .claude-bead file"
  echo "  4. Claims bead (marks as in_progress)"
  echo "  5. Opens iTerm tab with Claude session"
  echo ""
  echo "The servus agent will automatically detect the bead context."
  echo ""
  echo "Examples:"
  echo "  /dots-dev:worktree-from-bead dots-abc"
  exit 0
fi

!BEAD_ID="$1"

!if [ -z "$BEAD_ID" ]; then
  echo "Usage: /dots-dev:worktree-from-bead <bead-id>"
  echo "Use --help for more information."
  echo ""
  echo "Available beads:"
  bd ready 2>/dev/null || echo "(bd not available - install beads first)"
  exit 1
fi

# Verify bead exists
!echo "Checking bead: $BEAD_ID"
!BEAD_INFO=$(bd show "$BEAD_ID" --json 2>/dev/null)
!if [ -z "$BEAD_INFO" ] || [ "$BEAD_INFO" = "[]" ]; then
  echo "ERROR: Bead '$BEAD_ID' not found"
  echo ""
  echo "Available beads:"
  bd ready 2>/dev/null || bd list --status=open 2>/dev/null
  exit 1
fi

# Extract bead details
!BEAD_TITLE=$(echo "$BEAD_INFO" | jq -r '.[0].title // "untitled"')
!BEAD_TYPE=$(echo "$BEAD_INFO" | jq -r '.[0].type // "task"')
!BEAD_STATUS=$(echo "$BEAD_INFO" | jq -r '.[0].status // "open"')

!echo "Found: [$BEAD_TYPE] $BEAD_TITLE"
!echo "Status: $BEAD_STATUS"
!echo ""

# Create branch name from bead ID
!BRANCH_NAME="$BEAD_ID"
!WORKTREES_DIR=$(get_worktrees_dir)
!WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_NAME"

# Check if worktree already exists
!if [ -d "$WORKTREE_PATH" ]; then
  echo "Worktree already exists: $WORKTREE_PATH"
  echo ""
  echo "Opening existing worktree..."

  TAB_ID=$(open_iterm_claude_session "$WORKTREE_PATH")
  echo "Opened iTerm tab for: $BRANCH_NAME"
  exit 0
fi

# Ensure worktrees directory exists
!ensure_worktrees_dir

# Check if branch exists
!BRANCH_STATUS=$(branch_exists "$BRANCH_NAME")
!CURRENT_BRANCH=$(git branch --show-current)

!echo "Creating worktree: $WORKTREE_PATH"

!case "$BRANCH_STATUS" in
  "local")
    echo "Using existing local branch: $BRANCH_NAME"
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    ;;
  "remote")
    echo "Using existing remote branch: origin/$BRANCH_NAME"
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    ;;
  *)
    echo "Creating new branch: $BRANCH_NAME (from $CURRENT_BRANCH)"
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$CURRENT_BRANCH"
    ;;
esac

!if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create worktree"
  exit 1
fi

# Store bead ID in worktree for context
!echo "$BEAD_ID" > "$WORKTREE_PATH/.claude-bead"
!echo "Stored bead context: $WORKTREE_PATH/.claude-bead"

# Claim the bead
!echo ""
!echo "Claiming bead..."
!bd update "$BEAD_ID" --status=in_progress 2>/dev/null && echo "Marked $BEAD_ID as in_progress"

# Register and open iTerm tab
!ensure_registry
!ABS_PATH="$(cd "$WORKTREE_PATH" && pwd)"
!TAB_ID=$(open_iterm_claude_session "$WORKTREE_PATH")
!echo "$TAB_ID" > "$WORKTREE_PATH/.claude-tab-id"
!register_worktree "$ABS_PATH" "$BRANCH_NAME" "$TAB_ID"

!echo ""
!echo "✅ Worktree created from bead"
!echo ""
!echo "   Bead: $BEAD_ID [$BEAD_TYPE] $BEAD_TITLE"
!echo "   Path: $WORKTREE_PATH"
!echo "   Branch: $BRANCH_NAME"
!echo ""
!echo "iTerm tab opened with Claude session."
!echo "The servus agent will auto-detect the bead context."
