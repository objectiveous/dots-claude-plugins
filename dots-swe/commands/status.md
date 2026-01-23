---
description: "Show comprehensive work status dashboard"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Display the complete output EXACTLY as-is to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, display the complete output EXACTLY as-is to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- DO NOT summarize or interpret the output - show the complete report as-is
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

!bash "$(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)/status.sh"
