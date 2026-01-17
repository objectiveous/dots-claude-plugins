---
allowed-tools: Bash(bash:*), Bash(zmx:*), Bash(tmux:*), AskUserQuestion
description: Continue work on an existing bead - reattach to session
---

<claude-instructions>
When the user runs this command:

**If a bead ID is provided** (e.g., `/dots-swe:continue dots-abc`):
1. Run the continue script with the provided bead ID
2. Report the result to the user

**If NO bead ID is provided** (e.g., `/dots-swe:continue`):
1. Run the continue script with `--format=json` to get available sessions
2. Parse the JSON output to get session information
3. Use AskUserQuestion to present the sessions as options with their bead titles
4. Run the continue script with the selected session
5. Report the result to the user

The script path is: `$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/continue.sh 2>/dev/null | head -1)`
</claude-instructions>

# Continue Work

Reattach to an existing work session.

**Usage:** `/dots-swe:continue [bead-id]`

**Examples:**
```bash
/dots-swe:continue              # Select from available sessions interactively
/dots-swe:continue dots-abc     # Continue work on dots-abc
```
