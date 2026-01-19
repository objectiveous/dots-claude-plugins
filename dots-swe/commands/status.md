---
description: "Show comprehensive work status dashboard"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
After calling the Skill tool:
1. Check the tool result immediately - it may contain execution output or status information
2. If the bash script executed, display the complete output EXACTLY as-is to the user
3. If you see a task_id or background process reference, use TaskOutput to check its status
4. DO NOT wait passively - actively check results and report to the user
5. DO NOT manually run individual bash commands from this skill definition
6. DO NOT summarize or interpret the output - show the complete status report
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
