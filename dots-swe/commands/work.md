---
allowed-tools: Bash(git:*), Bash(bd:*), Bash(mkdir:*), Bash(jq:*), Bash(osascript:*), Bash(cat:*)
description: Start work from a bead - creates worktree and claims the task
execution-mode: atomic-bash
---

<claude-instructions>
CRITICAL: This skill spawns a NEW session in a worktree. DO NOT work in the current directory.

1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output
4. Report the result to the user and STOP - work happens in the NEW session
5. NEVER continue working in the current directory after this skill runs

The `/dots-swe:work` command ALWAYS creates/opens a worktree, regardless of bead status.
</claude-instructions>

# Start Work from Bead

Creates a worktree from a bead ID, claims the bead, and sets up context for the task.

**Usage:** `/dots-swe:work <bead-id>`

**Example:**
```bash
/dots-swe:work dots-abc
```

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:work <bead-id>"
  echo ""
  echo "Creates a worktree from a bead, claims it, and opens Claude session."
  echo ""
  echo "Example:"
  echo "  /dots-swe:work dots-abc"
  exit 0
fi

# Validate arguments
!if [ $# -eq 0 ]; then
  echo "ERROR: No bead ID provided"
  echo ""
  echo "Usage: /dots-swe:work <bead-id>"
  echo ""
  echo "Available work:"
  bd ready 2>/dev/null || echo "  (bd command not available)"
  exit 1
fi

!BEAD_ID="$1"

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                  Starting Work from Bead                     ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""
!echo "Bead ID: $BEAD_ID"
!echo ""

# Verify bead exists
!echo "Verifying bead exists..."
!BEAD_INFO=$(bd show "$BEAD_ID" 2>/dev/null)
!if [ -z "$BEAD_INFO" ]; then
  echo "ERROR: Bead '$BEAD_ID' not found"
  echo ""
  echo "Available work:"
  bd ready 2>/dev/null
  exit 1
fi
!echo "✅ Bead found"
!echo ""

# Setup variables
!REPO_ROOT=$(get_repo_root)
!CURRENT_BRANCH=$(git branch --show-current)
!WORKTREES_DIR=$(get_worktrees_dir)
!WORKTREE_PATH="$WORKTREES_DIR/$BEAD_ID"

# Check if worktree already exists
!if [ -d "$WORKTREE_PATH" ]; then
  echo "⚠️  Worktree already exists: $WORKTREE_PATH"
  echo ""
  echo "Opening iTerm tab for existing worktree..."
  TAB_ID=$(open_iterm_claude_session "$WORKTREE_PATH")
  register_worktree "$(cd "$WORKTREE_PATH" && pwd)" "$BEAD_ID" "$TAB_ID"
  echo "✅ Opened existing worktree"
  exit 0
fi

# Ensure worktrees directory exists
!ensure_worktrees_dir

# Create the worktree
!echo "Creating worktree..."
!BRANCH_STATUS=$(branch_exists "$BEAD_ID")
!case "$BRANCH_STATUS" in
  "local")
    echo "Using existing local branch: $BEAD_ID"
    git worktree add "$WORKTREE_PATH" "$BEAD_ID"
    ;;
  "remote")
    echo "Using existing remote branch: origin/$BEAD_ID"
    git worktree add "$WORKTREE_PATH" "$BEAD_ID"
    ;;
  *)
    echo "Creating new branch: $BEAD_ID (from $CURRENT_BRANCH)"
    git worktree add -b "$BEAD_ID" "$WORKTREE_PATH" "$CURRENT_BRANCH"
    ;;
esac

!if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create worktree"
  exit 1
fi
!echo "✅ Worktree created"
!echo ""

# Copy .claude directory
!if [ -d "$REPO_ROOT/.claude" ]; then
  cp -r "$REPO_ROOT/.claude" "$WORKTREE_PATH/"
  echo "Copied .claude/ to worktree"
fi

# Store bead ID
!echo "Setting up bead context..."
!echo "$BEAD_ID" > "$WORKTREE_PATH/.swe-bead"
!echo "✅ Created .swe-bead file"

# Create context file
!cat > "$WORKTREE_PATH/.swe-context" << 'CONTEXT'
# Task: $(echo "$BEAD_ID")

$(echo "$BEAD_INFO")

## Quick Reference

- Run `/dots-swe:check` before committing to verify tests, lint, and build
- Run `/dots-swe:ship` when ready to create PR and watch CI
- Update bead status: `bd update $(echo "$BEAD_ID") --status=<status>`
  - Statuses: `in_progress`, `blocked`, `ready_to_merge`
- Add notes: `bd comment $(echo "$BEAD_ID") "Your comment here"`

## Quality Checklist

Before shipping:
- [ ] Tests written and passing
- [ ] Lint clean
- [ ] Build successful
- [ ] Changes committed with clear messages
- [ ] PR description written

CONTEXT

!echo "✅ Created .swe-context file"
!echo ""

# Claim the bead
!echo "Claiming bead..."
!bd update "$BEAD_ID" --status=in_progress 2>/dev/null
!if [ $? -eq 0 ]; then
  echo "✅ Bead status updated to in_progress"
else
  echo "⚠️  Failed to update bead status (continuing anyway)"
fi
!echo ""

# Open iTerm tab
!echo "Opening iTerm tab with Claude..."
!ABS_PATH="$(cd "$WORKTREE_PATH" && pwd)"
!TAB_ID=$(open_iterm_claude_session "$WORKTREE_PATH")
!echo "$TAB_ID" > "$WORKTREE_PATH/.claude-tab-id"
!register_worktree "$ABS_PATH" "$BEAD_ID" "$TAB_ID"
!echo "✅ Claude session opened (tab ID: $TAB_ID)"
!echo ""

!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "✅ Ready to work!"
!echo ""
!echo "Worktree: $WORKTREE_PATH"
!echo "Branch: $BEAD_ID"
!echo "Bead: $BEAD_ID"
!echo ""
!echo "The Claude session has been opened in a new iTerm tab."
!echo "Check .swe-context for task details and quick reference."
