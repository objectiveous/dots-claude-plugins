---
allowed-tools: mcp__tmux__*, Bash(tmux:*)
description: List active Servus tmux sessions with their status
---

# List Servus Sessions

Lists all active Servus tmux sessions, showing their status and associated worktrees.

**Usage:** `/dots-dev:servus-list`

## Your task

List all active tmux sessions that are Servus workers (sessions with names starting with `servus-`).

**Steps:**

1. **Use tmux MCP to list sessions:**
   - Call `mcp__tmux__list-sessions` to get all active tmux sessions

2. **Filter for Servus sessions:**
   - Only show sessions whose names start with `servus-`
   - Extract the branch name from the session name (remove `servus-` prefix, replace `-` back to `/` where appropriate)

3. **For each Servus session, show:**
   - Session name
   - Derived branch/worktree name
   - Whether the session is attached or detached
   - Optionally capture the last few lines of output using `mcp__tmux__capture-pane` to show activity status

4. **Display in a table format:**
   ```
   | Session | Branch | Status | Last Activity |
   |---------|--------|--------|---------------|
   | servus-task-dots-dfi | task/dots-dfi | detached | Working on... |
   | servus-feature-auth | feature/auth | attached | Idle |
   ```

5. **Show helpful commands:**
   - How to attach: `tmux attach -t <session-name>` or `/dots-dev:servus-attach <session-name>`
   - How to view pane: `mcp__tmux__capture-pane`
   - How to kill: `mcp__tmux__kill-session`

If no Servus sessions are found, inform the user that no workers are currently running.

## Notes

- Session names follow the pattern: `servus-<sanitized-branch-name>`
- The session list only shows tmux sessions - iTerm spawned workers won't appear here
- Use `/dots-dev:worktree-status` for a more comprehensive view including non-tmux worktrees
