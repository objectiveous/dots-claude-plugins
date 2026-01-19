#!/bin/bash
# Enhanced context loader with quality gates enforcement
# Replaces/enhances bd prime output to ensure agents run quality gates before committing

set -euo pipefail

# Source swe-lib for detect_project_commands
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Only run in SWE worktrees (identified by .swe-bead file)
if [ ! -f ".swe-bead" ]; then
  echo "# Enhanced Session Context"
  echo ""
  echo "Not an SWE worktree (no .swe-bead file found)."
  echo "This command is designed for SWE agent workflows."
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

# 3. Detect project type for quality gates
eval "$(detect_project_commands)"

# 4. Build enhanced SESSION CLOSE PROTOCOL
CONTEXT+="# 🚨 SESSION CLOSE PROTOCOL 🚨\n\n"
CONTEXT+="**CRITICAL**: Before saying \"done\" or \"complete\", you MUST run this checklist:\n\n"
CONTEXT+="\`\`\`\n"

# Determine quality gates command based on what's detected
QUALITY_CMD=""
HAS_QUALITY_GATES=false

if [ -n "$TEST_CMD" ] || [ -n "$LINT_CMD" ] || [ -n "$BUILD_CMD" ]; then
  HAS_QUALITY_GATES=true
  QUALITY_CMD="/dots-swe:process-check"
fi

# Add Step 0 for quality gates (if project has them)
if [ "$HAS_QUALITY_GATES" = true ]; then
  CONTEXT+="[ ] 0. $QUALITY_CMD          (run tests, lint, build)\n"
fi

# Add original bd prime protocol steps
CONTEXT+="[ ] 1. git status              (check what changed)\n"
CONTEXT+="[ ] 2. git add <files>         (stage code changes)\n"
CONTEXT+="[ ] 3. bd sync --from-main     (pull beads updates from main)\n"
CONTEXT+="[ ] 4. git commit -m \"...\"     (commit code changes)\n"
CONTEXT+="\`\`\`\n\n"

# Add explanation
if [ "$HAS_QUALITY_GATES" = true ]; then
  CONTEXT+="**Note:** This is an ephemeral branch (no upstream). Code is merged to main locally, not pushed.\n\n"
  CONTEXT+="**Quality Gates Detected:**\n"
  [ -n "$TEST_CMD" ] && CONTEXT+="- Tests: \`$TEST_CMD\`\n"
  [ -n "$LINT_CMD" ] && CONTEXT+="- Lint: \`$LINT_CMD\`\n"
  [ -n "$BUILD_CMD" ] && CONTEXT+="- Build: \`$BUILD_CMD\`\n"
  CONTEXT+="\n"
else
  CONTEXT+="**Note:** No quality gates detected (no tests/lint/build commands found).\n"
  CONTEXT+="This is an ephemeral branch (no upstream). Code is merged to main locally, not pushed.\n\n"
fi

# 5. Show git status
CONTEXT+="## Git Status\n\n"
CONTEXT+="\`\`\`\n"
CONTEXT+="$(git status --short 2>/dev/null || echo 'Not a git repo')\n"
CONTEXT+="\`\`\`\n\n"

# 6. Show recent commits
CONTEXT+="## Recent Commits\n\n"
CONTEXT+="\`\`\`\n"
CONTEXT+="$(git log --oneline -5 2>/dev/null || echo 'No commits')\n"
CONTEXT+="\`\`\`\n\n"

# 7. Load CLAUDE.md if exists
if [ -f "CLAUDE.md" ]; then
  CONTEXT+="## Project Conventions\n\n"
  CONTEXT+="See CLAUDE.md for project-specific conventions.\n\n"
fi

# 8. Show bead dependencies if available
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

# Output as systemMessage for Claude (in hook mode) or markdown (in command mode)
# Detect if we're being called from a hook (has CLAUDE_HOOK env var) or as a command
if [ -n "${CLAUDE_HOOK:-}" ]; then
  # Hook mode: output JSON
  echo "{\"systemMessage\": \"$CONTEXT\", \"continue\": true}"
else
  # Command mode: output markdown
  echo -e "$CONTEXT"
fi
