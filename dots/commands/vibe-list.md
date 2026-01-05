---
allowed-tools: mcp__dots_mcp__*
description: List all active Servus vibes
---

# List Vibes

Lists all active Servus workers.

**Usage:** `/dots:vibe-list`

## Your Task

1. Call the `list_servi()` MCP tool
2. Display the results in a formatted table showing:
   - Bead ID
   - Branch
   - Status (pending/working/blocked/done)
   - tmux session name
   - Worktree path

## Example Output

```
| Bead ID    | Branch              | Status  | Session          |
|------------|---------------------|---------|------------------|
| dots-d82.3 | feature/dots-d82.3  | working | servus-dots-d82.3|
| dots-8vw   | feature/dots-8vw    | pending | servus-dots-8vw  |
```

If no vibes are active, inform the user.
