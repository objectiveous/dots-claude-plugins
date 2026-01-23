---
description: "Reconnect to stranded worktrees without active sessions"
allowed-tools: ["Bash"]
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

# Reconnect to All Worktrees

Opens terminal tabs for ALL worktrees, creating new sessions for stranded ones.

**Usage:** `/dots-swe:reconnect [options]`

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--tab` - Open in new Ghostty tabs (default)
- `--window` - Open in new Ghostty windows

**What it does:**
1. Scans all git worktrees (excluding main)
2. For worktrees with existing sessions: opens tabs to reconnect
3. For worktrees without sessions: creates new sessions (no auto-start)
4. Opens a terminal tab/window for EACH worktree

**Important:** New sessions (stranded worktrees) start Claude WITHOUT automatic prompts. Claude will wait for human input and won't auto-start working. This requires human intervention to provide direction.

**Use when:**
- You want to open tabs for all your work-in-progress branches
- Terminal sessions were closed and you want to restore them all
- After system restart or terminal crash
- You manually created worktrees and need to connect to them

**Terminal Support:**
- **Ghostty**: Opens zmx sessions in tabs/windows for ALL worktrees
- **iTerm2**: Creates tmux windows, attaches via AppleScript

## Implementation

!bash "$(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)/reconnect.sh" "$@"
