---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*)
description: Dashboard showing all worktrees with git status and bead info
---

# Worktree Status Dashboard

Shows all git worktrees with their current state: git status, active bead, uncommitted changes.

**Usage:** `/dots-dev:worktree-status`

## Context

- Repository root: !`git rev-parse --show-toplevel`
- Worktrees (porcelain): !`git worktree list --porcelain`
- Registry: !`cat ~/.claude/worktree-registry.json 2>/dev/null || echo "{}"`

## Your task

Display a dashboard showing all worktrees with their status.

**For each worktree** (excluding the main repo root):

1. **Get basic info**:
   - Path from `git worktree list`
   - Branch: `git -C <path> branch --show-current`

2. **Get git status**:
   - Uncommitted changes count: `git -C <path> status --porcelain | wc -l`
   - Staged changes count: `git -C <path> diff --cached --numstat | wc -l`
   - Unpushed commits: `git -C <path> log @{u}..HEAD --oneline 2>/dev/null | wc -l`

3. **Check for bead association**:
   - Look for `.claude-bead` file in worktree
   - Or extract bead ID from branch name if it matches `dots-*` pattern

4. **Get registry info**: Creation timestamp and tab ID from `~/.claude/worktree-registry.json`

**Format the output** as a dashboard with:
- Branch name as header
- Path
- Clean/dirty status with change counts
- Unpushed commits indicator
- Bead association if any
- Creation timestamp

**End with a summary**: Total worktree count and helpful command references.
