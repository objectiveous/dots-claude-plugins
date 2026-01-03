---
description: "Capture session context before closing a worktree"
allowed-tools: ["Bash"]
---

# Worktree Handoff

Captures the current session context for handoff to the next session. Records what was done, what's left, and any blockers.

**Usage:** `/dots-dev:worktree-handoff`

Run this before closing a worktree session to preserve context.

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:worktree-handoff"
  echo ""
  echo "Capture session context before closing a worktree."
  echo ""
  echo "Creates a .claude-handoff file containing:"
  echo "  - Associated bead ID"
  echo "  - Last commit"
  echo "  - Uncommitted changes"
  echo "  - Unpushed commits"
  echo "  - Template sections for:"
  echo "    - Session summary (what was done)"
  echo "    - Remaining work"
  echo "    - Blockers"
  echo "    - Notes for next session"
  echo ""
  echo "The next Claude session will automatically see this handoff."
  echo ""
  echo "Must be run from within a worktree (not main repo)."
  exit 0
fi

!WORKTREE_PATH=$(pwd)
!REPO_ROOT=$(get_repo_root)

# Check if we're in a worktree
!if [ "$WORKTREE_PATH" = "$REPO_ROOT" ]; then
  echo "⚠️  You're in the main repository, not a worktree."
  echo "Run this from within a worktree to capture handoff context."
  exit 1
fi

!BRANCH=$(git branch --show-current)
!HANDOFF_FILE="$WORKTREE_PATH/.claude-handoff"
!TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                    Session Handoff                           ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""
!echo "Capturing context for: $BRANCH"
!echo ""

# Gather git status
!echo "Gathering git status..."
!GIT_STATUS=$(git status --short)
!UNPUSHED=$(git log @{u}..HEAD --oneline 2>/dev/null || echo "")
!LAST_COMMIT=$(git log -1 --format="%h %s" 2>/dev/null || echo "none")

# Check for bead
!BEAD_ID=""
!if [ -f "$WORKTREE_PATH/.claude-bead" ]; then
  BEAD_ID=$(cat "$WORKTREE_PATH/.claude-bead")
fi

# Generate handoff document
!cat > "$HANDOFF_FILE" << EOF
# Session Handoff: $BRANCH
Generated: $TIMESTAMP

## Bead
${BEAD_ID:-No bead associated}

## Last Commit
$LAST_COMMIT

## Uncommitted Changes
\`\`\`
${GIT_STATUS:-None}
\`\`\`

## Unpushed Commits
\`\`\`
${UNPUSHED:-None (or no upstream)}
\`\`\`

## Session Summary
<!-- FILL IN: What was accomplished this session -->


## Remaining Work
<!-- FILL IN: What still needs to be done -->


## Blockers
<!-- FILL IN: Any blockers for the next session -->


## Notes for Next Session
<!-- FILL IN: Context, gotchas, or tips -->


EOF

!echo "Created handoff file: $HANDOFF_FILE"
!echo ""
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!cat "$HANDOFF_FILE"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""
!echo "Please fill in the sections marked with <!-- FILL IN -->."
!echo ""
!echo "The next Claude session in this worktree will automatically"
!echo "see this handoff file and can pick up where you left off."
!echo ""

# If we have a bead, offer to update it
!if [ -n "$BEAD_ID" ]; then
  echo "Bead $BEAD_ID is associated with this worktree."
  echo "Consider updating its status or adding a comment:"
  echo ""
  echo "  bd comment $BEAD_ID \"Session handoff: <summary>\""
  echo ""
fi
