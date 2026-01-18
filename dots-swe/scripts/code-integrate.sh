#!/bin/bash
# Batch integration of merged swe:done work

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Parse flags
DRY_RUN=false
FORCE=false
NO_REMOTE=false
BEAD_IDS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --force|-f) FORCE=true ;;
    --no-remote) NO_REMOTE=true ;;
    --help|-h) ;; # handled below
    *) BEAD_IDS+=("$arg") ;;
  esac
done

# Help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:code-integrate [options] [bead-id...]"
  echo ""
  echo "Batch integration of merged swe:done work."
  echo ""
  echo "Options:"
  echo "  --dry-run, -n    Show what would happen without doing it"
  echo "  --force, -f      Skip merge verification (use with caution)"
  echo "  --no-remote      Skip remote branch deletion"
  echo ""
  echo "Behavior:"
  echo "  Without bead IDs: processes ALL swe:done beads that are merged"
  echo "  With bead IDs: processes only specified beads"
  echo ""
  echo "For each merged bead:"
  echo "  1. Kill zmx/tmux session"
  echo "  2. Delete worktree"
  echo "  3. Delete local branch"
  echo "  4. Delete remote branch (unless --no-remote)"
  echo "  5. Close bead"
  echo "  6. Remove swe:done label"
  echo ""
  echo "Examples:"
  echo "  /dots-swe:code-integrate                    # Integrate all merged work"
  echo "  /dots-swe:code-integrate dots-abc           # Integrate specific bead"
  echo "  /dots-swe:code-integrate --dry-run          # Preview what would happen"
  echo "  /dots-swe:code-integrate --no-remote        # Keep remote branches"
  echo ""
  echo "See also:"
  echo "  /dots-swe:code-integrate-status    # Show what's ready for integration"
  exit 0
fi

WORKTREES_DIR=$(get_worktrees_dir)
TERMINAL=$(get_swe_terminal)

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Batch Integration                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Get beads to process
if [ ${#BEAD_IDS[@]} -eq 0 ]; then
  # No beads specified - get all swe:done beads
  echo "📋 Finding all swe:done labeled beads..."
  BEADS_JSON=$(bd list --label swe:done --json 2>/dev/null)

  if [ -z "$BEADS_JSON" ] || [ "$BEADS_JSON" = "[]" ]; then
    echo "ℹ️  No beads with swe:done label found."
    exit 0
  fi

  # Extract bead IDs
  mapfile -t BEAD_IDS < <(echo "$BEADS_JSON" | jq -r '.[].id')
  echo "   Found ${#BEAD_IDS[@]} bead(s) with swe:done label"
  echo ""
else
  echo "📋 Processing ${#BEAD_IDS[@]} specified bead(s)..."
  echo ""
fi

# Filter for merged beads (unless --force)
TO_INTEGRATION=()
SKIPPED=()

for BEAD_ID in "${BEAD_IDS[@]}"; do
  # Check merge status
  MERGE_STATUS=$(is_branch_merged "$BEAD_ID")

  if [ "$FORCE" = true ] || [ "$MERGE_STATUS" != "no" ]; then
    TO_INTEGRATION+=("$BEAD_ID")
  else
    SKIPPED+=("$BEAD_ID")
  fi
done

if [ ${#TO_INTEGRATION[@]} -eq 0 ]; then
  echo "ℹ️  No merged beads to clean up."
  echo ""
  if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo "Skipped (not merged):"
    for BEAD_ID in "${SKIPPED[@]}"; do
      echo "  - $BEAD_ID"
    done
    echo ""
    echo "Use --force to clean up anyway (not recommended)"
  fi
  exit 0
fi

# Show what will be cleaned
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Will clean up ${#TO_INTEGRATION[@]} bead(s):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for BEAD_ID in "${TO_INTEGRATION[@]}"; do
  MERGE_STATUS=$(is_branch_merged "$BEAD_ID")
  RESOURCES=$(get_integration_resources "$BEAD_ID")

  STATUS_LABEL="MERGED"
  [ "$MERGE_STATUS" = "local" ] && STATUS_LABEL="MERGED (local)"
  [ "$MERGE_STATUS" = "pr" ] && STATUS_LABEL="MERGED (PR)"
  [ "$FORCE" = true ] && STATUS_LABEL="FORCED"

  echo "  • $BEAD_ID [$STATUS_LABEL]"
  [ -n "$RESOURCES" ] && echo "    Resources: $RESOURCES"
done

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo ""
  echo "Skipped (not merged):"
  for BEAD_ID in "${SKIPPED[@]}"; do
    echo "  - $BEAD_ID"
  done
fi

echo ""

# Dry run mode
if [ "$DRY_RUN" = true ]; then
  echo "📋 DRY RUN: Here's what would happen for each bead"
  echo ""
  echo "  1. Kill session (zmx/tmux)"
  echo "  2. Remove worktree"
  echo "  3. Delete local branch"
  [ "$NO_REMOTE" = false ] && echo "  4. Delete remote branch"
  [ "$NO_REMOTE" = true ] && echo "  4. Keep remote branch (--no-remote)"
  echo "  5. Close bead"
  echo "  6. Remove swe:done label"
  echo "  7. Sync beads"
  echo ""
  echo "Run without --dry-run to execute"
  exit 0
fi

# Confirm before proceeding
if [ ${#TO_INTEGRATION[@]} -gt 1 ]; then
  echo "⚠️  About to clean up ${#TO_INTEGRATION[@]} beads. This will:"
  echo "   • Delete worktrees, branches, and sessions"
  echo "   • Close beads"
  [ "$NO_REMOTE" = false ] && echo "   • Delete remote branches"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Starting integration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CLEANED_COUNT=0
ERROR_COUNT=0

for BEAD_ID in "${TO_INTEGRATION[@]}"; do
  echo "🔄 Cleaning up: $BEAD_ID"

  WORKTREE_PATH="$WORKTREES_DIR/$BEAD_ID"
  BRANCH="$BEAD_ID"
  INTEGRATION_ERROR=false

  # 1. Kill session
  if [ "$TERMINAL" = "ghostty" ]; then
    if zmx_session_exists "$BEAD_ID"; then
      echo "   Killing zmx session..."
      kill_zmx_session "$BEAD_ID" 2>/dev/null || echo "   Warning: Could not kill session"
    fi
  else
    if tmux_session_exists "$BEAD_ID"; then
      echo "   Killing tmux session..."
      tmux kill-session -t "$BEAD_ID" 2>/dev/null || echo "   Warning: Could not kill session"
    fi
  fi

  # 2. Remove worktree
  if [ -d "$WORKTREE_PATH" ]; then
    echo "   Removing worktree..."
    git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || {
      echo "   Warning: Could not remove worktree"
      INTEGRATION_ERROR=true
    }
  fi

  # 3. Delete local branch
  if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "   Deleting local branch..."
    git branch -D "$BRANCH" 2>/dev/null || {
      echo "   Warning: Could not delete local branch"
      INTEGRATION_ERROR=true
    }
  fi

  # 4. Delete remote branch
  if [ "$NO_REMOTE" = false ]; then
    if git ls-remote --heads origin "$BRANCH" 2>/dev/null | grep -q .; then
      echo "   Deleting remote branch..."
      git push origin --delete "$BRANCH" 2>/dev/null || {
        echo "   Warning: Could not delete remote branch"
        INTEGRATION_ERROR=true
      }
    fi
  fi

  # 5. Close bead
  echo "   Closing bead..."
  bd close "$BEAD_ID" 2>/dev/null || {
    echo "   Warning: Could not close bead"
    INTEGRATION_ERROR=true
  }

  # 6. Remove label
  bd label remove "$BEAD_ID" swe:done 2>/dev/null

  # 7. Unregister from global registry
  if [ -n "$WORKTREE_PATH" ]; then
    unregister_worktree "$WORKTREE_PATH" 2>/dev/null
  fi

  if [ "$INTEGRATION_ERROR" = true ]; then
    echo "   ⚠️  Completed with warnings"
    ERROR_COUNT=$((ERROR_COUNT + 1))
  else
    echo "   ✅ Integration complete"
    CLEANED_COUNT=$((CLEANED_COUNT + 1))
  fi

  echo ""
done

# Sync beads
echo "Syncing beads..."
bd sync 2>/dev/null

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Integration Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Cleaned: $CLEANED_COUNT"
if [ $ERROR_COUNT -gt 0 ]; then
  echo "  With warnings: $ERROR_COUNT"
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo "  Skipped: ${#SKIPPED[@]}"
fi
echo ""

if [ $CLEANED_COUNT -gt 0 ]; then
  echo "✅ Integration complete!"
fi
