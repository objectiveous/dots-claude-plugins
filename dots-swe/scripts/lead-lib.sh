#!/bin/bash
# Lead agent library - state management, notifications, and orchestration

# =============================================================================
# Configuration (Environment Variables)
# =============================================================================

# Max concurrent SWE agents
SWE_MAX_PARALLEL="${SWE_MAX_PARALLEL:-3}"

# Loop interval in seconds
SWE_LOOP_INTERVAL="${SWE_LOOP_INTERVAL:-60}"

# Stall detection threshold in minutes
SWE_STALL_MINUTES="${SWE_STALL_MINUTES:-30}"

# Auto-integrate completed work
SWE_AUTO_INTEGRATE="${SWE_AUTO_INTEGRATE:-true}"

# Lead state directory
SWE_LEAD_STATE_DIR="${HOME}/.claude/swe-lead"

# =============================================================================
# State Management
# =============================================================================

# Ensure state directory exists
ensure_lead_state_dir() {
  mkdir -p "$SWE_LEAD_STATE_DIR"
}

# Get state file path
get_lead_state_file() {
  echo "$SWE_LEAD_STATE_DIR/state.json"
}

# Get lock file path
get_lead_lock_file() {
  echo "$SWE_LEAD_STATE_DIR/lead.lock"
}

# Initialize lead state
init_lead_state() {
  ensure_lead_state_dir
  local state_file=$(get_lead_state_file)

  if [ ! -f "$state_file" ]; then
    cat > "$state_file" <<EOF
{
  "status": "stopped",
  "started_at": null,
  "pid": null,
  "active_sessions": {},
  "last_cycle": null,
  "escalations": []
}
EOF
  fi
}

# Update lead state
# Usage: update_lead_state <field> <value>
update_lead_state() {
  local field="$1"
  local value="$2"
  local state_file=$(get_lead_state_file)

  ensure_lead_state_dir

  if [ ! -f "$state_file" ]; then
    init_lead_state
  fi

  jq --arg field "$field" --arg value "$value" \
    '.[$field] = $value' \
    "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
}

# Update lead state with object
# Usage: update_lead_state_object <field> <json_value>
update_lead_state_object() {
  local field="$1"
  local json_value="$2"
  local state_file=$(get_lead_state_file)

  ensure_lead_state_dir

  if [ ! -f "$state_file" ]; then
    init_lead_state
  fi

  jq --arg field "$field" --argjson value "$json_value" \
    '.[$field] = $value' \
    "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
}

# Get lead state field
# Usage: get_lead_state <field>
get_lead_state() {
  local field="$1"
  local state_file=$(get_lead_state_file)

  if [ ! -f "$state_file" ]; then
    echo "null"
    return
  fi

  jq -r ".$field // \"null\"" "$state_file"
}

# Check if lead is running
is_lead_running() {
  local status=$(get_lead_state "status")
  local pid=$(get_lead_state "pid")

  if [ "$status" = "running" ] && [ "$pid" != "null" ] && [ -n "$pid" ]; then
    # Check if process is actually running
    if kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi

  return 1
}

# =============================================================================
# Session Tracking
# =============================================================================

# Register active session
# Usage: register_active_session <bead_id> <worktree_path> <session_name>
register_active_session() {
  local bead_id="$1"
  local worktree_path="$2"
  local session_name="$3"
  local state_file=$(get_lead_state_file)

  local session_data=$(cat <<EOF
{
  "bead_id": "$bead_id",
  "worktree_path": "$worktree_path",
  "session_name": "$session_name",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_activity": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "active"
}
EOF
)

  jq --arg bead "$bead_id" --argjson data "$session_data" \
    '.active_sessions[$bead] = $data' \
    "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
}

# Unregister active session
# Usage: unregister_active_session <bead_id>
unregister_active_session() {
  local bead_id="$1"
  local state_file=$(get_lead_state_file)

  jq --arg bead "$bead_id" \
    'del(.active_sessions[$bead])' \
    "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
}

# Update session activity timestamp
# Usage: update_session_activity <bead_id>
update_session_activity() {
  local bead_id="$1"
  local state_file=$(get_lead_state_file)
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  jq --arg bead "$bead_id" --arg ts "$timestamp" \
    '.active_sessions[$bead].last_activity = $ts' \
    "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
}

# Get active session count
get_active_session_count() {
  local state_file=$(get_lead_state_file)

  if [ ! -f "$state_file" ]; then
    echo "0"
    return
  fi

  jq '.active_sessions | length' "$state_file"
}

# Get active sessions
get_active_sessions() {
  local state_file=$(get_lead_state_file)

  if [ ! -f "$state_file" ]; then
    echo "{}"
    return
  fi

  jq '.active_sessions' "$state_file"
}

# Check if session has stalled
# Returns: 0 if stalled, 1 if active
# Usage: is_session_stalled <bead_id>
is_session_stalled() {
  local bead_id="$1"
  local state_file=$(get_lead_state_file)

  if [ ! -f "$state_file" ]; then
    return 1
  fi

  local last_activity=$(jq -r --arg bead "$bead_id" \
    '.active_sessions[$bead].last_activity // ""' "$state_file")

  if [ -z "$last_activity" ] || [ "$last_activity" = "null" ]; then
    return 1
  fi

  # Calculate minutes since last activity
  local now=$(date +%s)
  local last=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_activity" +%s 2>/dev/null || echo "$now")
  local diff=$(( (now - last) / 60 ))

  if [ "$diff" -ge "$SWE_STALL_MINUTES" ]; then
    return 0
  fi

  return 1
}

# =============================================================================
# Desktop Notifications (macOS)
# =============================================================================

# Send desktop notification
# Usage: send_notification <type> <title> <message>
# Types: BLOCKER, STALL, CONFLICT, TEST_FAILURE, CRASH, INFO
send_notification() {
  local type="$1"
  local title="$2"
  local message="$3"

  # Map type to emoji
  local icon=""
  case "$type" in
    BLOCKER)      icon="🚫" ;;
    STALL)        icon="⏸️" ;;
    CONFLICT)     icon="⚠️" ;;
    TEST_FAILURE) icon="❌" ;;
    CRASH)        icon="💥" ;;
    INFO)         icon="ℹ️" ;;
    *)            icon="📢" ;;
  esac

  # Send notification via osascript
  osascript -e "display notification \"$message\" with title \"$icon Lead Agent: $title\" sound name \"Submarine\"" 2>/dev/null || true

  # Log escalation
  log_escalation "$type" "$title" "$message"
}

# Log escalation to state
log_escalation() {
  local type="$1"
  local title="$2"
  local message="$3"
  local state_file=$(get_lead_state_file)

  local escalation=$(cat <<EOF
{
  "type": "$type",
  "title": "$title",
  "message": "$message",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

  jq --argjson esc "$escalation" \
    '.escalations += [$esc] | .escalations |= .[-20:]' \
    "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
}

# =============================================================================
# Lock Management
# =============================================================================

# Acquire lock
# Returns: 0 if acquired, 1 if already locked
acquire_lead_lock() {
  local lock_file=$(get_lead_lock_file)
  local pid=$$

  # Try to create lock file atomically
  if mkdir "$lock_file" 2>/dev/null; then
    echo "$pid" > "$lock_file/pid"
    return 0
  fi

  # Check if existing lock is stale
  if [ -f "$lock_file/pid" ]; then
    local old_pid=$(cat "$lock_file/pid")
    if ! kill -0 "$old_pid" 2>/dev/null; then
      # Stale lock, remove and retry
      rm -rf "$lock_file"
      if mkdir "$lock_file" 2>/dev/null; then
        echo "$pid" > "$lock_file/pid"
        return 0
      fi
    fi
  fi

  return 1
}

# Release lock
release_lead_lock() {
  local lock_file=$(get_lead_lock_file)
  rm -rf "$lock_file" 2>/dev/null
}

# =============================================================================
# Work Queue Management
# =============================================================================

# Get dispatchable beads (ready to work)
get_dispatchable_beads() {
  # Use bd ready to get leaf tasks with no blockers
  local ready_beads=""

  for type in task bug feature chore; do
    ready_beads+=$(bd ready --type "$type" --limit 100 2>/dev/null || echo "")
    ready_beads+=$'\n'
  done

  # Extract bead IDs from output
  echo "$ready_beads" | grep -oE '[a-z]+-[a-z0-9]+(\.[0-9]+)*' | sort -u
}

# Get beads ready for integration (swe:code-complete label)
get_integration_ready_beads() {
  # Look for beads with swe:code-complete label
  bd list --status=in_progress --label=swe:code-complete 2>/dev/null | \
    grep -oE '[a-z]+-[a-z0-9]+(\.[0-9]+)*' | sort -u
}

# Check if bead is blocked
is_bead_blocked() {
  local bead_id="$1"

  # Check bead status
  local status=$(bd show "$bead_id" 2>/dev/null | grep -i "^Status:" | awk '{print $2}')

  if [ "$status" = "blocked" ]; then
    return 0
  fi

  return 1
}

# =============================================================================
# Session Monitoring
# =============================================================================

# Check if worktree has uncommitted changes
has_uncommitted_changes() {
  local worktree_path="$1"

  if [ ! -d "$worktree_path" ]; then
    return 1
  fi

  (cd "$worktree_path" && git status --porcelain 2>/dev/null | grep -q .)
}

# Check if worktree has unpushed commits
has_unpushed_commits() {
  local worktree_path="$1"

  if [ ! -d "$worktree_path" ]; then
    return 1
  fi

  local branch=$(cd "$worktree_path" && git branch --show-current 2>/dev/null)

  if [ -z "$branch" ]; then
    return 1
  fi

  local ahead=$(cd "$worktree_path" && git rev-list --count "origin/$branch..$branch" 2>/dev/null || echo "0")

  [ "$ahead" -gt 0 ]
}

# Detect session activity (git activity in worktree)
detect_session_activity() {
  local bead_id="$1"
  local worktree_path="$2"

  if [ ! -d "$worktree_path" ]; then
    return 1
  fi

  # Check if there have been recent commits or file changes
  if has_uncommitted_changes "$worktree_path" || has_unpushed_commits "$worktree_path"; then
    update_session_activity "$bead_id"
    return 0
  fi

  # Check last commit time
  local last_commit_time=$(cd "$worktree_path" && git log -1 --format=%ct 2>/dev/null || echo "0")
  local now=$(date +%s)
  local minutes_since=$(( (now - last_commit_time) / 60 ))

  # If commit in last 30 minutes, consider it activity
  if [ "$minutes_since" -lt "$SWE_STALL_MINUTES" ]; then
    update_session_activity "$bead_id"
    return 0
  fi

  return 1
}

# =============================================================================
# Utility Functions
# =============================================================================

# Pretty print timestamp
format_timestamp() {
  local ts="$1"

  if [ -z "$ts" ] || [ "$ts" = "null" ]; then
    echo "never"
    return
  fi

  # Convert to local time and format
  date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$ts"
}

# Calculate time difference in minutes
time_diff_minutes() {
  local start="$1"
  local end="${2:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

  local start_sec=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$start" +%s 2>/dev/null || echo "0")
  local end_sec=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$end" +%s 2>/dev/null || date +%s)

  echo $(( (end_sec - start_sec) / 60 ))
}
