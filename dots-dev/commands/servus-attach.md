---
allowed-tools: Bash(osascript:*), Bash(tmux:*), mcp__tmux__*
description: Attach to a Servus tmux session via iTerm
---

# Attach to Servus Session

Opens an iTerm window/tab attached to a Servus tmux session, allowing the user to interact with the Claude worker.

**Usage:** `/dots-dev:servus-attach [session-name]`

## Context

- Available sessions: !`tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^servus-" || echo "No servus sessions found"`

## Your task

Attach to a Servus tmux session in a new iTerm tab so the user can interact with it.

**Steps:**

1. **Determine target session:**
   - If a session name is provided, use it directly
   - If no session name provided:
     - List available Servus sessions (names starting with `servus-`)
     - If only one session exists, use it
     - If multiple sessions exist, ask the user which one to attach to
     - If no sessions exist, inform the user and exit

2. **Verify session exists:**
   - Use `mcp__tmux__find-session` or `tmux has-session -t <name>` to verify
   - If not found, show error with list of available sessions

3. **Open iTerm attached to the session:**
   ```bash
   osascript -e 'tell application "iTerm"
     activate
     tell current window
       create tab with default profile
       tell current session
         write text "tmux attach -t '"'"'<session-name>'"'"'"
       end tell
     end tell
   end tell'
   ```

4. **Confirm to user:**
   - Report that iTerm tab was opened attached to the session
   - Remind them to use `Ctrl+B D` to detach (or their tmux prefix key)

## Notes

- This command opens a new iTerm tab for human interaction
- The Claude agent continues running in the tmux session
- Detaching (Ctrl+B D) leaves the session running in background
- Killing the tab (Ctrl+D or exit) will terminate the tmux session

## Session Naming Convention

Sessions follow the pattern: `servus-<branch-name>`

To attach to branch `task/dots-dfi`, use:
```
/dots-dev:servus-attach servus-task-dots-dfi
```
