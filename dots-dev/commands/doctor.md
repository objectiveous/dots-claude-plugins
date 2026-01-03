---
description: "Health check for worktrees, branches, and beads"
allowed-tools: ["Bash"]
---

# Dots Dev Doctor

Checks for common issues: stale branches, uncommitted work, orphaned worktrees, beads out of sync.

**Usage:** `/dots-dev:doctor`

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:doctor"
  echo ""
  echo "Health check for worktrees, branches, and beads."
  echo ""
  echo "Checks performed:"
  echo "  1. Stale git worktree references"
  echo "  2. Worktrees with uncommitted changes"
  echo "  3. Worktrees with unpushed commits"
  echo "  4. Stale registry entries"
  echo "  5. Merged branches not deleted"
  echo "  6. Beads sync status (via bd doctor)"
  echo "  7. Main branch status vs origin"
  echo ""
  echo "See also: /dots-dev:worktree-cleanup (fix stale entries)"
  exit 0
fi

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                     dots-dev Doctor                          ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!ISSUES_FOUND=0
!REPO_ROOT=$(get_repo_root)
!REGISTRY_FILE=$(get_registry_file)

# Check 1: Stale git worktree references
!echo "🔍 Checking for stale worktree references..."
!STALE_WORKTREES=$(git worktree list --porcelain | grep -c "prunable" 2>/dev/null || echo "0")
!if [ "$STALE_WORKTREES" -gt 0 ]; then
  echo "   ⚠️  Found $STALE_WORKTREES stale worktree reference(s)"
  echo "   Fix: git worktree prune"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo "   ✅ No stale worktree references"
fi
!echo ""

# Check 2: Worktrees with uncommitted changes
!echo "🔍 Checking for uncommitted changes in worktrees..."
!git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2- | while read path; do
  if [ "$path" != "$REPO_ROOT" ] && [ -d "$path" ]; then
    CHANGES=$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGES" -gt 0 ]; then
      BRANCH=$(git -C "$path" branch --show-current 2>/dev/null || echo "unknown")
      echo "   ⚠️  $BRANCH: $CHANGES uncommitted changes"
      echo "      Path: $path"
    fi
  fi
done
!echo "   (Check complete)"
!echo ""

# Check 3: Worktrees with unpushed commits
!echo "🔍 Checking for unpushed commits..."
!git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2- | while read path; do
  if [ "$path" != "$REPO_ROOT" ] && [ -d "$path" ]; then
    UNPUSHED=$(git -C "$path" log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNPUSHED" -gt 0 ]; then
      BRANCH=$(git -C "$path" branch --show-current 2>/dev/null || echo "unknown")
      echo "   ⚠️  $BRANCH: $UNPUSHED unpushed commits"
    fi
  fi
done
!echo "   (Check complete)"
!echo ""

# Check 4: Registry entries pointing to non-existent paths
!echo "🔍 Checking worktree registry..."
!if [ -f "$REGISTRY_FILE" ]; then
  STALE_ENTRIES=$(jq -r 'keys[]' "$REGISTRY_FILE" 2>/dev/null | while read path; do
    if [ ! -d "$path" ]; then
      echo "$path"
    fi
  done | wc -l | tr -d ' ')

  if [ "$STALE_ENTRIES" -gt 0 ]; then
    echo "   ⚠️  Found $STALE_ENTRIES stale registry entries"
    echo "   Fix: /dots-dev:worktree-cleanup"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  else
    echo "   ✅ Registry is clean"
  fi
else
  echo "   ℹ️  No registry file found (this is fine if no worktrees created)"
fi
!echo ""

# Check 5: Branches that have been merged but not deleted
!echo "🔍 Checking for merged branches..."
!MERGED_COUNT=$(git branch --merged main 2>/dev/null | grep -v "^\*" | grep -v "main" | wc -l | tr -d ' ')
!if [ "$MERGED_COUNT" -gt 0 ]; then
  echo "   ⚠️  Found $MERGED_COUNT branches merged to main but not deleted:"
  git branch --merged main 2>/dev/null | grep -v "^\*" | grep -v "main" | sed 's/^/      /'
  echo "   Fix: git branch -d <branch-name>"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo "   ✅ No stale merged branches"
fi
!echo ""

# Check 6: Beads sync status (if bd available)
!echo "🔍 Checking beads status..."
!if command -v bd &> /dev/null; then
  BD_DOCTOR=$(bd doctor 2>&1)
  if echo "$BD_DOCTOR" | grep -qi "error\|warning\|issue"; then
    echo "   ⚠️  Beads issues detected:"
    echo "$BD_DOCTOR" | sed 's/^/      /'
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  else
    echo "   ✅ Beads look healthy"
  fi
else
  echo "   ℹ️  bd (beads) not available"
fi
!echo ""

# Check 7: Main branch status
!echo "🔍 Checking main branch..."
!git fetch origin main --dry-run 2>&1 | head -5
!BEHIND=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "0")
!if [ "$BEHIND" -gt 0 ]; then
  echo "   ⚠️  Main is $BEHIND commits behind origin/main"
  echo "   Fix: git checkout main && git pull"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo "   ✅ Main is up to date"
fi
!echo ""

# Summary
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!if [ "$ISSUES_FOUND" -gt 0 ]; then
  echo "Found potential issues. See recommendations above."
else
  echo "✅ All checks passed!"
fi
!echo ""
