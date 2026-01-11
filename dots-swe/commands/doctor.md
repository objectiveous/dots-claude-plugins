---
description: "Health check for repository and worktrees"
allowed-tools: ["Bash"]
---

# Doctor - Health Check

Checks repository health: stale worktrees, uncommitted changes, unpushed commits, and beads sync status.

**Usage:** `/dots-swe:doctor`

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/swe-lib.sh"

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                    Repository Health Check                   ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!REPO_ROOT=$(get_repo_root)
!ISSUES_FOUND=0

# Check 1: Main branch status
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Main Branch Status"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""

!CURRENT_BRANCH=$(git branch --show-current)
!echo "Current branch: $CURRENT_BRANCH"

!if [ "$CURRENT_BRANCH" = "main" ]; then
  # Check if main is up to date
  git fetch origin main --quiet 2>/dev/null
  BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
  AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")

  if [ "$BEHIND" -gt 0 ]; then
    echo "⚠️  Main is $BEHIND commits behind origin"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  elif [ "$AHEAD" -gt 0 ]; then
    echo "⚠️  Main is $AHEAD commits ahead of origin"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  else
    echo "✅ Main is up to date with origin"
  fi
else
  echo "ℹ️  Not on main branch"
fi
!echo ""

# Check 2: Uncommitted changes
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Uncommitted Changes"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""

!CHANGES=$(git status --porcelain | wc -l | tr -d ' ')
!if [ "$CHANGES" -gt 0 ]; then
  echo "⚠️  $CHANGES uncommitted changes in current directory"
  git status --short
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo "✅ No uncommitted changes"
fi
!echo ""

# Check 3: Worktrees with uncommitted changes
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Worktree Status"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""

!WORKTREE_ISSUES=0
!git worktree list --porcelain | while IFS= read -r line; do
  case "$line" in
    worktree*)
      WORKTREE_PATH="${line#worktree }"
      if [ "$WORKTREE_PATH" != "$REPO_ROOT" ]; then
        BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "detached")
        WT_CHANGES=$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

        if [ "$WT_CHANGES" -gt 0 ]; then
          echo "⚠️  $BRANCH: $WT_CHANGES uncommitted changes"
          WORKTREE_ISSUES=$((WORKTREE_ISSUES + 1))
        fi
      fi
      ;;
  esac
done

!if [ "$WORKTREE_ISSUES" -eq 0 ]; then
  echo "✅ All worktrees clean"
else
  echo ""
  echo "⚠️  $WORKTREE_ISSUES worktrees with uncommitted changes"
  ISSUES_FOUND=$((ISSUES_FOUND + WORKTREE_ISSUES))
fi
!echo ""

# Check 4: Beads sync
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Beads Sync Status"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""

!if command -v bd >/dev/null 2>&1; then
  # Check if beads is in sync
  if bd sync --dry-run 2>&1 | grep -q "nothing to sync"; then
    echo "✅ Beads in sync"
  else
    echo "⚠️  Beads needs sync - run: bd sync"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  fi
else
  echo "ℹ️  Beads not installed"
fi
!echo ""

# Summary
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "Summary"
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo ""

!if [ "$ISSUES_FOUND" -eq 0 ]; then
  echo "✅ All checks passed! Repository is healthy."
else
  echo "⚠️  Found $ISSUES_FOUND issue(s)"
  echo ""
  echo "Recommendations:"
  echo "  - Commit or stash uncommitted changes"
  echo "  - Sync worktrees with /dots-swe:worktree-sync"
  echo "  - Run bd sync to synchronize beads"
fi
