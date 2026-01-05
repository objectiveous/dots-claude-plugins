---
allowed-tools: mcp__dots_mcp__*
description: Report Servus status to the UI
---

# Report Vibe Status

Reports a Servus worker's status to the Dots UI.

**Usage:** `/dots:vibe-status <bead-id> <status> [reason]`

## Status Values

| Status | Description | UI Category |
|--------|-------------|-------------|
| `pending` | Servus created but not yet working | Beads |
| `working` | Actively working on the bead | Vibing |
| `blocked` | Blocked and needs help | Escalation |
| `done` | Completed the work | (hidden) |

## Your Task

1. Parse bead ID and status from the user's command arguments
2. Call the `report_status(bead_id, status, reason)` MCP tool with:
   - `bead_id`: The bead ID
   - `status`: One of `pending`, `working`, `blocked`, `done`
   - `reason`: Optional reason (required for `blocked` status)
3. Confirm the status was updated

## Examples

```
# Mark a vibe as working
/dots:vibe-status dots-d82.3 working

# Mark a vibe as blocked with a reason
/dots:vibe-status dots-d82.3 blocked "Need API credentials"

# Mark a vibe as done
/dots:vibe-status dots-d82.3 done
```

## Note

This command is primarily used by Servi to report their status back to the Dominus. The Dots UI will automatically update to reflect the new status:

- **Vibing** section shows `working` vibes
- **Escalation** section shows `blocked` vibes
- **Beads** section shows all vibes except `done`
