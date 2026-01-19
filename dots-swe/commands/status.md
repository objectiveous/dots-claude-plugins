---
description: "Show comprehensive work status dashboard"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and display it EXACTLY as-is to the user
4. DO NOT summarize or interpret the output - show the complete status report
</claude-instructions>

# SWE Status Dashboard

Displays a comprehensive dashboard of current work status including active epics, in-flight work, available tasks, work ready to merge, and blocked issues.

**Usage:** `/dots-swe:status`

**Shows:**
- **Active Epic** - Current epic(s) in progress
- **Git Worktrees** - All active worktrees with detailed status:
  - Branch name and associated bead
  - Uncommitted changes count
  - Unpushed commits (ahead of origin)
  - Behind origin status
  - Overall sync state
- **In-Flight Work** - Beads currently being worked on (status: in_progress)
- **Ready to Work** - Unblocked tasks available to start
- **Ready to Merge** - Completed work needing to be finished or merged
- **Blocked Work** - Tasks waiting on dependencies
- **Project Statistics** - Overall project health metrics
- **Quick Actions** - Common commands for next steps

**Use when:**
- Starting a work session to see what needs attention
- Checking overall project health
- Finding next task to work on
- Identifying work that needs to be finished or shipped

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/status.sh 2>/dev/null | head -1)"
