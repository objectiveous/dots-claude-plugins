---
allowed-tools: Bash
description: Start work on a bead - creates workspace and opens Claude session
execution-mode: atomic-bash
---

<claude-instructions>
CRITICAL: This skill spawns a NEW session in a workspace. DO NOT work in the current directory.

**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Report the complete output to the user and STOP

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, report the complete output to the user and STOP
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- Report the complete output without summarizing
- NEVER continue working in the current directory after this skill runs - work happens in the NEW session
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
