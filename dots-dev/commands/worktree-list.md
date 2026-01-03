---
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*)
description: List all git worktrees in the current repository
---

# List Git Worktrees

Shows all git worktrees for the current repository with their status.

**Usage:** `/dots-dev:worktree-list`

## Context

- Git worktrees: !`git worktree list`
- Registry: !`cat ~/.claude/worktree-registry.json 2>/dev/null || echo "{}"`

## Your task

Display all worktrees with their information.

1. **Show git worktrees**: Display the output of `git worktree list`.

2. **Show registry info**: If `~/.claude/worktree-registry.json` exists and has entries, display registered worktrees with their branch names, creation timestamps, and tab IDs using:
   ```bash
   jq -r 'to_entries[] | "  \(.value.branch) - created \(.value.created) (tab: \(.value.tab_id))"' ~/.claude/worktree-registry.json
   ```

3. **Show helpful commands**:
   - `/dots-dev:worktree-create <branch>` - Create new worktree
   - `/dots-dev:worktree-delete <name>` - Delete worktree
   - `/dots-dev:worktree-cleanup` - Remove stale worktrees
