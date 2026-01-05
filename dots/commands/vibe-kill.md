---
allowed-tools: mcp__dots_mcp__*
description: Kill a Servus vibe
---

# Kill Vibe

Terminates a Servus worker and cleans up its worktree.

**Usage:** `/dots:vibe-kill <bead-id>`

## Your Task

1. Parse the bead ID from the user's command arguments
2. Call the `kill_servus(bead_id)` MCP tool
3. Report the result to the user

## What kill_servus Does

The MCP tool will:
- Kill the tmux session `servus-<bead-id>`
- Unregister from `~/.dots/sessions.json` (triggers UI update)
- Remove the git worktree at `.worktrees/feature/<bead-id>/`

## Example

```
/dots:vibe-kill dots-d82.3
```

This will terminate the Servus worker for bead `dots-d82.3` and clean up its resources.

If no bead ID is provided, show usage information.

## Warning

This will forcibly terminate the Servus session. Any uncommitted work will be lost. Make sure the Servus has completed its work or use `/dots:vibe-status` to check its status first.
