---
allowed-tools: Bash(git:*)
description: Pull latest changes from main into a worktree
---

# Sync Worktree with Main

Pulls latest changes from main branch into the current or specified worktree.

**Usage:** `/dots-dev:worktree-sync [worktree-name]`

If no worktree name provided, syncs the current worktree.

## Context

- Current directory: !`pwd`
- Repository root: !`git rev-parse --show-toplevel`
- Current branch: !`git branch --show-current`
- Existing worktrees: !`git worktree list`

## Your task

Sync a worktree with the latest changes from main.

**Determine the target worktree:**
- If a worktree name is provided, find its path in `.worktrees/<name>` or `git worktree list`
- If no name provided, use the current directory (but verify it's not the main repo root)

**Required steps:**

1. **Get the branch name**: `git -C <worktree-path> branch --show-current`

2. **Fetch latest from origin**: `git -C <worktree-path> fetch origin main`

3. **Check for uncommitted changes**: Run `git -C <worktree-path> status --porcelain`
   - If changes exist, show them and stash: `git -C <worktree-path> stash push -m "Auto-stash before sync"`
   - Remember to restore the stash later

4. **Rebase onto main**: `git -C <worktree-path> rebase origin/main`
   - If conflicts occur, inform user how to resolve with `git rebase --continue` or `git rebase --abort`

5. **Restore stashed changes** (if any): `git -C <worktree-path> stash pop`
   - Warn if conflicts occur applying stash

6. **Show success message** with branch name.
