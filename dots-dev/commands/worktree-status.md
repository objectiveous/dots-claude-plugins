---
description: "Dashboard showing all worktrees with git status and bead info"
allowed-tools: ["Bash"]
---

# Worktree Status Dashboard

Shows all git worktrees with their current state: git status, active bead, uncommitted changes.

**Usage:** `/dots-dev:worktree-status`

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-status"
  echo ""
  echo "Dashboard showing all worktrees with their current state."
  echo ""
  echo "For each worktree, shows:"
  echo "  - Branch name and path"
  echo "  - Uncommitted changes count"
  echo "  - Unpushed commits count"
  echo "  - Associated bead (from .claude-bead or branch name)"
  echo "  - Creation timestamp"
  echo ""
  echo "See also: /dots-dev:worktree-list (simpler view)"
  exit 0
fi

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                   Worktree Status Dashboard                  ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!REPO_ROOT=$(get_repo_root)

# Get all worktrees
!git worktree list --porcelain | while read line; do
  if [[ "$line" == worktree* ]]; then
    WORKTREE_PATH="${line#worktree }"

    # Skip the main worktree
    if [ "$WORKTREE_PATH" = "$REPO_ROOT" ]; then
      continue
    fi

    # Get branch name
    BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "detached")

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📁 $BRANCH"
    echo "   Path: $WORKTREE_PATH"

    # Git status summary
    CHANGES=$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    STAGED=$(git -C "$WORKTREE_PATH" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNPUSHED=$(git -C "$WORKTREE_PATH" log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')

    if [ "$CHANGES" -gt 0 ]; then
      echo "   📝 $CHANGES uncommitted changes ($STAGED staged)"
    else
      echo "   ✅ Clean working tree"
    fi

    if [ "$UNPUSHED" -gt 0 ]; then
      echo "   ⬆️  $UNPUSHED commits to push"
    fi

    # Check for active bead (look for bead ID in branch name or .claude-bead file)
    if [ -f "$WORKTREE_PATH/.claude-bead" ]; then
      BEAD_ID=$(cat "$WORKTREE_PATH/.claude-bead")
      echo "   🔮 Bead: $BEAD_ID"
    elif [[ "$BRANCH" =~ (dots-[a-z0-9]+) ]]; then
      echo "   🔮 Bead (from branch): ${BASH_REMATCH[1]}"
    fi

    # Check registry for session info
    REGISTRY_FILE=$(get_registry_file)
    if [ -f "$REGISTRY_FILE" ]; then
      TAB_ID=$(jq -r --arg path "$WORKTREE_PATH" '.[$path].tab_id // ""' "$REGISTRY_FILE" 2>/dev/null)
      CREATED=$(jq -r --arg path "$WORKTREE_PATH" '.[$path].created // ""' "$REGISTRY_FILE" 2>/dev/null)
      if [ -n "$CREATED" ]; then
        echo "   🕐 Created: $CREATED"
      fi
    fi

    echo ""
  fi
done

# Summary
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!WORKTREE_COUNT=$(git worktree list | wc -l | tr -d ' ')
!echo "Total worktrees: $WORKTREE_COUNT (including main)"
!echo ""
!echo "Commands: /dots-dev:worktree-sync, /dots-dev:worktree-merge, /dots-dev:doctor"
