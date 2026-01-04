---
allowed-tools: Bash(cat:*), Bash(ls:*), Bash(jq:*), Bash(git:*)
description: Check status of all active Servi workers
---

# Servus Status Check

Polls all worktrees for `.servus-status.json` to show Servus worker states.

**Usage:** `/dots-dev:servus-check`

## Context

- Repository root: !`git rev-parse --show-toplevel`
- Worktrees: !`git worktree list`

## Your task

Check the status of all Servi by reading `.servus-status.json` from each worktree.

**Steps:**

1. Get list of worktrees from `git worktree list`

2. For each worktree (excluding main repo):
   - Check if `.servus-status.json` exists
   - If yes, read and parse it
   - Display: branch, status, message, last updated

3. Format output as a status dashboard:
   ```
   === SERVUS STATUS ===
   
   ✓ task/dots-d82.2.2 [working] - Implementing SessionRegistry (2 min ago)
   ⏳ task/dots-d82.2.3 [started] - Received mission briefing (5 min ago)
   ⚠️ feature/xyz [waiting_input] - Need clarification on API design (10 min ago)
   
   Total: 3 active Servi
   ```

4. Status icons:
   - `✓` = working
   - `⏳` = started (not yet working)
   - `⚠️` = waiting_input or blocked
   - `✅` = done
   - `❓` = no status file (unknown)

5. Show time since last update in human-readable format (X min ago, X hours ago)

If no worktrees have status files, show "No active Servi found."
