#!/bin/bash
# Start work from a bead - creates worktree and claims the task

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Parse flags
DRY_RUN=false
BEAD_ID=""
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --tab) export SWE_GHOSTTY_MODE=tab ;;
    --window) export SWE_GHOSTTY_MODE=window ;;
    --help|-h) ;; # handled below
    *) BEAD_ID="$arg" ;;
  esac
done

# Help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  # Source lib for helper functions
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/swe-lib.sh"

  REPO_ROOT=$(get_repo_root 2>/dev/null || echo "<repo-root>")
  WORKTREES_DIR="$REPO_ROOT/.worktrees"
  TERMINAL=$(get_swe_terminal)
  CLAUDE_OPTS=$(get_claude_options)

  echo "Usage: /dots-swe:start [options] <bead-id>"
  echo ""
  echo "Start work on a bead by creating a worktree and Claude session."
  echo ""
  echo "Options:"
  echo "  --dry-run, -n    Show what would happen without doing it"
  echo "  --window         Open Claude in a new Ghostty window (default)"
  echo "  --tab            Open Claude in a new Ghostty tab"
  echo ""
  echo "What this does:"
  echo "  • Verifies the bead exists"
  echo "  • Creates a git worktree at $WORKTREES_DIR/<bead-id>"
  echo "  • Sets up context files (.swe-bead, .swe-context)"
  echo "  • Claims the bead (status → in_progress)"
  echo "  • Opens Claude in a new terminal"
  echo ""
  echo "Current setup:"
  echo "  Terminal: $TERMINAL"
  if [ "$TERMINAL" = "ghostty" ]; then
    echo "  Session:  zmx (opens new Ghostty ${SWE_GHOSTTY_MODE:-window})"
    echo "  Detach:   ctrl+\\"
    echo "  Reattach: zmx attach <bead-id>"
  else
    echo "  Session:  tmux (opens new iTerm window)"
    echo "  Reattach: /dots-swe:starttree-attach <session>"
  fi
  echo ""
  echo "Example:"
  echo "  /dots-swe:start dots-abc"
  echo "  /dots-swe:start --tab dots-abc"
  echo "  /dots-swe:start --dry-run dots-abc"
  echo ""
  echo "See also:"
  echo "  bd ready          # Find available work"
  echo "  bd show <id>      # Preview bead details"
  exit 0
fi

# Validate arguments
if [ -z "$BEAD_ID" ]; then
  echo "ERROR: No bead ID provided"
  echo ""
  echo "Usage: /dots-swe:start [--dry-run] <bead-id>"
  echo ""
  echo "Available work:"
  bd ready 2>/dev/null || echo "  (bd command not available)"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Starting Work from Bead                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Bead ID: $BEAD_ID"
echo ""

# Verify bead exists
echo "Verifying bead exists..."
BEAD_INFO=$(bd show "$BEAD_ID" 2>/dev/null)
if [ -z "$BEAD_INFO" ]; then
  echo "ERROR: Bead '$BEAD_ID' not found"
  echo ""
  echo "Available work:"
  bd ready 2>/dev/null
  exit 1
fi
echo "✅ Bead found"
echo ""

# Setup variables
REPO_ROOT=$(get_repo_root)
CURRENT_BRANCH=$(git branch --show-current)
WORKTREES_DIR=$(get_worktrees_dir)
WORKTREE_PATH="$WORKTREES_DIR/$BEAD_ID"
TERMINAL=$(get_swe_terminal)
CLAUDE_OPTS=$(get_claude_options)

# Dry-run mode - show what would happen
if [ "$DRY_RUN" = true ]; then
  MODE="${SWE_GHOSTTY_MODE:-window}"

  echo ""
  echo "📋 DRY RUN: Here's what would happen"
  echo ""

  # Show bead summary (first 2 lines usually have title)
  echo "Task:"
  echo "$BEAD_INFO" | head -5 | sed 's/^/  /'
  echo ""

  if [ -d "$WORKTREE_PATH" ]; then
    echo "📁 Worktree already exists"
    echo "   Path: $WORKTREE_PATH"
    echo "   Branch: $(cd "$WORKTREE_PATH" && git branch --show-current 2>/dev/null || echo "unknown")"
    echo ""
    echo "   → Would skip creation and just open the session"
  else
    BRANCH_STATUS=$(branch_exists "$BEAD_ID")
    echo "📁 Will create worktree"
    echo "   Path: $WORKTREE_PATH"
    case "$BRANCH_STATUS" in
      "local")  echo "   Branch: $BEAD_ID (existing local)" ;;
      "remote") echo "   Branch: $BEAD_ID (from origin)" ;;
      *)        echo "   Branch: $BEAD_ID (new, from $CURRENT_BRANCH)" ;;
    esac
    echo ""
    echo "📝 Will set up context"
    echo "   • Copy .claude/ config"
    echo "   • Create .swe-bead and .swe-context files"
    echo "   • Claim bead (status → in_progress)"
  fi

  echo ""
  if [ "$TERMINAL" = "ghostty" ]; then
    echo "🖥️  Will open Ghostty $MODE with Claude"
    echo "   Session: zmx attach $BEAD_ID"
    echo "   Detach: ctrl+\\"
    echo "   Reattach: zmx attach $BEAD_ID"
  else
    echo "🖥️  Will open iTerm window with Claude"
    echo "   Session: tmux ($BEAD_ID)"
    echo "   Reattach: /dots-swe:starttree-attach"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Run without --dry-run to execute"
  echo "Add --tab to open in a Ghostty tab instead of window"
  exit 0
fi

# Check if worktree already exists
if [ -d "$WORKTREE_PATH" ]; then
  echo "⚠️  Worktree already exists: $WORKTREE_PATH"
  echo ""
  echo "Opening session for existing worktree..."
  ABS_PATH="$(cd "$WORKTREE_PATH" && pwd)"
  register_worktree "$ABS_PATH" "$BEAD_ID" "$BEAD_ID"
  # open_worktree_session may exec (zmx) or return (tmux)
  open_worktree_session "$WORKTREE_PATH" "$BEAD_ID"
  echo "✅ Opened existing worktree"
  exit 0
fi

# Ensure worktrees directory exists
ensure_worktrees_dir

# Create the worktree
echo "Creating worktree..."
BRANCH_STATUS=$(branch_exists "$BEAD_ID")
case "$BRANCH_STATUS" in
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

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create worktree"
  exit 1
fi
echo "✅ Worktree created"
echo ""

# Copy .claude directory
if [ -d "$REPO_ROOT/.claude" ]; then
  cp -r "$REPO_ROOT/.claude" "$WORKTREE_PATH/"
  echo "Copied .claude/ to worktree"
fi

# Store bead ID
echo "Setting up bead context..."
echo "$BEAD_ID" > "$WORKTREE_PATH/.swe-bead"
echo "✅ Created .swe-bead file"

# Create context file
cat > "$WORKTREE_PATH/.swe-context" << CONTEXT
# Task: $BEAD_ID

$BEAD_INFO

## Quick Reference

- Run \`/dots-swe:check\` before committing to verify tests, lint, and build
- Run \`/dots-swe:ship\` when ready to create PR and watch CI
- Update bead status: \`bd update $BEAD_ID --status=<status>\`
  - Statuses: \`in_progress\`, \`blocked\`, \`ready_to_merge\`
- Add notes: \`bd comment $BEAD_ID "Your comment here"\`

## Quality Checklist

Before shipping:
- [ ] Tests written and passing
- [ ] Lint clean
- [ ] Build successful
- [ ] Changes committed with clear messages
- [ ] PR description written

CONTEXT

echo "✅ Created .swe-context file"
echo ""

# Claim the bead
echo "Claiming bead..."
if bd update "$BEAD_ID" --status=in_progress 2>/dev/null; then
  echo "✅ Bead status updated to in_progress"
else
  echo "⚠️  Failed to update bead status (continuing anyway)"
fi
echo ""

# Open session with Claude
TERMINAL=$(get_swe_terminal)
echo "Opening Claude session ($TERMINAL)..."
ABS_PATH="$(cd "$WORKTREE_PATH" && pwd)"
register_worktree "$ABS_PATH" "$BEAD_ID" "$BEAD_ID"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Ready to work!"
echo ""
echo "Worktree: $WORKTREE_PATH"
echo "Branch: $BEAD_ID"
echo "Bead: $BEAD_ID"
echo ""
echo "Check .swe-context for task details and quick reference."
echo ""

# Opens new terminal window/tab with Claude session
open_worktree_session "$WORKTREE_PATH" "$BEAD_ID"

echo "✅ Claude session opened in new terminal."
