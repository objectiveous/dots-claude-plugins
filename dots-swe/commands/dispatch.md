---
allowed-tools: Bash(bash:*)
description: Start work on a bead - creates workspace and opens Claude session
execution-mode: atomic-bash
---

<claude-instructions>
CRITICAL: This skill spawns a NEW session in a workspace. DO NOT work in the current directory.

1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output
4. Report the result to the user and STOP - work happens in the NEW session
5. NEVER continue working in the current directory after this skill runs
</claude-instructions>

# Dispatch Work

Start work on a bead by creating a workspace and opening a Claude session.

**Usage:** `/dots-swe:dispatch [options] [bead-id]`

**Arguments:**
- `bead-id` - Bead to work on (optional if already in a worktree)

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--tab` - Open in a new Ghostty tab (default)
- `--window` - Open in a new Ghostty window
- `--model <name>` - Claude model to use (opus, sonnet, haiku; default: opus)

**Examples:**
```bash
/dots-swe:dispatch dots-abc                    # Open tab for specific bead
/dots-swe:dispatch --window dots-abc           # Open window instead
/dots-swe:dispatch --model sonnet dots-abc     # Use sonnet model
/dots-swe:dispatch                             # Open tab for current worktree
/dots-swe:dispatch --dry-run dots-abc          # Preview what would happen
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/dispatch.sh 2>/dev/null | head -1)" "$@"
