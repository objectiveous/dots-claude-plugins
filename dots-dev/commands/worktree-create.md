---
allowed-tools: Bash(git:*), Bash(mkdir:*), Bash(source:*), Bash(osascript:*), Bash(bd:*), Bash(cat:*), Bash(tmux:*), mcp__tmux__*
description: Create git worktrees with parallel Claude sessions in iTerm
---

# Create Git Worktrees

Creates one or more git worktrees in `.worktrees/` directory and spawns Claude sessions via tmux (preferred) or iTerm tabs (fallback).

**Usage:** `/dots-dev:worktree-create <branch1> [branch2] [...]`

## Context

- Current branch: !`git branch --show-current`
- Repository root: !`git rev-parse --show-toplevel`
- Existing worktrees: !`git worktree list`
- tmux available: !`command -v tmux >/dev/null && echo "yes" || echo "no"`

## Your task

Create worktrees for the branch name(s) provided in the user's command arguments.

**Required steps:**

1. **Ensure worktrees directory exists**: Create `.worktrees/` in the repo root if it doesn't exist. Add `.worktrees/` to `.gitignore` if not already present.

2. **For each branch name provided**:
   - Check if the worktree directory already exists at `<repo-root>/.worktrees/<branch-name>`. If it does, inform the user and skip creation but still spawn Claude session.
   - Check if the branch exists locally (`git show-ref --verify refs/heads/<branch>`) or on remote (`git show-ref --verify refs/remotes/origin/<branch>`).
   - If branch exists: `git worktree add .worktrees/<branch-name> <branch-name>`
   - If branch doesn't exist: `git worktree add -b <branch-name> .worktrees/<branch-name> <current-branch>`
   - Copy the `.claude/` directory to the new worktree if it exists in the repo root.

3. **Check if branch name is a bead ID**: Run `bd show <branch-name> 2>/dev/null`. If it returns valid bead info:
   - Write `.worktrees/<branch-name>/.servus-dispatch.md` with the mission briefing:
     ```bash
     BEAD_INFO=$(bd show <branch-name>)
     cat > .worktrees/<branch-name>/.servus-dispatch.md << DISPATCH
     # Mission: <branch-name>

     $BEAD_INFO

     ## Instructions

     1. Complete this task according to the description above
     2. Make atomic commits as you progress
     3. When finished, run: /dots-dev:worktree-handoff
     4. The Dominus will review and merge your work

     Strength and honor, Servus. Execute with precision.
     DISPATCH
     ```
   - Run `bd update <branch-name> --status=in_progress` to claim the bead

4. **Spawn Claude session (tmux preferred, iTerm fallback)**:

   First, check if tmux MCP tools are available by attempting to use `mcp__tmux__list-sessions`.

   **If tmux is available (mcp__tmux__* tools work):**

   For each worktree, use tmux to create a headless session:

   a. Create session with a descriptive name (use branch name, sanitized for tmux):
      - Session name: `servus-<sanitized-branch-name>` (replace `/` with `-`, limit to 50 chars)
      - Use `mcp__tmux__create-session` with the worktree path as working directory

   b. Execute the claude command in the session:
      - Use `mcp__tmux__execute-command` to run `claude` in the new session

   c. Report the session name to the user so they can attach if needed:
      - `tmux attach -t <session-name>` or use `/dots-dev:servus-attach`

   **If tmux is NOT available (fallback to iTerm):**

   For each created worktree, run this AppleScript to open a new iTerm tab with Claude:
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

5. **Show results**: Display `git worktree list` to confirm the worktrees were created. Also show which spawning method was used (tmux or iTerm) and how to attach to sessions.

If no branch names are provided, show usage information instead.

## tmux Session Naming Convention

Session names follow the pattern: `servus-<branch-name>`

Examples:
- Branch `task/dots-dfi` → Session `servus-task-dots-dfi`
- Branch `feature/auth` → Session `servus-feature-auth`
- Branch `dots-abc` → Session `servus-dots-abc`

This allows easy identification and attachment via `/dots-dev:servus-list` and `/dots-dev:servus-attach`.
