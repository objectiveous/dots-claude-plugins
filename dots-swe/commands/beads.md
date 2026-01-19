---
allowed-tools: Bash(bd:*), Bash(cat:*)
description: Show available work and beads command reference
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Report the complete output to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, report the complete output to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- Report the complete output without summarizing
</claude-instructions>

# Beads - Available Work

Shows available work from beads and provides a quick reference for beads commands.

**Usage:** `/dots-swe:beads`

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                   Available Work (Beads)                     ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

# Show current bead if in a worktree
!CURRENT_BEAD=$(get_current_bead)
!if [ -n "$CURRENT_BEAD" ]; then
  echo "Current bead: $CURRENT_BEAD"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# Show available work
!echo "Available work:"
!echo ""
!bd ready 2>/dev/null || echo "  (bd command not available - is beads installed?)"
!echo ""

!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Quick Reference"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""
!echo "Start work:"
!echo "  /dots-swe:work <bead-id>     - Create worktree and claim bead"
!echo ""
!echo "View beads:"
!echo "  bd ready                     - List available work"
!echo "  bd show <id>                 - Show bead details"
!echo "  bd list --status=<status>    - List beads by status"
!echo ""
!echo "Update beads:"
!echo "  bd update <id> --status=in_progress      - Mark as in progress"
!echo "  bd update <id> --status=blocked          - Mark as blocked"
!echo "  bd label add <id> swe:code-complete               - Mark code complete"
!echo "  bd comment <id> \"message\"                - Add comment"
!echo "  bd close <id>                            - Close bead"
!echo ""
!echo "Create beads:"
!echo "  bd create --title=\"title\" --type=<type>  - Create new bead"
!echo "  bd create --interactive                  - Interactive creation"
!echo ""
!echo "Sync:"
!echo "  bd sync --message \"chore: sync beads database\" - Sync with git"
!echo ""
!echo "Squash commits before merge:"
!echo "  git rebase -i main           - Squash into logical commits"
