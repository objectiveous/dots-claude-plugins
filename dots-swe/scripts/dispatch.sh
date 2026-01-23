#!/bin/bash
# Start work from a bead - creates worktree and claims the task

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Parse flags
DRY_RUN=false
BEAD_IDS=()
MODEL=""
i=0
while [ $i -lt $# ]; do
  i=$((i + 1))
  eval "arg=\${$i}"
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --tab) export SWE_GHOSTTY_MODE=tab ;;
    --window) export SWE_GHOSTTY_MODE=window ;;
    --model)
      i=$((i + 1))
      eval "MODEL=\${$i}"
      ;;
    --help|-h) ;; # handled below
    *) BEAD_IDS+=("$arg") ;;
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

  echo "Usage: /dots-swe:dispatch [options] [bead-id...]"
  echo ""
  echo "Start work on one or more beads by creating worktrees and Claude sessions."
  echo ""
  echo "Arguments:"
  echo "  bead-id...       One or more beads to work on (optional if already in a worktree)"
  echo ""
  echo "Options:"
  echo "  --dry-run, -n    Show what would happen without doing it"
  echo "  --tab            Open Claude in a new Ghostty tab (default)"
  echo "  --window         Open Claude in a new Ghostty window"
  echo "  --model <name>   Claude model to use (sonnet, opus, haiku; default: sonnet)"
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
    echo "  Session:  zmx (opens new Ghostty ${SWE_GHOSTTY_MODE:-tab})"
    echo "  Detach:   ctrl+\\"
    echo "  Reattach: zmx attach <bead-id>"
  else
    echo "  Session:  tmux (opens new iTerm window)"
    echo "  Reattach: /dots-swe:dispatchtree-attach <session>"
  fi
  echo ""
  echo "Examples:"
  echo "  /dots-swe:dispatch dots-abc                           # Start work on specific bead (tab)"
  echo "  /dots-swe:dispatch dots-abc dots-def dots-xyz         # Dispatch multiple beads"
  echo "  /dots-swe:dispatch --window dots-abc                  # Open in new window"
  echo "  /dots-swe:dispatch --model sonnet dots-abc            # Use sonnet model"
  echo "  /dots-swe:dispatch                                    # Open tab for current worktree"
  echo "  /dots-swe:dispatch --dry-run dots-abc                 # Preview what would happen"
  echo ""
  echo "See also:"
  echo "  bd ready          # Find available work"
  echo "  bd show <id>      # Preview bead details"
  exit 0
fi

# Validate arguments - try to detect from .swe-bead if not provided
if [ ${#BEAD_IDS[@]} -eq 0 ]; then
  CURRENT_BEAD=$(get_current_bead)
  if [ -z "$CURRENT_BEAD" ]; then
    echo "ERROR: No bead ID provided and not in a worktree"
    echo ""
    echo "Usage: /dots-swe:dispatch [options] <bead-id...>"
    echo ""
    echo "Available work:"
    bd ready 2>/dev/null || echo "  (bd command not available)"
    exit 1
  fi
  echo "Detected bead from current worktree: $CURRENT_BEAD"
  echo ""
  BEAD_IDS=("$CURRENT_BEAD")
fi

# Dispatch each bead
BEAD_COUNT=0
for BEAD_ID in "${BEAD_IDS[@]}"; do
  BEAD_COUNT=$((BEAD_COUNT + 1))
  if [ ${#BEAD_IDS[@]} -gt 1 ]; then
    echo ""
    echo "Dispatching: $BEAD_ID ($BEAD_COUNT of ${#BEAD_IDS[@]})"
    echo ""
  fi

  echo "Starting Work from Bead"
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
  MODE="${SWE_GHOSTTY_MODE:-tab}"

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
    echo "   Reattach: /dots-swe:dispatchtree-attach"
  fi

  echo ""
  echo "Run without --dry-run to execute"
  echo "Add --window to open in a Ghostty window instead of tab"
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
  MODEL="${MODEL:-sonnet}"
  open_worktree_session "$WORKTREE_PATH" "$BEAD_ID" "$MODEL"
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

**CRITICAL:** Run \`/dots-swe:code-complete\` when code is ready (REQUIRED before closing bead)
  - This runs tests, lint, build, pushes code, and marks bead ready for merge
  - DO NOT skip this step - it's required by the SESSION CLOSE PROTOCOL

- Run \`/dots-swe:process-check\` for interim quality checks (test/lint/build only)
- Update bead status: \`bd update $BEAD_ID --status=<status>\`
  - Statuses: \`in_progress\`, \`blocked\`, \`open\`, \`closed\`
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

# Install quality hook
echo "Installing quality hook..."

# Check if we're in a worktree (.git is a file) or main repo (.git is a directory)
if [ -f "$WORKTREE_PATH/.git" ]; then
  # In a worktree - hooks are shared from main repo
  echo "✅ Using shared hooks from main repo"
else
  # In main repo - install hook locally
  HOOK_DIR="$WORKTREE_PATH/.git/hooks"
  HOOK_PATH="$HOOK_DIR/pre-commit"
  # Find the hook script in the plugin cache
  HOOK_SCRIPT=$(ls -t ${DOTS_SWE_DEV:-/nonexistent}/scripts/pre-commit-quality-hook.sh $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/pre-commit-quality-hook.sh 2>/dev/null | head -1)

  if [ -n "$HOOK_SCRIPT" ] && [ -f "$HOOK_SCRIPT" ]; then
    mkdir -p "$HOOK_DIR"
    cp "$HOOK_SCRIPT" "$HOOK_PATH"
    chmod +x "$HOOK_PATH"
    echo "✅ Quality hook installed"
  else
    echo "⚠️  Could not find quality hook script (continuing anyway)"
  fi
fi
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

echo "✅ Ready to work!"
echo ""
echo "Worktree: $WORKTREE_PATH"
echo "Branch: $BEAD_ID"
echo "Bead: $BEAD_ID"
echo ""
echo "Check .swe-context for task details and quick reference."
echo ""

# Opens new terminal window/tab with Claude session
MODEL="${MODEL:-sonnet}"
TERMINAL=$(get_swe_terminal)

# For Ghostty, start zmx session in background first
if [ "$TERMINAL" = "ghostty" ]; then
  echo "Starting zmx session with model: $MODEL"
  start_zmx_session_background "$WORKTREE_PATH" "$BEAD_ID" false "$MODEL"
fi

# Open terminal and attach to session
open_worktree_session "$WORKTREE_PATH" "$BEAD_ID" "$MODEL"

echo "✅ Claude session opened in new terminal."

  # Small delay between dispatches to avoid overwhelming the system
  if [ ${#BEAD_IDS[@]} -gt 1 ]; then
    sleep 0.5
  fi
done

# Summary if multiple beads
if [ ${#BEAD_IDS[@]} -gt 1 ]; then
  echo ""
  echo "✅ Dispatched ${#BEAD_IDS[@]} beads successfully"
fi
