---
allowed-tools: Bash, AskUserQuestion
description: Continue work on an existing bead - reattach to session
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the behavior described below directly

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result and follow the behavior described below

**Behavior when executing this command:**

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
