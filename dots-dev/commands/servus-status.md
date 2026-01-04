---
allowed-tools: Bash(cat:*), Bash(date:*)
description: Update your status as a Servus worker
---

# Update Servus Status

Updates your `.servus-status.json` so Dominus can see your current state.

**Usage:** `/dots-dev:servus-status <status> [message]`

**Statuses:**
- `working` - Actively working on the task
- `blocked` - Stuck, need help or waiting on dependency
- `waiting_input` - Need human input/clarification
- `done` - Task complete

**Examples:**
- `/dots-dev:servus-status working Implementing SessionRegistry`
- `/dots-dev:servus-status blocked Cannot find notify crate docs`
- `/dots-dev:servus-status done PR ready for review`

## Arguments

- STATUS: !`echo "$1"`
- MESSAGE: !`shift; echo "$*"`

## Your task

Write the status update to `.servus-status.json`.

**Steps:**

1. Validate status is one of: working, blocked, waiting_input, done
2. Get current branch and bead info
3. Write `.servus-status.json`:
   ```json
   {
     "status": "<status>",
     "updated": "<ISO timestamp>",
     "message": "<message>",
     "branch": "<current branch>",
     "bead": "<bead id if found>"
   }
   ```
4. Confirm: "Status updated: [status] - [message]"

If no status provided, show current status from file if it exists.
