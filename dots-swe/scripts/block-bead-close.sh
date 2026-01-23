#!/bin/bash
# PreToolUse hook to block direct bd close commands in SWE worktrees
# Enforces proper /dots-swe:code-complete workflow

set -euo pipefail

# Read tool use data from stdin (JSON format)
TOOL_USE_JSON=$(cat)

# Extract the command from the tool use JSON
# For Bash tool, the command is in .parameters.command
COMMAND=$(echo "$TOOL_USE_JSON" | jq -r '.parameters.command // empty')

# If no command or doesn't contain "bd close", allow it
if [[ -z "$COMMAND" ]] || [[ ! "$COMMAND" =~ bd[[:space:]]+close ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Check if we're in a SWE worktree (has .swe-bead file)
if [[ ! -f .swe-bead ]]; then
  # Not in a SWE worktree, allow the command
  echo '{"continue": true}'
  exit 0
fi

# We're in a SWE worktree and command contains "bd close" - BLOCK IT
cat <<'EOF'
{
  "decision": "block",
  "reason": "Direct bd close is not allowed in SWE worktrees",
  "message": "❌ **Cannot use `bd close` in SWE worktrees**\n\nYou must follow the proper workflow:\n\n1. **Run `/dots-swe:code-complete`** (REQUIRED)\n   - Runs quality gates (test/lint/build)\n   - Pushes code to remote\n   - Creates/updates PR\n   - Adds `swe:code-complete` label to bead\n\n2. **Then run `/dots-swe:code-integrate`**\n   - Merges code to main\n   - Closes the bead\n   - Cleans up worktree\n\nThis ensures all quality gates pass before closing the bead."
}
EOF
