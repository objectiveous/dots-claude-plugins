---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*)
description: List all git worktrees in the current repository
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# List Git Worktrees

Shows all git worktrees for the current repository with their status.

**Usage:** `/dots-swe:worktree-list`

## Implementation

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                    Git Worktrees                             ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!if git worktree list > /dev/null 2>&1; then
  git worktree list
else
  echo "No worktrees found"
fi

!echo ""
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Registry Info"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""

!if [ -f "$HOME/.claude/swe-registry.json" ]; then
  REGISTRY_ENTRIES=$(jq -r 'to_entries | length' "$HOME/.claude/swe-registry.json" 2>/dev/null)
  if [ "$REGISTRY_ENTRIES" -gt 0 ]; then
    jq -r 'to_entries[] | "  \(.value.branch) - created \(.value.created) (tab: \(.value.tab_id))"' "$HOME/.claude/swe-registry.json"
  else
    echo "  No registered worktrees"
  fi
else
  echo "  No registry file found"
fi

!echo ""
!echo "Helpful commands:"
!echo "  /dots-swe:worktree-create <branch> - Create new worktree"
!echo "  /dots-swe:worktree-delete <name>   - Delete worktree"
!echo "  /dots-swe:worktree-status          - Show worktree dashboard"
!echo "  /dots-swe:work <bead-id>           - Start work from bead"
