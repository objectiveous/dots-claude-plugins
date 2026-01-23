#!/bin/bash
# Delete worktrees and clean up associated resources

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

# Check for arguments
if [ $# -eq 0 ]; then
  echo "ERROR: No bead IDs provided"
  echo ""
  echo "Usage: /dots-swe:delete <bead-id> [bead-id...]"
  echo ""
  echo "Examples:"
  echo "  /dots-swe:delete dots-abc"
  echo "  /dots-swe:delete dots-abc dots-def dots-ghi"
  exit 1
fi

echo "Deleting Worktrees"
echo ""

# Use the delete_worktrees function from swe-lib.sh
delete_worktrees "$@"

echo "✅ Deletion complete!"
echo ""
echo "To reopen beads, use: /dots-swe:dispatch <bead-id>"
