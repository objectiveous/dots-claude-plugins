---
description: "Reconnect to stranded worktrees without active sessions"
allowed-tools: ["Bash"]
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

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/reconnect.sh 2>/dev/null | head -1)" "$@"
