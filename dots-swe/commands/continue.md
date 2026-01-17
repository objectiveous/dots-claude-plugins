---
allowed-tools: Bash(bash:*), Bash(zmx:*), Bash(tmux:*)
description: Continue work on an existing bead - reattach to session
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Continue Work

Reattach to an existing work session.

**Usage:** `/dots-swe:continue [bead-id]`

**Examples:**
```bash
/dots-swe:continue              # List available sessions
/dots-swe:continue dots-abc     # Continue work on dots-abc
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/continue.sh 2>/dev/null | head -1)" "$@"
