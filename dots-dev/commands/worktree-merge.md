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

6. **Show commits to be merged**: Display the commits that will be merged:
   ```bash
   git log main..<branch-name> --oneline
   ```

7. **Prompt for Conventional Commit message**: Ask the user for:
   - **Type**: feat, fix, chore, refactor, docs, test, perf, ci, build, or revert
   - **Scope** (optional): e.g., auth, api, ui
   - **Description**: Brief summary of what's being merged

   Format the subject line as: `type(scope): description` or `type: description` if no scope.

8. **Generate merge commit message**: Create a properly formatted commit message with:
   - **Subject**: The conventional commit format from step 7
   - **Body**: Summary of commits being merged (extracted from git log output)
   - **Footer**: `Merged branch: <branch-name>`

   Example format:
   ```
   feat(auth): add OAuth integration

   - Add OAuth 2.0 provider configuration
   - Implement token refresh logic
   - Add session management

   Merged branch: feature/oauth
   ```

9. **Merge the branch**: Run the merge with the generated message:
   ```bash
   git merge <branch-name> --no-ff -m "<full-commit-message>"
   ```
   If conflicts occur, inform user how to resolve.

10. **Push main**: Run `git push origin main`.

11. **If `--cleanup` flag provided**:
   - Get tab_id from registry and close iTerm tab
   - Remove worktree: `git worktree remove <path> --force`
   - Delete branch: `git branch -d <branch-name>`
   - Remove from registry

12. **Show success message** with merge confirmation.
