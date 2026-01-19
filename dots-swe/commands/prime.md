---
description: "Enhanced context loader with quality gates enforcement"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- The output will be automatically injected as system context

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately

**About this command:**

This command loads enhanced session context including quality gates in the SESSION CLOSE PROTOCOL.
It replaces/enhances bd prime output to ensure agents run tests/lint/build before committing.

The output includes:
- Bead context from .swe-bead and .swe-context files
- Git status and recent commits
- Enhanced SESSION CLOSE PROTOCOL with quality gates as Step 0
- Project conventions from CLAUDE.md

This command is automatically called on SessionStart by the dots-swe hook.
You can also call it manually via /dots-swe:prime to refresh context.
</claude-instructions>

# Enhanced Context Loader

Loads session context with enhanced SESSION CLOSE PROTOCOL that includes quality gates.

**Usage:** `/dots-swe:prime`

This command enhances `bd prime` output by:
- Adding quality gates (test/lint/build) as Step 0 in SESSION CLOSE PROTOCOL
- Detecting project type and adapting recommendations
- Providing prominent enforcement checklist

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/prime.sh 2>/dev/null | head -1)"
