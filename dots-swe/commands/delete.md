---
allowed-tools: Bash(bash:*)
description: Delete worktrees and clean up associated resources
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Report the complete output to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, report the complete output to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- Report the complete output without summarizing
</claude-instructions>

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
