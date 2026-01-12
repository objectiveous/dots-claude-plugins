---
allowed-tools: Bash(bash:*)
description: Start work from a bead - creates worktree and claims the task
execution-mode: atomic-bash
---

<claude-instructions>
CRITICAL: This skill spawns a NEW session in a worktree. DO NOT work in the current directory.

1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output
4. Report the result to the user and STOP - work happens in the NEW session
5. NEVER continue working in the current directory after this skill runs

The `/dots-swe:work` command ALWAYS creates/opens a worktree, regardless of bead status.
</claude-instructions>

# Start Work from Bead

Creates a worktree from a bead ID, claims the bead, and sets up context for the task.

**Usage:** `/dots-swe:work <bead-id>`

**Example:**
```bash
/dots-swe:work dots-abc
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/work.sh 2>/dev/null | head -1)" "$@"
