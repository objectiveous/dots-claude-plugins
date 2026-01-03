---
allowed-tools: Bash(git:*), Bash(bd:*), Bash(mkdir:*), Bash(jq:*), Bash(osascript:*)
description: Create a worktree from a bead ID with auto-context
---

# Create Worktree from Bead

Creates a worktree named after a bead, claims the bead, and sets up context for the servus agent.

**Usage:** `/dots-dev:worktree-from-bead <bead-id>`

## Context

- Current branch: !`git branch --show-current`
- Repository root: !`git rev-parse --show-toplevel`
- Existing worktrees: !`git worktree list`

## Your task

Create a worktree from the bead ID provided in the user's command arguments.

**If no bead-id provided**, show usage and list available beads with `bd ready`.

**Required steps:**

1. **Verify bead exists**: Run `bd show <bead-id> --json` and check it returns valid data. If not found, show available beads with `bd ready` or `bd list --status=open`.

2. **Check if worktree already exists**: If `.worktrees/<bead-id>` exists, inform the user and offer to just open an iTerm tab for it.

3. **Ensure worktrees directory exists**: Create `.worktrees/` if needed, add to `.gitignore`.

4. **Check if branch exists**: Use `git show-ref --verify refs/heads/<bead-id>` and `refs/remotes/origin/<bead-id>`.

5. **Create the worktree**:
   - If branch exists: `git worktree add .worktrees/<bead-id> <bead-id>`
   - If not: `git worktree add -b <bead-id> .worktrees/<bead-id> <current-branch>`

6. **Store bead context**: Write the bead-id to `.worktrees/<bead-id>/.claude-bead`

7. **Copy .claude directory**: If it exists in repo root, copy to the worktree.

8. **Claim the bead**: Run `bd update <bead-id> --status=in_progress`

9. **Open iTerm tab**: Use AppleScript to open a new iTerm tab with Claude:
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

10. **Show results**: Confirm worktree creation with path and bead info.
