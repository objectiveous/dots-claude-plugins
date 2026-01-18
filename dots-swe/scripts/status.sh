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
# In-Flight Work
# ═══════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 In-Flight Work"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

IN_PROGRESS=$(bd list --status=in_progress 2>/dev/null | grep -v "^$")
if [ -n "$IN_PROGRESS" ]; then
  echo "$IN_PROGRESS"

  # Show which ones have active worktrees
  echo ""
  echo "Active worktrees:"
  WORKTREES_DIR=$(get_worktrees_dir)
  if [ -d "$WORKTREES_DIR" ]; then
    WORKTREE_COUNT=0
    for worktree in "$WORKTREES_DIR"/*; do
      if [ -d "$worktree" ]; then
        BEAD_ID=$(basename "$worktree")
        BRANCH=$(cd "$worktree" && git branch --show-current 2>/dev/null || echo "unknown")
        CHANGES=$(cd "$worktree" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

        if [ "$CHANGES" -gt 0 ]; then
          echo "  $BEAD_ID ($BRANCH) - $CHANGES uncommitted changes"
        else
          echo "  $BEAD_ID ($BRANCH) - clean"
        fi
        WORKTREE_COUNT=$((WORKTREE_COUNT + 1))
      fi
    done

    if [ "$WORKTREE_COUNT" -eq 0 ]; then
      echo "  (no worktrees found)"
    fi
  else
    echo "  (no worktrees directory)"
  fi
else
  echo "  No work currently in progress"
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
echo "🎁 Ready to Merge/Finish"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for issues marked ready_to_merge
READY_TO_MERGE=$(bd list --status=ready_to_merge 2>/dev/null | grep -v "^$")
if [ -n "$READY_TO_MERGE" ]; then
  echo "Marked ready to merge:"
  echo "$READY_TO_MERGE"
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
    echo "  Use: /dots-swe:finish <bead-id>"
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
echo "Ship work:      /dots-swe:done"
echo "Finish work:    /dots-swe:finish <bead-id>"
echo "Health check:   /dots-swe:doctor"
echo ""
