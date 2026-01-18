---
allowed-tools: Bash(bash:*)
description: Show work ready for integration after merge
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Code Integration Status

Shows all `swe:done` labeled beads and their integration readiness.

**Usage:** `/dots-swe:code-integrate-status`

**Shows:**
- Beads with `swe:done` label
- Merge status for each (MERGED/OPEN PR/NO PR)
- Resources ready for integration (worktree, session, branches)
- Summary with suggested next actions

**Example:**
```bash
/dots-swe:code-integrate-status   # Show all integration-ready work
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/code-integrate-status.sh 2>/dev/null | head -1)"
