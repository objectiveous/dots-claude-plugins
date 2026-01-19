#!/bin/bash
# Visualize bead dependency graphs and relationships

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Parse arguments
BEAD_ID=""
DIRECTION="both"
OUTPUT_FORMAT="tree"
STATUS_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --up)
      DIRECTION="up"
      shift
      ;;
    --down)
      DIRECTION="down"
      shift
      ;;
    --mermaid)
      OUTPUT_FORMAT="mermaid"
      shift
      ;;
    --status=*)
      STATUS_FILTER="${1#*=}"
      shift
      ;;
    --*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      BEAD_ID="$1"
      shift
      ;;
  esac
done

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

# =============================================================================
# Mode 1: Project Overview (no bead ID specified)
# =============================================================================
if [ -z "$BEAD_ID" ]; then
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║              Project Dependency Overview                     ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""

  # Show active epics with their child tasks
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎯 Active Epics"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  OPEN_EPICS=$(bd list --type=epic --status=open 2>/dev/null | grep "^[a-z]" || echo "")

  if [ -n "$OPEN_EPICS" ]; then
    # Show each epic with its dependency tree
    echo "$OPEN_EPICS" | while IFS= read -r epic_line; do
      # Extract epic ID (first field)
      EPIC_ID=$(echo "$epic_line" | grep -o "^[a-z][a-z-]*-[a-z0-9]*")

      if [ -n "$EPIC_ID" ]; then
        echo ""
        # Show the epic and its dependents (children)
        bd dep tree "$EPIC_ID" --direction=up 2>/dev/null || echo "$epic_line"
        echo ""
      fi
    done
  else
    echo "  No active epics"
    echo ""
  fi

  # Show blocked issues summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚫 Blocked Issues"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  BLOCKED=$(bd blocked 2>/dev/null | grep "^[a-z]" || echo "")
  if [ -n "$BLOCKED" ]; then
    # Count blocked issues
    BLOCKED_COUNT=$(echo "$BLOCKED" | wc -l | tr -d ' ')
    echo "  Total blocked: $BLOCKED_COUNT"
    echo ""

    # Show first 5 blocked issues
    echo "$BLOCKED" | head -5

    if [ "$BLOCKED_COUNT" -gt 5 ]; then
      echo ""
      echo "  (and $((BLOCKED_COUNT - 5)) more...)"
    fi
  else
    echo "  No blocked work"
  fi
  echo ""

  # Show ready to work summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Ready to Work (No Blockers)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  READY_WORK=$(bd ready 2>/dev/null | grep "^[a-z]" || echo "")
  if [ -n "$READY_WORK" ]; then
    # Count ready issues
    READY_COUNT=$(echo "$READY_WORK" | wc -l | tr -d ' ')
    echo "  Total ready: $READY_COUNT"
    echo ""

    # Show first 5 ready issues
    echo "$READY_WORK" | head -5

    if [ "$READY_COUNT" -gt 5 ]; then
      echo ""
      echo "  (and $((READY_COUNT - 5)) more...)"
    fi
  else
    echo "  No ready work available"
  fi
  echo ""

  # Show tip
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "💡 Tip"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Use: /dots-swe:deps <bead-id> to see detailed dependency tree"
  echo "  Use: /dots-swe:deps <bead-id> --mermaid for documentation diagrams"
  echo ""

  exit 0
fi

# =============================================================================
# Mode 2: Single Bead Dependency Tree
# =============================================================================

# Validate bead exists
if ! bd show "$BEAD_ID" >/dev/null 2>&1; then
  echo "Error: Bead '$BEAD_ID' not found" >&2
  exit 1
fi

# Handle Mermaid output format
if [ "$OUTPUT_FORMAT" = "mermaid" ]; then
  # Build status filter flag
  STATUS_FLAG=""
  if [ -n "$STATUS_FILTER" ]; then
    STATUS_FLAG="--status=$STATUS_FILTER"
  fi

  bd dep tree "$BEAD_ID" --direction="$DIRECTION" --format=mermaid $STATUS_FLAG 2>/dev/null
  exit 0
fi

# Show dependency tree with enhanced formatting
echo ""

# Build the bd dep tree command
TREE_CMD="bd dep tree \"$BEAD_ID\" --direction=\"$DIRECTION\""
if [ -n "$STATUS_FILTER" ]; then
  TREE_CMD="$TREE_CMD --status=\"$STATUS_FILTER\""
fi

# Execute and enhance the output
eval "$TREE_CMD" 2>/dev/null | while IFS= read -r line; do
  # Add status indicators
  if echo "$line" | grep -q "(open)"; then
    echo "$line ✓"
  elif echo "$line" | grep -q "(blocked)"; then
    echo "$line ⏸"
  elif echo "$line" | grep -q "(in_progress)"; then
    echo "$line ◐"
  elif echo "$line" | grep -q "(closed)"; then
    echo "$line ✅"
  else
    echo "$line"
  fi
done

echo ""

# Show additional context
BEAD_INFO=$(bd show "$BEAD_ID" 2>/dev/null)

# Check if bead has parent (is part of an epic)
PARENT_INFO=$(echo "$BEAD_INFO" | grep "^DEPENDS ON" -A1 | grep "parent-child\|epic" || echo "")

if [ -n "$PARENT_INFO" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 Context"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Part of epic/parent:"
  echo "$PARENT_INFO" | sed 's/^/    /'
  echo ""
fi

# Show helpful tips based on direction
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Tip"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

case "$DIRECTION" in
  down)
    echo "  Showing dependencies (what blocks this bead)"
    echo "  Use --up to see what this bead blocks"
    echo "  Use --mermaid to generate a diagram for documentation"
    ;;
  up)
    echo "  Showing dependents (what this bead blocks)"
    echo "  Use --down to see what blocks this bead"
    echo "  Use --mermaid to generate a diagram for documentation"
    ;;
  both)
    echo "  Showing full dependency context (both directions)"
    echo "  Use --down to see only what blocks this bead"
    echo "  Use --up to see only what this bead blocks"
    echo "  Use --mermaid to generate a diagram for documentation"
    ;;
esac

echo ""
