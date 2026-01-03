---
allowed-tools: Bash(git:*), Bash(jq:*)
description: Clean up stale worktrees and prune registry
---

# Cleanup Stale Worktrees

Removes worktrees that no longer exist from the registry, prunes git worktree metadata, and optionally removes merged branches.

**Usage:** `/dots-dev:worktree-cleanup [--prune-merged]`

## Context

- Existing worktrees: !`git worktree list`
- Registry file: !`cat ~/.claude/worktree-registry.json 2>/dev/null || echo "{}"`

## Your task

Clean up stale worktrees and registry entries.

**Required steps:**

1. **Prune git worktree metadata**: Run `git worktree prune -v` to remove references to deleted worktrees.

2. **Clean registry entries**: Check `~/.claude/worktree-registry.json` for entries pointing to non-existent paths. Remove stale entries using:
   ```bash
   jq --arg path "<stale-path>" 'del(.[$path])' ~/.claude/worktree-registry.json > ~/.claude/worktree-registry.json.tmp && mv ~/.claude/worktree-registry.json.tmp ~/.claude/worktree-registry.json
   ```

3. **If `--prune-merged` flag is provided**: Find worktrees whose branches have been merged to main (`git branch --merged main`) and delete them along with their branches.

4. **Show results**: Display `git worktree list` to show remaining worktrees.
