---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*), Bash(wc:*)
description: Dashboard showing all worktrees with git status and bead info
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Worktree Status Dashboard

Shows all git worktrees with their current state: git status, active bead, uncommitted changes.

**Usage:** `/dots-swe:worktree-status`

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                  Worktree Dashboard                          ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!REPO_ROOT=$(get_repo_root)
!COUNT=0

# Get all worktrees
!git worktree list --porcelain | while IFS= read -r line; do
  case "$line" in
    worktree*)
      WORKTREE_PATH="${line#worktree }"
      # Skip main repo
      if [ "$WORKTREE_PATH" != "$REPO_ROOT" ]; then
        COUNT=$((COUNT + 1))

        # Get branch
        BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "detached")

        # Get status
        UNCOMMITTED=$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        STAGED=$(git -C "$WORKTREE_PATH" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        UNPUSHED=$(git -C "$WORKTREE_PATH" log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')

        # Check for bead
        BEAD=""
        if [ -f "$WORKTREE_PATH/.swe-bead" ]; then
          BEAD=$(cat "$WORKTREE_PATH/.swe-bead")
        fi

        # Get registry info
        CREATED=$(get_worktree_info "$WORKTREE_PATH" "created")

        # Display worktree info
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Branch: $BRANCH"
        echo "Path: $WORKTREE_PATH"

        if [ "$UNCOMMITTED" -gt 0 ]; then
          echo "Status: 🔴 Dirty ($UNCOMMITTED changes, $STAGED staged)"
        else
          echo "Status: ✅ Clean"
        fi

        if [ "$UNPUSHED" -gt 0 ]; then
          echo "Unpushed: $UNPUSHED commits"
        fi

        if [ -n "$BEAD" ]; then
          echo "Bead: $BEAD"
        fi

        if [ -n "$CREATED" ]; then
          echo "Created: $CREATED"
        fi

        echo ""
      fi
      ;;
  esac
done

!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!WORKTREE_COUNT=$(git worktree list | grep -v "$(get_repo_root)" | wc -l | tr -d ' ')
!echo "Total worktrees: $WORKTREE_COUNT"
!echo ""
!echo "Helpful commands:"
!echo "  /dots-swe:worktree-sync <name>   - Sync with main"
!echo "  /dots-swe:worktree-delete <name> - Delete worktree"
!echo "  /dots-swe:work <bead-id>         - Start work from bead"
!echo "  /dots-swe:ship                   - Run ship protocol"
