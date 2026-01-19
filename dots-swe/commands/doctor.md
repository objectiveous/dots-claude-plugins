---
description: "Health check for repository and worktrees"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
After calling the Skill tool:
1. Check the tool result immediately - it may contain execution output or status information
2. If the bash script executed, report the complete output to the user
3. If you see a task_id or background process reference, use TaskOutput to check its status
4. DO NOT wait passively - actively check results and report to the user
5. DO NOT manually run individual bash commands from this skill definition
</claude-instructions>

# Doctor - Health Check

Checks repository health: stale worktrees, uncommitted changes, unpushed commits, and beads sync status.

**Usage:** `/dots-swe:doctor`

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/doctor.sh 2>/dev/null | head -1)"
