---
description: "Show Lead agent status and active orchestration state"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Display the complete output EXACTLY as-is to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, display the complete output EXACTLY as-is to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- DO NOT summarize or interpret the output - show the complete report as-is
</claude-instructions>

# Lead Status - Check Lead Agent State

Shows the current state of the Lead agent including running status, active sessions, recent escalations, and configuration.

**Usage:** `/dots-swe:lead-status`

**Shows:**
- **Status** - Running or stopped, PID, uptime
- **Active Sessions** - SWE agents currently working
- **Configuration** - Current settings
- **Recent Escalations** - Last 10 notifications sent
- **Work Queue** - Pending dispatchable work
- **Integration Queue** - Completed work ready to merge

**See also:**
- `/dots-swe:lead-start` - Start Lead agent
- `/dots-swe:lead-stop` - Stop Lead agent
- `/dots-swe:status` - Overall work status

## Implementation

!source "$(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)/lead-lib.sh"

!echo "═══════════════════════════════════════════"
!echo "LEAD AGENT STATUS"
!echo "═══════════════════════════════════════════"
!echo ""

# Initialize state if needed
!ensure_lead_state_dir
!if [ ! -f "$(get_lead_state_file)" ]; then
  init_lead_state
fi

# Get state
!STATUS=$(get_lead_state "status")
!PID=$(get_lead_state "pid")
!STARTED_AT=$(get_lead_state "started_at")
!LAST_CYCLE=$(get_lead_state "last_cycle")

# Check if really running
!if [ "$STATUS" = "running" ] && [ "$PID" != "null" ] && [ -n "$PID" ]; then
  if kill -0 "$PID" 2>/dev/null; then
    RUNNING=true
  else
    # Process died but state not updated
    RUNNING=false
    update_lead_state "status" "stopped"
    STATUS="stopped"
  fi
else
  RUNNING=false
fi

# Show status
!echo "Status:       $STATUS"
!if [ "$RUNNING" = true ]; then
  echo "PID:          $PID"
  STARTED_FMT=$(format_timestamp "$STARTED_AT")
  echo "Started:      $STARTED_FMT"

  if [ "$LAST_CYCLE" != "null" ] && [ -n "$LAST_CYCLE" ]; then
    LAST_CYCLE_FMT=$(format_timestamp "$LAST_CYCLE")
    MINUTES_AGO=$(time_diff_minutes "$LAST_CYCLE")
    echo "Last cycle:   $LAST_CYCLE_FMT (${MINUTES_AGO}m ago)"
  fi

  # Calculate uptime
  if [ "$STARTED_AT" != "null" ] && [ -n "$STARTED_AT" ]; then
    UPTIME_MIN=$(time_diff_minutes "$STARTED_AT")
    UPTIME_HOURS=$(( UPTIME_MIN / 60 ))
    UPTIME_REMAIN=$(( UPTIME_MIN % 60 ))
    if [ "$UPTIME_HOURS" -gt 0 ]; then
      echo "Uptime:       ${UPTIME_HOURS}h ${UPTIME_REMAIN}m"
    else
      echo "Uptime:       ${UPTIME_MIN}m"
    fi
  fi
else
  echo "PID:          (not running)"
  if [ "$STARTED_AT" != "null" ] && [ -n "$STARTED_AT" ]; then
    STOPPED_FMT=$(format_timestamp "$STARTED_AT")
    echo "Last run:     $STOPPED_FMT"
  fi
fi

!echo ""

# Configuration
!echo "Configuration:"
!echo "  Max parallel:    ${SWE_MAX_PARALLEL:-3}"
!echo "  Loop interval:   ${SWE_LOOP_INTERVAL:-60}s"
!echo "  Stall threshold: ${SWE_STALL_MINUTES:-30}min"
!echo "  Auto-integrate:  ${SWE_AUTO_INTEGRATE:-true}"
!echo ""

# Active sessions
!ACTIVE_COUNT=$(get_active_session_count)
!ACTIVE_SESSIONS=$(get_active_sessions)

!echo "Active Sessions: $ACTIVE_COUNT"
!if [ "$ACTIVE_COUNT" -gt 0 ]; then
  echo ""
  echo "$ACTIVE_SESSIONS" | jq -r 'to_entries[] | "  • \(.key)\n    Started: \(.value.started_at)\n    Last activity: \(.value.last_activity)\n    Path: \(.value.worktree_path)"'
else
  echo "  (none)"
fi

!echo ""

# Work queue
!READY_BEADS=$(get_dispatchable_beads 2>/dev/null || echo "")
!READY_COUNT=$(echo "$READY_BEADS" | grep -c . || echo "0")

!echo "Dispatchable Work: $READY_COUNT"
!if [ "$READY_COUNT" -gt 0 ]; then
  echo "$READY_BEADS" | head -5 | while read -r bead_id; do
    if [ -n "$bead_id" ]; then
      echo "  • $bead_id"
    fi
  done
  if [ "$READY_COUNT" -gt 5 ]; then
    REMAINING=$(( READY_COUNT - 5 ))
    echo "  ... and $REMAINING more"
  fi
else
  echo "  (none)"
fi

!echo ""

# Integration queue
!INTEGRATION_READY=$(get_integration_ready_beads 2>/dev/null || echo "")
!INTEGRATION_COUNT=$(echo "$INTEGRATION_READY" | grep -c . || echo "0")

!echo "Ready to Integrate: $INTEGRATION_COUNT"
!if [ "$INTEGRATION_COUNT" -gt 0 ]; then
  echo "$INTEGRATION_READY" | while read -r bead_id; do
    if [ -n "$bead_id" ]; then
      echo "  • $bead_id"
    fi
  done
else
  echo "  (none)"
fi

!echo ""

# Recent escalations
!STATE_FILE=$(get_lead_state_file)
!ESCALATIONS=$(jq -r '.escalations // [] | .[-10:] | reverse | .[] | "[\(.timestamp | split("T")[0]) \(.timestamp | split("T")[1] | split("Z")[0])] \(.type) - \(.title)"' "$STATE_FILE" 2>/dev/null || echo "")

!echo "Recent Escalations (last 10):"
!if [ -n "$ESCALATIONS" ]; then
  echo "$ESCALATIONS" | while IFS= read -r line; do
    if [ -n "$line" ]; then
      echo "  $line"
    fi
  done
else
  echo "  (none)"
fi

!echo ""

# Quick actions
!if [ "$RUNNING" = true ]; then
  echo "Actions:"
  echo "  /dots-swe:lead-stop     Stop Lead agent"
  echo "  /dots-swe:status        View overall work status"
else
  echo "Actions:"
  echo "  /dots-swe:lead-start    Start Lead agent"
  echo "  /dots-swe:status        View overall work status"
fi
