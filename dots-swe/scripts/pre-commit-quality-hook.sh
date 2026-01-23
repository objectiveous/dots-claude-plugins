#!/bin/bash
# Pre-commit hook: Enforce code-complete workflow for SWE beads
#
# This hook checks if a bead has the swe:code-complete label before allowing commits.
# It ensures quality gates (test/lint/build) are run before committing completed work.

# Check if we're in a worktree with a bead
BEAD_ID=$(cat .swe-bead 2>/dev/null)

if [ -z "$BEAD_ID" ]; then
  # Not a bead worktree, allow commit
  exit 0
fi

# Check if bead has swe:code-complete label
if bd label list "$BEAD_ID" 2>/dev/null | grep -q "swe:code-complete"; then
  # Has label, all good
  exit 0
fi

# Missing swe:code-complete label - prompt user
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  Quality Gates Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Bead: $BEAD_ID"
echo "Status: Missing swe:code-complete label"
echo ""
echo "Before committing completed work, you should run:"
echo "  /dots-swe:code-complete"
echo ""
echo "This will:"
echo "  • Run quality gates (test/lint/build)"
echo "  • Push to remote"
echo "  • Add swe:code-complete label"
echo "  • Verify work is ready for integration"
echo ""
echo "Options:"
echo "  [y] Yes, I ran code-complete (proceed with commit)"
echo "  [n] No, let me run it now (abort commit)"
echo "  [w] This is WIP, skip for now (proceed with commit)"
echo ""
read -p "Continue with commit? [y/n/w]: " -n 1 -r
echo ""

case "$REPLY" in
  y|Y)
    echo "✓ Proceeding with commit"
    exit 0
    ;;
  w|W)
    echo "⚠️  Proceeding with WIP commit (code-complete skipped)"
    exit 0
    ;;
  *)
    echo "❌ Commit aborted"
    echo ""
    echo "Next steps:"
    echo "  1. Run: /dots-swe:code-complete"
    echo "  2. If quality gates pass, commit again"
    echo ""
    exit 1
    ;;
esac
