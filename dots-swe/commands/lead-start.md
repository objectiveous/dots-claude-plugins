---
description: "Start Lead agent in new terminal for autonomous work orchestration"
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

# Lead Start - Launch Lead Agent

Starts the autonomous Lead agent in a new terminal window/tab. The Lead agent orchestrates SWE agents by dispatching work, monitoring progress, integrating completed code, and escalating blockers to humans.

**Usage:** `/dots-swe:lead-start [options]`

**Options:**
- `--dry-run, -n` - Show what would happen without starting
- `--help, -h` - Show this help

**What this does:**
- Checks if Lead agent is already running
- Acquires lock to prevent multiple instances
- Opens new terminal with Lead agent running
- Starts the continuous ASSESS → DISPATCH → MONITOR → INTEGRATE → ESCALATE loop

**Configuration (Environment Variables):**
- `SWE_MAX_PARALLEL=3` - Max concurrent SWE agents
- `SWE_LOOP_INTERVAL=60` - Seconds between cycles
- `SWE_STALL_MINUTES=30` - Minutes of inactivity = stall
- `SWE_AUTO_INTEGRATE=true` - Auto-merge completed work

**Escalation Types (Desktop Notifications):**
- **BLOCKER** - SWE marked bead as blocked
- **STALL** - No activity for 30+ minutes
- **CONFLICT** - Merge conflict during integration
- **TEST_FAILURE** - Integration tests failed
- **CRASH** - Session died unexpectedly

**See also:**
- `/dots-swe:lead-status` - Check Lead agent state
- `/dots-swe:lead-stop` - Stop Lead agent gracefully
- `/dots-swe:status` - View overall work status

## Implementation

!source "$(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)/lead-lib.sh"
!source "$(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)/swe-lib.sh"

# Parse flags
!DRY_RUN=false
!if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
  DRY_RUN=true
fi

!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:lead-start [options]"
  echo ""
  echo "Start autonomous Lead agent for SWE orchestration"
  echo ""
  echo "Options:"
  echo "  --dry-run, -n    Show what would happen without starting"
  echo "  --help, -h       Show this help"
  echo ""
  echo "Configuration:"
  echo "  SWE_MAX_PARALLEL=${SWE_MAX_PARALLEL:-3}"
  echo "  SWE_LOOP_INTERVAL=${SWE_LOOP_INTERVAL:-60}s"
  echo "  SWE_STALL_MINUTES=${SWE_STALL_MINUTES:-30}min"
  echo "  SWE_AUTO_INTEGRATE=${SWE_AUTO_INTEGRATE:-true}"
  echo ""
  echo "What happens:"
  echo "  • Check if Lead already running"
  echo "  • Acquire lock"
  echo "  • Open new terminal with Lead agent"
  echo "  • Start continuous orchestration loop"
  echo ""
  echo "See also:"
  echo "  /dots-swe:lead-status    Check Lead state"
  echo "  /dots-swe:lead-stop      Stop Lead agent"
  exit 0
fi

!echo "═══════════════════════════════════════════"
!echo "LEAD AGENT STARTUP"
!echo "═══════════════════════════════════════════"
!echo ""

# Initialize state
!ensure_lead_state_dir
!init_lead_state

# Check if Lead is already running
!if is_lead_running; then
  EXISTING_PID=$(get_lead_state "pid")
  STARTED_AT=$(get_lead_state "started_at")
  echo "ERROR: Lead agent is already running"
  echo ""
  echo "PID:        $EXISTING_PID"
  echo "Started:    $(format_timestamp "$STARTED_AT")"
  echo ""
  echo "To stop:    /dots-swe:lead-stop"
  echo "To check:   /dots-swe:lead-status"
  exit 1
fi

# Show configuration
!echo "Configuration:"
!echo "  Max parallel:    ${SWE_MAX_PARALLEL:-3}"
!echo "  Loop interval:   ${SWE_LOOP_INTERVAL:-60}s"
!echo "  Stall threshold: ${SWE_STALL_MINUTES:-30}min"
!echo "  Auto-integrate:  ${SWE_AUTO_INTEGRATE:-true}"
!echo ""

# Dry run mode
!if [ "$DRY_RUN" = true ]; then
  echo "📋 DRY RUN: Here's what would happen"
  echo ""
  echo "1. Acquire lock file"
  echo "   Location: $(get_lead_lock_file)"
  echo ""
  echo "2. Initialize state"
  echo "   Location: $(get_lead_state_file)"
  echo ""
  echo "3. Open new terminal with Lead agent"
  TERMINAL=$(get_swe_terminal)
  if [ "$TERMINAL" = "ghostty" ]; then
    echo "   Terminal: Ghostty (new tab)"
    echo "   Session: zmx run lead-agent"
  else
    echo "   Terminal: iTerm (new window)"
    echo "   Session: tmux (lead)"
  fi
  echo ""
  echo "4. Start continuous loop:"
  echo "   ASSESS → DISPATCH → MONITOR → INTEGRATE → ESCALATE"
  echo ""
  echo "5. Desktop notifications will be sent for:"
  echo "   • BLOCKER - Bead marked as blocked"
  echo "   • STALL - No activity for ${SWE_STALL_MINUTES:-30}min"
  echo "   • CONFLICT - Merge conflict"
  echo "   • TEST_FAILURE - Tests failed during integration"
  echo "   • CRASH - Session died"
  echo ""
  echo "Run without --dry-run to start"
  exit 0
fi

# Acquire lock
!if ! acquire_lead_lock; then
  echo "ERROR: Could not acquire lock"
  echo "Another Lead agent may be starting up"
  exit 1
fi

!echo "✅ Lock acquired"
!echo ""

# Get terminal type
!TERMINAL=$(get_swe_terminal)

# Create startup script that will run in new terminal
!LEAD_SCRIPT="$SWE_LEAD_STATE_DIR/lead-loop.sh"
!cat > "$LEAD_SCRIPT" <<'LEAD_EOF'
#!/bin/bash

# Source libraries
source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/lead-lib.sh 2>/dev/null | head -1)"
source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

# Update state to running
update_lead_state "status" "running"
update_lead_state "pid" "$$"
update_lead_state "started_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Graceful shutdown handler
shutdown_lead() {
  echo ""
  echo "═══════════════════════════════════════════"
  echo "LEAD AGENT SHUTDOWN"
  echo "═══════════════════════════════════════════"
  update_lead_state "status" "stopped"
  update_lead_state "pid" "null"
  release_lead_lock
  echo "✅ Lead agent stopped"
  exit 0
}

trap shutdown_lead INT TERM

echo "═══════════════════════════════════════════"
echo "LEAD AGENT STARTED"
echo "═══════════════════════════════════════════"
echo ""
echo "PID:             $$"
echo "Max parallel:    ${SWE_MAX_PARALLEL:-3}"
echo "Loop interval:   ${SWE_LOOP_INTERVAL:-60}s"
echo "Stall threshold: ${SWE_STALL_MINUTES:-30}min"
echo "Auto-integrate:  ${SWE_AUTO_INTEGRATE:-true}"
echo ""
echo "Press Ctrl+C to stop gracefully"
echo ""

# Main loop
while true; do
  # Check for stop signal
  if [ -f "$HOME/.claude/swe-lead/stop" ]; then
    rm -f "$HOME/.claude/swe-lead/stop"
    shutdown_lead
  fi

  # Update last cycle timestamp
  update_lead_state "last_cycle" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  echo "═══════════════════════════════════════════"
  echo "LEAD CYCLE $(date +%H:%M:%S)"
  echo "═══════════════════════════════════════════"

  # PHASE 1: ASSESS
  ACTIVE_COUNT=$(get_active_session_count)
  READY_BEADS=$(get_dispatchable_beads 2>/dev/null || echo "")
  INTEGRATION_READY=$(get_integration_ready_beads 2>/dev/null || echo "")
  READY_COUNT=$(echo "$READY_BEADS" | grep -c . || echo "0")
  INTEGRATION_COUNT=$(echo "$INTEGRATION_READY" | grep -c . || echo "0")
  CAPACITY=$(( ${SWE_MAX_PARALLEL:-3} - ACTIVE_COUNT ))

  echo "Active sessions: $ACTIVE_COUNT / ${SWE_MAX_PARALLEL:-3}"
  echo "Ready work:      $READY_COUNT"
  echo "Integration:     $INTEGRATION_COUNT"
  echo "Capacity:        $CAPACITY"

  # PHASE 2: DISPATCH
  if [ "$CAPACITY" -gt 0 ] && [ "$READY_COUNT" -gt 0 ]; then
    echo ""
    echo "DISPATCH:"
    # Note: Actual dispatching would use Claude with Skill tool
    # For now, just report what we would dispatch
    echo "$READY_BEADS" | head -n "$CAPACITY" | while read -r bead_id; do
      if [ -n "$bead_id" ]; then
        echo "  📋 Ready to dispatch: $bead_id"
        echo "     (Run: /dots-swe:dispatch $bead_id)"
      fi
    done
  fi

  # PHASE 3: MONITOR
  ACTIVE_SESSIONS=$(get_active_sessions)
  if [ "$ACTIVE_COUNT" -gt 0 ]; then
    echo ""
    echo "MONITOR:"
    echo "$ACTIVE_SESSIONS" | jq -r 'to_entries[] | .key' | while read -r bead_id; do
      if [ -n "$bead_id" ]; then
        WORKTREE_PATH=$(echo "$ACTIVE_SESSIONS" | jq -r --arg b "$bead_id" '.[$b].worktree_path')

        # Check if worktree exists
        if [ ! -d "$WORKTREE_PATH" ]; then
          echo "  💥 $bead_id - CRASH (worktree gone)"
          send_notification "CRASH" "$bead_id" "Worktree no longer exists"
          unregister_active_session "$bead_id"
          continue
        fi

        # Detect activity
        if detect_session_activity "$bead_id" "$WORKTREE_PATH"; then
          echo "  ✓ $bead_id - active"
        elif is_session_stalled "$bead_id"; then
          echo "  ⏸  $bead_id - STALLED"
          send_notification "STALL" "$bead_id" "No activity for ${SWE_STALL_MINUTES:-30} minutes"
        else
          echo "  • $bead_id - quiet"
        fi

        # Check if blocked
        if is_bead_blocked "$bead_id"; then
          echo "  🚫 $bead_id - BLOCKED"
          send_notification "BLOCKER" "$bead_id" "Bead marked as blocked"
        fi
      fi
    done
  fi

  # PHASE 4: INTEGRATE
  if [ "${SWE_AUTO_INTEGRATE:-true}" = "true" ] && [ "$INTEGRATION_COUNT" -gt 0 ]; then
    echo ""
    echo "INTEGRATE:"
    echo "$INTEGRATION_READY" | while read -r bead_id; do
      if [ -n "$bead_id" ]; then
        echo "  🔀 Ready to integrate: $bead_id"
        echo "     (Run: /dots-swe:code-integrate $bead_id)"
      fi
    done
  fi

  # Sleep
  echo ""
  echo "Next cycle in ${SWE_LOOP_INTERVAL:-60}s..."
  sleep "${SWE_LOOP_INTERVAL:-60}"
done
LEAD_EOF

!chmod +x "$LEAD_SCRIPT"

!echo "Starting Lead agent in new terminal..."
!echo ""

# Open in new terminal based on terminal type
!if [ "$TERMINAL" = "ghostty" ]; then
  # Open Ghostty tab with Lead agent
  MODE="${SWE_GHOSTTY_MODE:-tab}"
  if [ "$MODE" = "tab" ]; then
    osascript 2>/dev/null <<APPLESCRIPT
tell application "ghostty"
    activate
end tell
delay 0.2
tell application "System Events"
    tell process "ghostty"
        keystroke "t" using command down
        delay 0.3
        keystroke "printf '\\\\033]0;lead-agent\\\\007' && $LEAD_SCRIPT"
        keystroke return
    end tell
end tell
APPLESCRIPT
  else
    open -na Ghostty --args --title="lead-agent" -e "$LEAD_SCRIPT"
  fi
else
  # Open iTerm window with Lead agent
  osascript 2>/dev/null <<APPLESCRIPT
tell application "iTerm2"
    activate
    create window with default profile
    tell current session of current window
        write text "$LEAD_SCRIPT"
    end tell
end tell
APPLESCRIPT
fi

!echo "✅ Lead agent started in new terminal"
!echo ""
!echo "Monitor status:  /dots-swe:lead-status"
!echo "Stop agent:      /dots-swe:lead-stop"
!echo ""
!echo "Desktop notifications will be sent for:"
!echo "  • BLOCKER - Bead marked as blocked"
!echo "  • STALL - No activity for ${SWE_STALL_MINUTES:-30}min"
!echo "  • CONFLICT - Merge conflict"
!echo "  • TEST_FAILURE - Tests failed"
!echo "  • CRASH - Session died"
