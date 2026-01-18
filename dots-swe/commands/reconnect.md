---
description: "Reconnect to stranded worktrees without active sessions"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Reconnect to Stranded Worktrees

Opens new terminal sessions for worktrees that don't have active sessions.

**Usage:** `/dots-swe:reconnect [options]`

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--tab` - Open in new Ghostty tabs (default)
- `--window` - Open in new Ghostty windows

**What it does:**
1. Scans all git worktrees (excluding main)
2. Identifies worktrees without active sessions (stranded)
3. Opens new terminal sessions for each stranded worktree
4. Attaches to the first session

**Use when:**
- Terminal sessions were closed or lost
- Worktrees were created manually without sessions
- After system restart or terminal crash
- You didn't use the proper workflow and have orphaned worktrees

**Terminal Support:**
- **Ghostty**: Creates zmx sessions, opens first as tab/window
- **iTerm2**: Creates tmux windows, attaches via AppleScript

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/reconnect.sh 2>/dev/null | head -1)" "$@"
