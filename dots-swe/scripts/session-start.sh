#!/bin/bash
# Auto-context loading for SWE agent sessions
# Runs at SessionStart to load bead context automatically

set -euo pipefail

# Only run in SWE worktrees (identified by .swe-bead file)
if [ ! -f ".swe-bead" ]; then
  exit 0
fi

# Build context message
CONTEXT=""

# 1. Load bead ID
BEAD_ID=$(cat .swe-bead 2>/dev/null || echo "")
if [ -n "$BEAD_ID" ]; then
  CONTEXT+="## Current Task: $BEAD_ID\n\n"
fi

# 2. Load task context if available
if [ -f ".swe-context" ]; then
  CONTEXT+="$(cat .swe-context)\n\n"
fi

# 3. Load CLAUDE.md if exists
if [ -f "CLAUDE.md" ]; then
  CONTEXT+="## Project Conventions\n\n"
  CONTEXT+="See CLAUDE.md for project-specific conventions.\n\n"
fi

# 4. Show git status
CONTEXT+="## Git Status\n\n"
CONTEXT+="\`\`\`\n"
CONTEXT+="$(git status --short 2>/dev/null || echo 'Not a git repo')\n"
CONTEXT+="\`\`\`\n\n"

# 5. Show recent commits
CONTEXT+="## Recent Commits\n\n"
CONTEXT+="\`\`\`\n"
CONTEXT+="$(git log --oneline -5 2>/dev/null || echo 'No commits')\n"
CONTEXT+="\`\`\`\n\n"

# 6. If bead exists, show dependencies
if [ -n "$BEAD_ID" ] && command -v bd >/dev/null 2>&1; then
  DEPS=$(bd show "$BEAD_ID" --json 2>/dev/null | jq -r '.[0].depends_on // empty' 2>/dev/null || echo "")
  BLOCKED_BY=$(bd show "$BEAD_ID" --json 2>/dev/null | jq -r '.[0].blocked_by // empty' 2>/dev/null || echo "")

  if [ -n "$DEPS" ] || [ -n "$BLOCKED_BY" ]; then
    CONTEXT+="## Dependencies\n\n"
    [ -n "$BLOCKED_BY" ] && CONTEXT+="**Blocked by:** $BLOCKED_BY\n"
    [ -n "$DEPS" ] && CONTEXT+="**Depends on:** $DEPS\n"
    CONTEXT+="\n"
  fi
fi

# Output as systemMessage for Claude
echo "{\"systemMessage\": \"$CONTEXT\", \"continue\": true}"
