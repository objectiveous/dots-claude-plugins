#!/bin/bash
# Batch integration of merged swe:code-complete work

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Parse flags
DRY_RUN=false
FORCE=false
NO_REMOTE=false
MERGE_MODE=""
BEAD_IDS=()

# Help flag (check first before validation)
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:code-integrate [options] [bead-id...]"
  echo ""
  echo "Integrate swe:code-complete work into main and clean up resources."
  echo ""
  echo "Required Merge Mode (choose one):"
  echo "  --local          Merge branch directly to main (no PR)"
  echo "  --remote         Create/use GitHub PR for merge"
  echo ""
  echo "Options:"
  echo "  --dry-run, -n    Show what would happen without doing it"
  echo "  --force, -f      Skip merge verification (use with caution)"
  echo "  --no-remote      Skip remote branch deletion"
  echo ""
  echo "Behavior:"
  echo "  Without bead IDs: processes ALL swe:code-complete beads"
  echo "  With bead IDs: processes only specified beads"
  echo ""
  echo "Merge Modes:"
  echo "  --local mode:"
  echo "    • Switches to main, pulls latest"
  echo "    • Merges branch with --no-ff"
  echo "    • Pushes to origin"
  echo "    • Proceeds to cleanup"
  echo ""
  echo "  --remote mode:"
  echo "    • Creates PR if needed (or finds existing)"
  echo "    • Shows PR URL and state"
  echo "    • If PR is open: skips with message to merge manually"
  echo "    • If PR is merged: proceeds to cleanup"
  echo ""
  echo "For each bead:"
  echo "  1. Merge to main if not already merged (per merge mode)"
  echo "  2. Kill zmx/tmux session"
  echo "  3. Delete worktree"
  echo "  4. Delete local branch"
  echo "  5. Delete remote branch (unless --no-remote)"
  echo "  6. Close bead"
  echo "  7. Remove swe:code-complete label"
  echo ""
  echo "Examples:"
  echo "  /dots-swe:code-integrate --remote                  # PR workflow for all"
  echo "  /dots-swe:code-integrate --local dots-abc          # Local merge for one"
  echo "  /dots-swe:code-integrate --remote --dry-run        # Preview PR workflow"
  echo "  /dots-swe:code-integrate --local --no-remote       # Local merge, keep remote branch"
  echo ""
  echo "See also:"
  echo "  /dots-swe:code-integrate-status    # Show what's ready for integration"
  exit 0
fi

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --force|-f) FORCE=true ;;
    --no-remote) NO_REMOTE=true ;;
    --local) MERGE_MODE="local" ;;
    --remote) MERGE_MODE="remote" ;;
    *) BEAD_IDS+=("$arg") ;;
  esac
done

# Validate merge mode
if [ -z "$MERGE_MODE" ]; then
  echo "ERROR: Must specify merge mode: --local or --remote"
  echo ""
  echo "  --local   Merge branch directly to main (no PR)"
  echo "  --remote  Create/use GitHub PR for merge"
  echo ""
  echo "Run with --help for full usage."
  exit 1
fi

WORKTREES_DIR=$(get_worktrees_dir)
TERMINAL=$(get_swe_terminal)

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Code Integration                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Merge mode: $MERGE_MODE"
echo ""

# Get beads to process
if [ ${#BEAD_IDS[@]} -eq 0 ]; then
  # No beads specified - get all swe:code-complete beads
  echo "📋 Finding all swe:code-complete labeled beads..."
  BEADS_JSON=$(bd list --label swe:code-complete --json 2>/dev/null)

  if [ -z "$BEADS_JSON" ] || [ "$BEADS_JSON" = "[]" ]; then
    echo "ℹ️  No beads with swe:code-complete label found."
    exit 0
  fi

  # Extract bead IDs
  mapfile -t BEAD_IDS < <(echo "$BEADS_JSON" | jq -r '.[].id')
  echo "   Found ${#BEAD_IDS[@]} bead(s) with swe:code-complete label"
  echo ""
else
  echo "📋 Processing ${#BEAD_IDS[@]} specified bead(s)..."
  echo ""
fi

# Process beads - merge if needed, then clean up
TO_INTEGRATION=()
SKIPPED=()
MERGE_FAILED=()

for BEAD_ID in "${BEAD_IDS[@]}"; do
  # Check merge status
  MERGE_STATUS=$(is_branch_merged "$BEAD_ID")

  if [ "$FORCE" = true ] || [ "$MERGE_STATUS" != "no" ]; then
    # Already merged or forced
    TO_INTEGRATION+=("$BEAD_ID")
  else
    # Not merged yet - try to merge based on merge mode
    echo "🔄 $BEAD_ID is not merged yet. Attempting integration..."

    if [ "$MERGE_MODE" = "remote" ]; then
      # GitHub PR workflow
      PR_NUMBER=$(create_or_find_pr "$BEAD_ID" "main" 2>&1)
      if [ -n "$PR_NUMBER" ] && [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
        PR_URL=$(gh pr view "$PR_NUMBER" --json url --jq '.url' 2>/dev/null)
        PR_STATE=$(gh pr view "$PR_NUMBER" --json state --jq '.state' 2>/dev/null)

        echo "   PR #$PR_NUMBER: $PR_URL"
        echo "   State: $PR_STATE"

        if [ "$PR_STATE" = "OPEN" ]; then
          echo "   ⏳ PR is open but not merged. Skipping for now."
          echo "      Merge the PR manually or wait for CI, then run code-integrate again."
          SKIPPED+=("$BEAD_ID")
          echo ""
          continue
        elif [ "$PR_STATE" = "MERGED" ]; then
          echo "   ✅ PR already merged"
          TO_INTEGRATION+=("$BEAD_ID")
        fi
      else
        echo "   ❌ $PR_NUMBER"
        MERGE_FAILED+=("$BEAD_ID")
        echo ""
        continue
      fi
    else
      # Local merge workflow
      echo "   Merging locally to main..."
      if merge_branch_to_main "$BEAD_ID"; then
        echo "   ✅ Merged to main"
        TO_INTEGRATION+=("$BEAD_ID")
      else
        echo "   ❌ Merge failed - may have conflicts"
        MERGE_FAILED+=("$BEAD_ID")
        echo ""
        continue
      fi
    fi

    echo ""
  fi
done

if [ ${#TO_INTEGRATION[@]} -eq 0 ]; then
  echo "ℹ️  No beads ready for integration."
  echo ""
  if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo "Skipped (PR not merged yet):"
    for BEAD_ID in "${SKIPPED[@]}"; do
      echo "  - $BEAD_ID (merge PR manually, then run code-integrate again)"
    done
    echo ""
  fi
  if [ ${#MERGE_FAILED[@]} -gt 0 ]; then
    echo "Failed to merge:"
    for BEAD_ID in "${MERGE_FAILED[@]}"; do
      echo "  - $BEAD_ID (check for conflicts or PR issues)"
    done
    echo ""
  fi
  if [ ${#SKIPPED[@]} -eq 0 ] && [ ${#MERGE_FAILED[@]} -eq 0 ]; then
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
  echo "Skipped (PR not merged yet):"
  for BEAD_ID in "${SKIPPED[@]}"; do
    echo "  - $BEAD_ID"
  done
fi

if [ ${#MERGE_FAILED[@]} -gt 0 ]; then
  echo ""
  echo "Failed to merge:"
  for BEAD_ID in "${MERGE_FAILED[@]}"; do
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
  echo "  6. Remove swe:code-complete label"
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
  bd label remove "$BEAD_ID" swe:code-complete 2>/dev/null

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
echo "  Integrated: $CLEANED_COUNT"
if [ $ERROR_COUNT -gt 0 ]; then
  echo "  With warnings: $ERROR_COUNT"
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo "  Skipped (PR pending): ${#SKIPPED[@]}"
fi
if [ ${#MERGE_FAILED[@]} -gt 0 ]; then
  echo "  Failed to merge: ${#MERGE_FAILED[@]}"
fi
echo ""

if [ $CLEANED_COUNT -gt 0 ]; then
  echo "✅ Integration complete!"
fi
