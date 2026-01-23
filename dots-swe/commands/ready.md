---
allowed-tools: Bash(bd:*), Bash(cat:*)
description: Show truly dispatchable work (leaf tasks with no blockers)
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

# Ready - Dispatchable Work

Shows truly dispatchable work - leaf tasks with no open children and no blockers.

**Usage:** `/dots-swe:ready`

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                 Dispatchable Work (Ready)                    ║"
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

# Get all candidates from bd ready
!echo "Dispatchable work (leaf tasks only):"
!echo ""

# Filter out beads that have open children
!\(
  # Get all ready beads
  READY_BEADS=$(
    for type in task bug feature chore; do
      bd ready --type $type --limit 100 2>/dev/null
    done | grep -E '^\[|^[0-9]+\.' | sort -u
  )

  if [ -z "$READY_BEADS" ]; then
    echo "  No beads available"
  else
    # Process each bead and check if it has open children
    echo "$READY_BEADS" | while IFS= read -r line; do
      # Extract bead ID from the line (format: [P2] dots-abc · Title)
      BEAD_ID=$(echo "$line" | grep -oE '[a-z]+-[a-z0-9]+(\.[0-9]+)*')

      if [ -n "$BEAD_ID" ]; then
        # Check if this bead has open children
        HAS_CHILDREN=$(bd list --parent="$BEAD_ID" --status=open 2>/dev/null | grep -E '^\[|^[0-9]+\.' | wc -l | tr -d ' ')

        # Only show beads with no open children (leaf tasks)
        if [ "$HAS_CHILDREN" -eq 0 ]; then
          echo "$line"
        fi
      fi
    done | sort -u
  fi
\)

!echo ""
!echo "Use /dots-swe:dispatch <bead-id> to start work"
!echo ""
