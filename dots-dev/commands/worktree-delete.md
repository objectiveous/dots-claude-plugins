---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(osascript:*)
description: Delete git worktrees by name
---

# Delete Git Worktrees

Deletes specified worktrees, closes associated iTerm tabs, and cleans up branches.

**Usage:** `/dots-dev:worktree-delete <name1> [name2] [...]`

## Context

- Existing worktrees: !`git worktree list`
- Registry: !`cat ~/.claude/worktree-registry.json 2>/dev/null || echo "{}"`

## Your task

Delete the worktree(s) specified in the user's command arguments.

**If no names provided**, show available worktrees and usage info instead.

**For each worktree name provided:**

1. **Find the worktree path**: Look for it in `git worktree list` output.

2. **Get the branch name**: Extract from the worktree list or use `git -C <path> branch --show-current`.

3. **Close iTerm tab if registered**: Check registry for a `tab_id`, then close it (may fail if already closed):
   ```bash
   osascript -e 'tell application "Terminal" to close (first tab of first window whose id is <tab_id>)' 2>/dev/null
   ```

4. **Remove the git worktree**: `git worktree remove <path> --force`

5. **Delete the branch**: `git branch -D <branch-name>`

6. **Remove from registry**:
   ```bash
   jq --arg path "<worktree-path>" 'del(.[$path])' ~/.claude/worktree-registry.json > ~/.claude/worktree-registry.json.tmp && mv ~/.claude/worktree-registry.json.tmp ~/.claude/worktree-registry.json
   ```

7. **Show remaining worktrees**: Display `git worktree list`.
