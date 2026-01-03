---
allowed-tools: Bash(git:*), Bash(cat:*), Bash(date:*), Bash(pwd:*)
description: Capture session context before closing a worktree
---

# Worktree Handoff

Captures the current session context for handoff to the next session. Records what was done, what's left, and any blockers.

**Usage:** `/dots-dev:worktree-handoff`

Run this before closing a worktree session to preserve context.

## Context

- Current directory: !`pwd`
- Repository root: !`git rev-parse --show-toplevel`
- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Unpushed commits: !`git log @{u}..HEAD --oneline 2>/dev/null || echo "none (or no upstream)"`
- Last commit: !`git log -1 --format="%h %s" 2>/dev/null || echo "none"`
- Associated bead: !`cat .claude-bead 2>/dev/null || echo "none"`

## Your task

Create a handoff file for the next session.

**First, verify we're in a worktree** (not the main repo). If current directory equals repo root, inform user and exit.

**Create `.claude-handoff` file** in the current directory with this template:

```markdown
# Session Handoff: <branch-name>
Generated: <UTC timestamp>

## Bead
<bead-id or "No bead associated">

## Last Commit
<commit hash and message>

## Uncommitted Changes
```
<git status --short output or "None">
```

## Unpushed Commits
```
<git log output or "None">
```

## Session Summary
<!-- FILL IN: What was accomplished this session -->


## Remaining Work
<!-- FILL IN: What still needs to be done -->


## Blockers
<!-- FILL IN: Any blockers for the next session -->


## Notes for Next Session
<!-- FILL IN: Context, gotchas, or tips -->

```

**After creating the file**, display its contents and instruct the user to fill in the sections marked with `<!-- FILL IN -->`.
