---
description: "Send a message to all active worktree sessions"
allowed-tools: ["Bash"]
---

# Broadcast to Worktrees

Sends a message to all active worktree Claude sessions. Useful for coordination like "stopping for lunch", "main updated - please sync", etc.

**Usage:** `/dots-dev:broadcast <message>`

## Implementation

!source "*/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:broadcast <message>"
  echo ""
  echo "Send a message to all active worktree Claude sessions."
  echo ""
  echo "Arguments:"
  echo "  <message>    The message to broadcast"
  echo ""
  echo "How it works:"
  echo "  - Writes message to .claude-broadcast in each worktree"
  echo "  - Servus agents check for broadcasts on startup"
  echo "  - Message is displayed and file is removed after reading"
  echo ""
  echo "Examples:"
  echo "  /dots-dev:broadcast Stopping for lunch - save your work"
  echo "  /dots-dev:broadcast Main updated - run /dots-dev:worktree-sync"
  echo "  /dots-dev:broadcast Standup in 5 minutes"
  exit 0
fi

!MESSAGE="$*"

!if [ -z "$MESSAGE" ]; then
  echo "Usage: /dots-dev:broadcast <message>"
  echo "Use --help for more information."
  exit 1
fi

!REGISTRY_FILE=$(get_registry_file)
!REPO_ROOT=$(get_repo_root)
!WORKTREES_DIR=$(get_worktrees_dir)

!if [ ! -f "$REGISTRY_FILE" ]; then
  echo "No worktrees registered."
  exit 0
fi

!WORKTREE_COUNT=$(jq 'length' "$REGISTRY_FILE" 2>/dev/null || echo "0")

!if [ "$WORKTREE_COUNT" -eq 0 ]; then
  echo "No worktrees registered."
  exit 0
fi

!TIMESTAMP=$(date +"%H:%M:%S")
!BROADCAST_FILE="$WORKTREES_DIR/.broadcast"

# Write broadcast message to shared file
!cat > "$BROADCAST_FILE" << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📢 BROADCAST [$TIMESTAMP]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$MESSAGE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

!echo "📢 Broadcasting to $WORKTREE_COUNT worktree(s):"
!echo ""
!echo "   $MESSAGE"
!echo ""

# For each registered worktree, create a notification file
!jq -r 'keys[]' "$REGISTRY_FILE" 2>/dev/null | while read path; do
  if [ -d "$path" ]; then
    BRANCH=$(jq -r --arg path "$path" '.[$path].branch // "unknown"' "$REGISTRY_FILE")

    # Write notification to worktree
    NOTIFY_FILE="$path/.claude-broadcast"
    cp "$BROADCAST_FILE" "$NOTIFY_FILE"

    echo "   ✓ $BRANCH"
  fi
done

!echo ""
!echo "Broadcast sent. Sessions will see the message on next interaction."
!echo ""
!echo "Note: Claude sessions check for broadcasts in .claude-broadcast file."
!echo "The servus agent is configured to check this on startup."
