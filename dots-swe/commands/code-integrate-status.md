---
allowed-tools: Bash(bash:*)
description: Show work ready for integration after merge
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

# Code Integration Status

Shows all `swe:code-complete` labeled beads and their integration readiness.

**Usage:** `/dots-swe:code-integrate-status`

**Shows:**
- Beads with `swe:code-complete` label
- Merge status for each (MERGED/OPEN PR/NO PR)
- Resources ready for integration (worktree, session, branches)
- Summary with suggested next actions

**Example:**
```bash
/dots-swe:code-integrate-status   # Show all integration-ready work
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/code-integrate-status.sh 2>/dev/null | head -1)"
