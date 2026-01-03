---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(osascript:*)
description: Merge a completed worktree branch back to main
---

# Merge Worktree to Main

Merges a completed worktree's branch back to main, then optionally cleans up the worktree.

**Usage:** `/dots-dev:worktree-merge <worktree-name> [--cleanup]`

## Context

- Repository root: !`git rev-parse --show-toplevel`
- Existing worktrees: !`git worktree list`

## Your task

Merge the specified worktree's branch back to main.

**If no worktree name provided**, show available worktrees and usage info.

**Required steps:**

1. **Find the worktree**: Look for `<repo-root>/.worktrees/<worktree-name>` or search in `git worktree list`.

2. **Get the branch name**: Use `git -C <worktree-path> branch --show-current`.

3. **Check for uncommitted changes**: Run `git -C <worktree-path> status --porcelain`. If changes exist, inform user to commit or stash first and exit.

4. **Check for unpushed commits**: Run `git -C <worktree-path> log @{u}..HEAD --oneline 2>/dev/null` and warn if any exist.

5. **Update main branch**: From repo root, run:
   ```bash
   git checkout main
   git pull origin main
   ```

6. **Merge the branch**: Run `git merge <branch-name> --no-ff -m "Merge branch '<branch-name>'"`. If conflicts occur, inform user how to resolve.

7. **Push main**: Run `git push origin main`.

8. **If `--cleanup` flag provided**:
   - Get tab_id from registry and close iTerm tab
   - Remove worktree: `git worktree remove <path> --force`
   - Delete branch: `git branch -d <branch-name>`
   - Remove from registry

9. **Show success message** with merge confirmation.
