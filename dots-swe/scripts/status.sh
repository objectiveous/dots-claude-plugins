#!/bin/bash
# Show comprehensive status of SWE work and beads

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                      SWE Work Status                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if bd is available
if ! command -v bd >/dev/null 2>&1; then
  echo "⚠️  beads (bd) is not installed or not in PATH"
  echo ""
  echo "Install beads to track issues and work:"
  echo "  npm install -g @dotslabs/beads"
  exit 1
fi

# Check if .beads directory exists
if [ ! -d ".beads" ]; then
  echo "ℹ️  No beads initialized in this repository"
  echo ""
  echo "Initialize beads with:"
  echo "  bd init"
  exit 0
fi

# Get current bead if in a worktree
CURRENT_BEAD=$(get_current_bead)
if [ -n "$CURRENT_BEAD" ]; then
  echo "📍 Current worktree: $CURRENT_BEAD"
  echo ""
fi

# ═══════════════════════════════════════════════════════════════════
# Active Epic
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 Active Epic"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Try to find open epics
OPEN_EPICS=$(bd list --type=epic --status=open 2>/dev/null | grep -v "^$")
if [ -n "$OPEN_EPICS" ]; then
  echo "$OPEN_EPICS" | head -1
  EPIC_COUNT=$(echo "$OPEN_EPICS" | wc -l | tr -d ' ')
  if [ "$EPIC_COUNT" -gt 1 ]; then
    echo ""
    echo "  (and $((EPIC_COUNT - 1)) other open epic(s))"
  fi
else
  echo "  No active epics"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════
# Git Worktrees
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌳 Git Worktrees"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

REPO_ROOT=$(get_repo_root)
WORKTREE_COUNT=0
WORKTREE_ISSUES=0

# Parse git worktree list
while IFS= read -r line; do
  case "$line" in
    worktree*)
      WORKTREE_PATH="${line#worktree }"
      # Skip main worktree
      if [ "$WORKTREE_PATH" != "$REPO_ROOT" ]; then
        BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "detached")
        BEAD_ID=$(basename "$WORKTREE_PATH")

        # Get bead status if exists
        BEAD_STATUS=$(bd show "$BEAD_ID" 2>/dev/null | grep "Status:" | awk '{print $2}' || echo "n/a")

        # Check for uncommitted changes
        CHANGES=$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

        # Check for unpushed commits
        git -C "$WORKTREE_PATH" fetch origin "$BRANCH" --quiet 2>/dev/null || true
        AHEAD=$(git -C "$WORKTREE_PATH" rev-list --count origin/$BRANCH..HEAD 2>/dev/null || echo "0")
        BEHIND=$(git -C "$WORKTREE_PATH" rev-list --count HEAD..origin/$BRANCH 2>/dev/null || echo "0")

        # Build status line
        STATUS_LINE="$BEAD_ID ($BRANCH)"

        # Add bead status
        if [ "$BEAD_STATUS" != "n/a" ]; then
          STATUS_LINE="$STATUS_LINE [bead: $BEAD_STATUS]"
        fi

        # Add git status
        DETAILS=""
        if [ "$CHANGES" -gt 0 ]; then
          DETAILS="$CHANGES uncommitted"
          WORKTREE_ISSUES=$((WORKTREE_ISSUES + 1))
        fi

        if [ "$AHEAD" -gt 0 ]; then
          [ -n "$DETAILS" ] && DETAILS="$DETAILS, "
          DETAILS="${DETAILS}↑$AHEAD unpushed"
          WORKTREE_ISSUES=$((WORKTREE_ISSUES + 1))
        fi

        if [ "$BEHIND" -gt 0 ]; then
          [ -n "$DETAILS" ] && DETAILS="$DETAILS, "
          DETAILS="${DETAILS}↓$BEHIND behind origin"
          WORKTREE_ISSUES=$((WORKTREE_ISSUES + 1))
        fi

        if [ -z "$DETAILS" ]; then
          DETAILS="✓ clean, synced"
        fi

        echo "  $STATUS_LINE"
        echo "    $DETAILS"

        WORKTREE_COUNT=$((WORKTREE_COUNT + 1))
      fi
      ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null)

if [ "$WORKTREE_COUNT" -eq 0 ]; then
  echo "  No active worktrees"
else
  echo ""
  if [ "$WORKTREE_ISSUES" -gt 0 ]; then
    echo "  ⚠️  $WORKTREE_ISSUES worktree(s) need attention"
  else
    echo "  ✅ All worktrees clean and synced"
  fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════════
# In-Flight Work (Beads)
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 In-Flight Work (Beads)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

IN_PROGRESS=$(bd list --status=in_progress 2>/dev/null | grep -v "^$")
if [ -n "$IN_PROGRESS" ]; then
  echo "$IN_PROGRESS"
else
  echo "  No beads currently in progress"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════
# Ready to Work
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Ready to Work (No Blockers)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

READY_WORK=$(bd ready 2>/dev/null | grep -v "^$")
if [ -n "$READY_WORK" ]; then
  echo "$READY_WORK"
else
  echo "  No ready work available"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════
# Ready to Merge
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎁 Ready to Integrate"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for issues marked with swe:done label
SWE_DONE=$(bd list --label swe:done 2>/dev/null | grep -v "^$")
if [ -n "$SWE_DONE" ]; then
  echo "Code complete (swe:done label):"
  echo "$SWE_DONE"
  echo ""
  echo "  Run: /dots-swe:code-integrate-status for details"
  echo ""
fi

# Check for worktrees that might need finishing (exist but not in_progress)
# This catches work that's been completed but not properly closed
WORKTREES_DIR=$(get_worktrees_dir)
if [ -d "$WORKTREES_DIR" ]; then
  UNFINISHED_WORKTREES=""
  for worktree in "$WORKTREES_DIR"/*; do
    if [ -d "$worktree" ]; then
      BEAD_ID=$(basename "$worktree")
      # Check if this bead is in_progress
      BEAD_STATUS=$(bd show "$BEAD_ID" 2>/dev/null | grep "Status:" | awk '{print $2}')

      if [ "$BEAD_STATUS" != "in_progress" ] && [ "$BEAD_STATUS" != "open" ]; then
        if [ -z "$UNFINISHED_WORKTREES" ]; then
          echo "Worktrees that may need finishing:"
        fi
        echo "  $BEAD_ID (status: ${BEAD_STATUS:-unknown})"
        UNFINISHED_WORKTREES="found"
      fi
    fi
  done

  if [ -n "$UNFINISHED_WORKTREES" ]; then
    echo ""
    echo "  Use: /dots-swe:code-integrate <bead-id>"
    echo ""
  fi
fi

if [ -z "$READY_TO_MERGE" ] && [ -z "$UNFINISHED_WORKTREES" ]; then
  echo "  No work ready to merge or finish"
  echo ""
fi

# ═══════════════════════════════════════════════════════════════════
# Blocked Work
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚫 Blocked Work"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BLOCKED=$(bd blocked 2>/dev/null | grep -v "^$")
if [ -n "$BLOCKED" ]; then
  echo "$BLOCKED"
else
  echo "  No blocked work"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════
# Project Statistics
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Project Statistics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

STATS=$(bd stats 2>/dev/null)
if [ -n "$STATS" ]; then
  echo "$STATS"
else
  echo "  No statistics available"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════
# Quick Actions
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ Quick Actions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Start work:     /dots-swe:dispatch <bead-id>"
echo "Continue work:  /dots-swe:continue <bead-id>"
echo "Code complete:  /dots-swe:code-complete"
echo "Integrate code: /dots-swe:code-integrate <bead-id>"
echo "Health check:   /dots-swe:doctor"
echo ""
