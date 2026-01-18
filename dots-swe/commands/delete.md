---
allowed-tools: Bash(bash:*)
description: Delete worktrees and clean up associated resources
execution-mode: atomic-bash
---

# Delete Worktrees

Delete one or more worktrees, including their branches, sessions, and beads.

**Usage:** `/dots-swe:delete <bead-id> [bead-id...]`

**Arguments:**
- `bead-id` - One or more bead IDs to delete

**What this does:**
- Kills the zmx/tmux session
- Removes the git worktree
- Deletes the local branch
- Removes from the global registry
- Optionally updates bead status

**Examples:**
```bash
/dots-swe:delete dots-abc                           # Delete single worktree
/dots-swe:delete dots-abc dots-def dots-ghi        # Delete multiple worktrees
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/delete.sh 2>/dev/null | head -1)" "$@"
