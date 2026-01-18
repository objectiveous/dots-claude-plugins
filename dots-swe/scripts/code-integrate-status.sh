#!/bin/bash
# Show code integration status for swe:code-complete labeled beads

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:code-integrate-status"
  echo ""
  echo "Show all swe:code-complete labeled beads and their integration readiness."
  echo ""
  echo "For each bead, shows:"
  echo "  • Merge status (MERGED/OPEN PR/NO PR)"
  echo "  • Resources ready for integration (worktree, session, branches)"
  echo ""
  echo "Examples:"
  echo "  /dots-swe:code-integrate-status     # Show integration status"
  echo ""
  echo "See also:"
  echo "  /dots-swe:code-integrate            # Integrate all merged work"
  echo "  /dots-swe:code-integrate <bead-id>  # Integrate specific bead"
  exit 0
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Code Integration Status                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Get all beads with swe:code-complete label
BEADS=$(bd list --label swe:code-complete --json 2>/dev/null)

if [ -z "$BEADS" ] || [ "$BEADS" = "[]" ]; then
  echo "ℹ️  No beads with swe:code-complete label found."
  echo ""
  echo "Run /dots-swe:code-complete to mark work as complete."
  exit 0
fi

# Parse beads and check status
MERGED_COUNT=0
WAITING_COUNT=0
NO_PR_COUNT=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 Work Completed (swe:code-complete)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Parse JSON and process each bead
echo "$BEADS" | jq -c '.[]' | while IFS= read -r bead_json; do
  BEAD_ID=$(echo "$bead_json" | jq -r '.id')
  TITLE=$(echo "$bead_json" | jq -r '.title')

  # Check merge status
  MERGE_STATUS=$(is_branch_merged "$BEAD_ID")

  # Get resources
  RESOURCES=$(get_cleanup_resources "$BEAD_ID")

  # Check for PR info
  PR_INFO=""
  if [ "$MERGE_STATUS" != "local" ]; then
    PR_NUMBER=$(gh pr list --head "$BEAD_ID" --state all --json number --jq '.[0].number' 2>/dev/null)
    if [ -n "$PR_NUMBER" ]; then
      PR_STATE=$(gh pr list --head "$BEAD_ID" --state all --json state --jq '.[0].state' 2>/dev/null)
      PR_INFO=" (#$PR_NUMBER, $PR_STATE)"
    fi
  fi

  # Display based on merge status
  case "$MERGE_STATUS" in
    local|pr)
      echo "  ✅ $BEAD_ID [MERGED]"
      MERGED_COUNT=$((MERGED_COUNT + 1))
      ;;
    no)
      if [ -n "$PR_INFO" ]; then
        echo "  ⏳ $BEAD_ID [OPEN PR$PR_INFO]"
        WAITING_COUNT=$((WAITING_COUNT + 1))
      else
        echo "  ⚠️  $BEAD_ID [NO PR]"
        NO_PR_COUNT=$((NO_PR_COUNT + 1))
      fi
      ;;
  esac

  echo "     $TITLE"
  if [ -n "$RESOURCES" ]; then
    echo "     Resources: $RESOURCES"
  fi
  echo ""
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count totals (re-parse since subshell)
TOTAL=$(echo "$BEADS" | jq '. | length')
MERGED_FINAL=0
WAITING_FINAL=0
NO_PR_FINAL=0

echo "$BEADS" | jq -r '.[].id' | while read -r bid; do
  ms=$(is_branch_merged "$bid")
  case "$ms" in
    local|pr) MERGED_FINAL=$((MERGED_FINAL + 1)) ;;
    no)
      PR=$(gh pr list --head "$bid" --state all --json number --jq '.[0].number' 2>/dev/null)
      if [ -n "$PR" ]; then
        WAITING_FINAL=$((WAITING_FINAL + 1))
      else
        NO_PR_FINAL=$((NO_PR_FINAL + 1))
      fi
      ;;
  esac
done

echo "$BEADS" | jq -r '.[].id' | {
  MERGED=0
  WAITING=0
  NO_PR=0
  while read -r bid; do
    ms=$(is_branch_merged "$bid")
    case "$ms" in
      local|pr) MERGED=$((MERGED + 1)) ;;
      no)
        PR=$(gh pr list --head "$bid" --state all --json number --jq '.[0].number' 2>/dev/null)
        if [ -n "$PR" ]; then
          WAITING=$((WAITING + 1))
        else
          NO_PR=$((NO_PR + 1))
        fi
        ;;
    esac
  done

  echo "  Ready for integration: $MERGED"
  echo "  Waiting for merge: $WAITING"
  if [ $NO_PR -gt 0 ]; then
    echo "  Needs PR: $NO_PR"
  fi
  echo ""

  if [ $MERGED -gt 0 ]; then
    echo "  Run: /dots-swe:code-integrate           # Integrate all merged work"
    echo "  Run: /dots-swe:code-integrate <bead>    # Integrate specific bead"
  fi
}
