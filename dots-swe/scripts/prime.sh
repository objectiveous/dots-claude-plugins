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

# 1.5. Show bead hierarchy (Go! announcement)
if [ -n "$BEAD_ID" ] && command -v bd >/dev/null 2>&1; then
  # Get bead info for announcement (using direct pipes to avoid JSON escaping issues)
  TITLE=$(bd show "$BEAD_ID" --json 2>/dev/null | jq -r '.[0].title // ""' 2>/dev/null || echo "")
  DESCRIPTION=$(bd show "$BEAD_ID" --json 2>/dev/null | jq -r '.[0].description // ""' 2>/dev/null || echo "")
  TYPE=$(bd show "$BEAD_ID" --json 2>/dev/null | jq -r '.[0].issue_type // "task"' 2>/dev/null || echo "task")

  if [ -n "$TITLE" ]; then
    # Get hierarchy
    if declare -f get_bead_hierarchy >/dev/null 2>&1; then
      HIERARCHY=$(get_bead_hierarchy "$BEAD_ID" 2>/dev/null || echo "")

      if [ -n "$HIERARCHY" ]; then
        CONTEXT+="🎯 **Working on bead hierarchy:**\n\n"
        CONTEXT+="$HIERARCHY\n\n"
      fi
    fi

    # Add brief description for context
    if [ -n "$DESCRIPTION" ]; then
      FIRST_LINE=$(echo "$DESCRIPTION" | head -1)
      CONTEXT+="**About this $TYPE:** $FIRST_LINE\n\n"
      CONTEXT+="---\n\n"
    fi
  fi
fi

# 2. Load task context if available
if [ -f ".swe-context" ]; then
  CONTEXT+="$(cat .swe-context)\n\n"
fi

# 3. Detect project type for quality gates
eval "$(detect_project_commands)"

# Detect workflow mode (GitHub PR or local/ephemeral)
WORKFLOW_MODE=$(detect_workflow_mode)

# 4. Build enhanced SESSION CLOSE PROTOCOL
CONTEXT+="# 🚨 SESSION CLOSE PROTOCOL 🚨\n\n"
CONTEXT+="**CRITICAL**: Before saying \"done\" or \"complete\", you MUST run this checklist:\n\n"

# Determine if we have quality gates
HAS_QUALITY_GATES=false
if [ -n "$TEST_CMD" ] || [ -n "$LINT_CMD" ] || [ -n "$BUILD_CMD" ]; then
  HAS_QUALITY_GATES=true
fi

# Build protocol based on workflow mode
if [ "$WORKFLOW_MODE" = "github" ]; then
  # GitHub PR Workflow
  CONTEXT+="\`\`\`\n"
  CONTEXT+="[ ] 0. Run /dots-swe:code-complete\n"
  CONTEXT+="       ↓ This command does ALL of the following:\n"

  if [ "$HAS_QUALITY_GATES" = true ]; then
    CONTEXT+="       • Runs quality gates:\n"
    [ -n "$TEST_CMD" ] && CONTEXT+="         - Tests: $TEST_CMD\n"
    [ -n "$LINT_CMD" ] && CONTEXT+="         - Lint: $LINT_CMD\n"
    [ -n "$BUILD_CMD" ] && CONTEXT+="         - Build: $BUILD_CMD\n"
  else
    CONTEXT+="       • No quality gates detected (no tests/lint/build)\n"
  fi

  CONTEXT+="       • Pushes code to remote\n"
  CONTEXT+="       • Creates/updates PR\n"
  CONTEXT+="       • Adds swe:code-complete label to bead\n"
  CONTEXT+="       ↓ DO NOT proceed if this fails\n"
  CONTEXT+="       ↓ Fix issues and run code-complete again\n"
  CONTEXT+="\n"
  CONTEXT+="[ ] 1. bd sync --from-main     (pull beads updates from main)\n"
  CONTEXT+="[ ] 2. git status              (verify everything committed and pushed)\n"
  CONTEXT+="\`\`\`\n\n"
  CONTEXT+="**Note:** GitHub PR workflow detected.\n"
  CONTEXT+="Next: Wait for PR review and CI to pass, then run /dots-swe:code-integrate\n\n"
else
  # Local/Ephemeral Workflow
  CONTEXT+="\`\`\`\n"
  CONTEXT+="[ ] 0. Run /dots-swe:code-complete\n"
  CONTEXT+="       ↓ This command does ALL of the following:\n"

  if [ "$HAS_QUALITY_GATES" = true ]; then
    CONTEXT+="       • Runs quality gates:\n"
    [ -n "$TEST_CMD" ] && CONTEXT+="         - Tests: $TEST_CMD\n"
    [ -n "$LINT_CMD" ] && CONTEXT+="         - Lint: $LINT_CMD\n"
    [ -n "$BUILD_CMD" ] && CONTEXT+="         - Build: $BUILD_CMD\n"
  else
    CONTEXT+="       • No quality gates detected (no tests/lint/build)\n"
  fi

  CONTEXT+="       • Pushes code to remote (if upstream configured)\n"
  CONTEXT+="       • Adds swe:code-complete label to bead\n"
  CONTEXT+="       • Marks work ready for integration\n"
  CONTEXT+="       ↓ DO NOT proceed to next steps if this fails\n"
  CONTEXT+="       ↓ Fix issues and run code-complete again\n"
  CONTEXT+="\n"
  CONTEXT+="[ ] 1. git status              (verify what changed)\n"
  CONTEXT+="[ ] 2. git add <files>         (stage code changes)\n"
  CONTEXT+="[ ] 3. bd sync --from-main     (pull beads updates from main)\n"
  CONTEXT+="[ ] 4. git commit -m \"...\"     (commit code changes)\n"
  CONTEXT+="\`\`\`\n\n"
  CONTEXT+="**Note:** This is an ephemeral branch (no upstream). Code is merged to main locally, not pushed.\n\n"
fi

# Add failure handling guidance
CONTEXT+="**When code-complete fails:**\n"
CONTEXT+="• Read the error output carefully\n"
CONTEXT+="• Fix the failing quality gate (test/lint/build)\n"
CONTEXT+="• Run code-complete again\n"
CONTEXT+="• Only commit after code-complete succeeds\n\n"

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
