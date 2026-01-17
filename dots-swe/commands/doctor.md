---
description: "Health check for repository and worktrees"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Doctor - Health Check

Checks repository health: stale worktrees, uncommitted changes, unpushed commits, and beads sync status.

**Usage:** `/dots-swe:doctor`

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/doctor.sh 2>/dev/null | head -1)"
