---
description: "Check plugin version and dependencies"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Version - Plugin Information

Displays dots-swe plugin version, installation path, last updated timestamp, and dependencies status.

**Usage:** `/dots-swe:version`

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/version.sh 2>/dev/null | head -1)"
