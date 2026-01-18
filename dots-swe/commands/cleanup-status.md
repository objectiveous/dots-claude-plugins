---
allowed-tools: Bash(bash:*)
description: Show work ready for cleanup after merge
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Cleanup Status

Shows all `swe:done` labeled beads and their cleanup readiness.

**Usage:** `/dots-swe:cleanup-status`

**Shows:**
- Beads with `swe:done` label
- Merge status for each (MERGED/OPEN PR/NO PR)
- Resources ready for cleanup (worktree, session, branches)
- Summary with suggested next actions

**Example:**
```bash
/dots-swe:cleanup-status   # Show all cleanup-ready work
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/cleanup-status.sh 2>/dev/null | head -1)"
