---
allowed-tools: Bash
description: Show work ready for integration after merge
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Report the complete output to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, report the complete output to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- Report the complete output without summarizing
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
