---
allowed-tools: Bash(bash:*)
description: Start work on a bead - creates workspace and opens Claude session
execution-mode: atomic-bash
---

<claude-instructions>
CRITICAL: This skill spawns a NEW session in a workspace. DO NOT work in the current directory.

After calling the Skill tool:
1. Check the tool result immediately - it may contain execution output or status information
2. If the bash script executed, report the complete output to the user and STOP
3. If you see a task_id or background process reference, use TaskOutput to check its status
4. DO NOT wait passively - actively check results and report to the user
5. DO NOT manually run individual bash commands from this skill definition
6. NEVER continue working in the current directory after this skill runs - work happens in the NEW session
</claude-instructions>

# Dispatch Work

Start work on one or more beads by creating worktrees and opening Claude sessions.

**Usage:** `/dots-swe:dispatch [options] [bead-id...]`

**Arguments:**
- `bead-id...` - One or more beads to work on (optional if already in a worktree)

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--tab` - Open in a new Ghostty tab (default)
- `--window` - Open in a new Ghostty window
- `--model <name>` - Claude model to use (opus, sonnet, haiku; default: opus)

**Examples:**
```bash
/dots-swe:dispatch dots-abc                           # Open tab for specific bead
/dots-swe:dispatch dots-abc dots-def dots-xyz         # Dispatch multiple beads
/dots-swe:dispatch --window dots-abc                  # Open window instead
/dots-swe:dispatch --model sonnet dots-abc            # Use sonnet model
/dots-swe:dispatch                                    # Open tab for current worktree
/dots-swe:dispatch --dry-run dots-abc                 # Preview what would happen
```

**macOS Permissions:**
This command uses AppleScript to control terminals. If it fails to open tabs/windows, grant Automation permissions in System Settings → Privacy & Security → Automation. See `/dots-swe:help` for details.

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/dispatch.sh 2>/dev/null | head -1)" "$@"
