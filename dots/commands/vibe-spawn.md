---
allowed-tools: mcp__dots_mcp__*, Bash(bd:*)
description: Spawn a new Servus vibe for a bead
---

# Spawn Vibe

Spawns a new Servus worker for the specified bead.

**Usage:** `/dots:vibe-spawn <bead-id> [context]`

## Context

- Current branch: !`git branch --show-current`
- Repository root: !`git rev-parse --show-toplevel`

## Your Task

1. Parse the bead ID from the user's command arguments
2. Optionally get bead context by running: `bd show <bead-id>`
3. Call the `spawn_servus(bead_id, context)` MCP tool with:
   - `bead_id`: The bead ID from the command
   - `context`: Optional context from bd show or user-provided context
4. Report the result to the user

## What spawn_servus Does

The MCP tool will:
- Create a git worktree in `.worktrees/feature/<bead-id>/`
- Write `.servus-dispatch.md` with mission briefing
- Register session in `~/.dots/sessions.json` (triggers UI update)
- Create tmux session `servus-<bead-id>` running Claude

## Example

```
/dots:vibe-spawn dots-d82.3
```

This will spawn a new Servus worker for bead `dots-d82.3`.

If no bead ID is provided, show usage information.
