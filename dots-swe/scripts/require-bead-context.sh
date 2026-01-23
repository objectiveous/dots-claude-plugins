#!/bin/bash
# PreToolUse hook: Require bead context for Edit/Write operations
# Soft-blocks code changes outside of bead worktrees to enforce dots-swe workflow

set -euo pipefail

# Read tool use data from stdin (JSON format)
TOOL_USE_JSON=$(cat)

# Extract the file_path from the tool use JSON
# For Edit/Write tools, the file path is in .parameters.file_path
FILE_PATH=$(echo "$TOOL_USE_JSON" | jq -r '.parameters.file_path // empty')

# Check if file path matches excluded patterns (paths that should always be allowed)
if [[ -n "$FILE_PATH" ]]; then
  # Allow writes to Claude Code plan files
  if [[ "$FILE_PATH" =~ /.claude/plans/ ]]; then
    echo '{"continue": true}'
    exit 0
  fi

  # Allow writes to beads database
  if [[ "$FILE_PATH" =~ /.beads/ ]]; then
    echo '{"continue": true}'
    exit 0
  fi

  # Allow writes to Claude plugin metadata
  if [[ "$FILE_PATH" =~ /.claude-plugin/ ]]; then
    echo '{"continue": true}'
    exit 0
  fi
fi

# Check if we're in a bead context (.swe-bead file exists)
if [[ -f .swe-bead ]]; then
    # In worktree - allow
    echo '{"continue": true}'
    exit 0
fi

# Check for bypass flag (session-scoped via parent process or recent flag)
# Since hooks run in subprocesses, check both $PPID and recent bypass files
BYPASS_DIR="$HOME/.claude"
mkdir -p "$BYPASS_DIR"

# Check for parent PID bypass flag
if [[ -f "$BYPASS_DIR/swe-bead-bypass-$PPID" ]]; then
    echo '{"continue": true}'
    exit 0
fi

# Check for any recent bypass flag (within last minute)
# This handles the case where Claude creates the flag in main shell
if [[ -n "$(find "$BYPASS_DIR" -name 'swe-bead-bypass-*' -mmin -1 2>/dev/null | head -n1)" ]]; then
    echo '{"continue": true}'
    exit 0
fi

# Check if the file path should be excluded from bead tracking
# Read JSON input from stdin and extract file_path
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | cut -d'"' -f4 || echo "")

if [[ -n "$FILE_PATH" ]]; then
    # Expand ~ to home directory for comparison
    EXPANDED_PATH="${FILE_PATH/#\~/$HOME}"

    # Paths that don't need bead tracking
    if [[ "$EXPANDED_PATH" == "$HOME/.claude/plans/"* ]] || \
       [[ "$EXPANDED_PATH" == *"/.beads/"* ]] || \
       [[ "$EXPANDED_PATH" == *"/.claude-plugin/"* ]]; then
        echo '{"continue": true}'
        exit 0
    fi
fi

# Not in bead context and no bypass - soft block
cat <<'EOF'
{
  "decision": "block",
  "reason": "No bead context detected - code changes should be tracked in beads",
  "message": "⚠️ No bead context detected.\n\nTo track this work properly:\n  1. bd create --title=\"...\" --type=task\n  2. /dots-swe:dispatch <bead-id>\n\nOr type 'allow once' to proceed without tracking.\n\nTo bypass: Run this command:\n  touch \"$HOME/.claude/swe-bead-bypass-$$\""
}
EOF
exit 0
