#!/bin/bash
# PreToolUse hook: Require bead context for Edit/Write operations
# Soft-blocks code changes outside of bead worktrees to enforce dots-swe workflow

set -euo pipefail

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

# Check for any recent bypass flag (within last 60 seconds)
# This handles the case where Claude creates the flag in main shell
if [[ -n "$(find "$BYPASS_DIR" -name 'swe-bead-bypass-*' -mtime -60s 2>/dev/null | head -n1)" ]]; then
    echo '{"continue": true}'
    exit 0
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
