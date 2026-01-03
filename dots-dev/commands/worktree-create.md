---
allowed-tools: Bash(git:*), Bash(mkdir:*), Bash(source:*), Bash(osascript:*)
description: Create git worktrees with parallel Claude sessions in iTerm
---

# Create Git Worktrees

Creates one or more git worktrees in `.worktrees/` directory and opens Claude sessions in iTerm tabs.

**Usage:** `/dots-dev:worktree-create <branch1> [branch2] [...]`

## Context

- Current branch: !`git branch --show-current`
- Repository root: !`git rev-parse --show-toplevel`
- Existing worktrees: !`git worktree list`

## Your task

Create worktrees for the branch name(s) provided in the user's command arguments.

**Required steps:**

1. **Ensure worktrees directory exists**: Create `.worktrees/` in the repo root if it doesn't exist. Add `.worktrees/` to `.gitignore` if not already present.

2. **For each branch name provided**:
   - Check if the worktree directory already exists at `<repo-root>/.worktrees/<branch-name>`. If it does, inform the user and skip.
   - Check if the branch exists locally (`git show-ref --verify refs/heads/<branch>`) or on remote (`git show-ref --verify refs/remotes/origin/<branch>`).
   - If branch exists: `git worktree add .worktrees/<branch-name> <branch-name>`
   - If branch doesn't exist: `git worktree add -b <branch-name> .worktrees/<branch-name> <current-branch>`
   - Copy the `.claude/` directory to the new worktree if it exists in the repo root.

3. **Open iTerm tabs**: For each created worktree, run this AppleScript to open a new iTerm tab with Claude:
   ```bash
   osascript -e 'tell application "iTerm"
     activate
     tell current window
       create tab with default profile
       tell current session
         write text "cd '"'"'<absolute-worktree-path>'"'"' && claude"
       end tell
     end tell
   end tell'
   ```

4. **Show results**: Display `git worktree list` to confirm the worktrees were created.

If no branch names are provided, show usage information instead.
