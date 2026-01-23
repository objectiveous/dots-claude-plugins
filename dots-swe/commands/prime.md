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

This command loads enhanced session context with a SESSION CLOSE PROTOCOL that mandates /dots-swe:code-complete.

The output includes:
- Bead context from .swe-bead and .swe-context files
- Git status and recent commits
- Enhanced SESSION CLOSE PROTOCOL with /dots-swe:code-complete as Step 0
- Workflow mode detection (GitHub PR vs local/ephemeral)
- Quality gates detection and display (test/lint/build)
- Failure handling guidance
- Project conventions from CLAUDE.md

This command is automatically called on SessionStart by the dots-swe hook.
You can also call it manually via /dots-swe:prime to refresh context.
</claude-instructions>

# Enhanced Context Loader

Loads session context with enhanced SESSION CLOSE PROTOCOL that mandates code-complete.

**Usage:** `/dots-swe:prime`

This command enhances `bd prime` output by:
- Making /dots-swe:code-complete Step 0 in SESSION CLOSE PROTOCOL (REQUIRED)
- Detecting workflow mode (GitHub PR vs local/ephemeral)
- Adapting protocol based on workflow mode
- Detecting quality gates (test/lint/build) and showing what will run
- Providing visual hierarchy with arrows (↓) showing flow
- Including failure handling guidance
- Emphasizing DO NOT proceed if code-complete fails

## Implementation

!source "$(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)/prime.sh"
