---
description: "Stop Lead agent gracefully"
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

# Lead Stop - Stop Lead Agent

Gracefully stops the running Lead agent. The agent will complete its current cycle and shut down cleanly.

**Usage:** `/dots-swe:lead-stop [options]`

**Options:**
- `--force, -f` - Force stop immediately (send SIGTERM)
- `--help, -h` - Show this help

**What this does:**
- Checks if Lead agent is running
- Sends stop signal (graceful by default, force with --force)
- Releases lock and updates state
- Active SWE agent sessions continue running independently

**Note:** Stopping the Lead agent does NOT stop active SWE agent sessions. Those will continue working and can be monitored manually.

**See also:**
- `/dots-swe:lead-start` - Start Lead agent
- `/dots-swe:lead-status` - Check Lead agent state

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/lead-lib.sh 2>/dev/null | head -1)"

# Parse flags
!FORCE=false
!if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
  FORCE=true
fi

!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:lead-stop [options]"
  echo ""
  echo "Stop Lead agent gracefully"
  echo ""
  echo "Options:"
  echo "  --force, -f      Force stop immediately (SIGTERM)"
  echo "  --help, -h       Show this help"
  echo ""
  echo "Graceful stop:"
  echo "  • Waits for current cycle to complete"
  echo "  • Updates state to stopped"
  echo "  • Releases lock"
  echo "  • Active SWE sessions continue running"
  echo ""
  echo "Force stop:"
  echo "  • Sends SIGTERM immediately"
  echo "  • Cleans up state and lock"
  echo ""
  echo "See also:"
  echo "  /dots-swe:lead-start     Start Lead agent"
  echo "  /dots-swe:lead-status    Check Lead state"
  exit 0
fi

!echo "═══════════════════════════════════════════"
!echo "LEAD AGENT SHUTDOWN"
!echo "═══════════════════════════════════════════"
!echo ""

# Initialize state if needed
!ensure_lead_state_dir
!if [ ! -f "$(get_lead_state_file)" ]; then
  init_lead_state
fi

# Check if Lead is running
!if ! is_lead_running; then
  echo "Lead agent is not running"
  echo ""
  echo "Current status: $(get_lead_state "status")"
  echo ""
  echo "To start: /dots-swe:lead-start"
  exit 0
fi

# Get PID
!PID=$(get_lead_state "pid")
!STARTED_AT=$(get_lead_state "started_at")

!echo "Found running Lead agent:"
!echo "  PID:     $PID"
!echo "  Started: $(format_timestamp "$STARTED_AT")"
!echo ""

# Stop based on mode
!if [ "$FORCE" = true ]; then
  echo "Force stopping (SIGTERM)..."
  if kill -TERM "$PID" 2>/dev/null; then
    echo "✅ SIGTERM sent to process $PID"

    # Wait a moment for process to exit
    sleep 1

    # Check if process is gone
    if ! kill -0 "$PID" 2>/dev/null; then
      echo "✅ Process terminated"
    else
      echo "⚠️  Process still running, may take a moment to exit"
    fi
  else
    echo "⚠️  Could not send signal (process may have already exited)"
  fi

  # Clean up state
  update_lead_state "status" "stopped"
  update_lead_state "pid" "null"
  release_lead_lock

  echo "✅ State cleaned up"
else
  echo "Sending graceful stop signal..."

  # Create stop file
  touch "$HOME/.claude/swe-lead/stop"

  echo "✅ Stop signal sent"
  echo ""
  echo "The Lead agent will:"
  echo "  1. Complete current cycle"
  echo "  2. Update state to stopped"
  echo "  3. Release lock and exit"
  echo ""
  echo "This may take up to ${SWE_LOOP_INTERVAL:-60}s"
  echo ""
  echo "To force stop immediately: /dots-swe:lead-stop --force"
  echo "To check status: /dots-swe:lead-status"
fi

!echo ""

# Show active sessions
!ACTIVE_COUNT=$(get_active_session_count)
!if [ "$ACTIVE_COUNT" -gt 0 ]; then
  echo "⚠️  Note: $ACTIVE_COUNT active SWE session(s) will continue running"
  echo ""
  ACTIVE_SESSIONS=$(get_active_sessions)
  echo "$ACTIVE_SESSIONS" | jq -r 'to_entries[] | "  • \(.key)"'
  echo ""
  echo "These sessions are independent and must be stopped separately"
  echo "Use /dots-swe:delete <bead-id> to clean up sessions"
fi
