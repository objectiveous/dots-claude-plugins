# Skill Tool Usage Pattern

## Problem

Previously, skill command files contained instructions that told Claude to wait passively for "AUTOMATIC" execution output:

```markdown
<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>
```

**Issue:** This caused Claude to wait indefinitely for output that never arrived in the expected format, leading to hung sessions requiring user intervention.

## Root Cause

The Skill tool framework:
1. Loads skill content and injects it into the conversation
2. May execute bash commands (with `execution-mode: atomic-bash`)
3. Returns a tool result, but Claude must actively check and report it

The problematic instructions told Claude to be completely passive and "wait" for output, when Claude actually needs to actively check the tool result and report what happened.

## Solution

Updated `<claude-instructions>` blocks to be actionable and clear about expected behavior:

```markdown
<claude-instructions>
After calling the Skill tool:
1. Check the tool result immediately - it may contain execution output or status information
2. If the bash script executed, report the complete output to the user
3. If you see a task_id or background process reference, use TaskOutput to check its status
4. DO NOT wait passively - actively check results and report to the user
5. DO NOT manually run individual bash commands from this skill definition
</claude-instructions>
```

## Key Improvements

1. **Active vs Passive**: Changed from "Wait for..." to "Check the tool result immediately"
2. **Actionable Steps**: Tells Claude exactly what to do after the Skill tool call
3. **Fallback Logic**: Provides guidance for checking background tasks if needed
4. **Clarity**: Removes misleading language about "AUTOMATIC" execution
5. **Preserves Intent**: Still prevents manual execution of individual commands from the skill definition

## Files Updated

All 11 dots-swe command files with this pattern were updated:

1. `code-complete.md`
2. `code-integrate.md`
3. `code-integrate-status.md`
4. `dispatch.md`
5. `status.md`
6. `process-check.md`
7. `doctor.md`
8. `beads.md`
9. `reconnect.md`
10. `install-commit-hook.md`
11. `uninstall-commit-hook.md`

## Testing

To verify the fix:
1. Call a skill command like `/dots-swe:code-integrate --local <bead-id>`
2. Observe that Claude immediately checks the tool result and reports output
3. Confirm Claude does not hang waiting for output
4. Verify that if a background task is spawned, Claude uses TaskOutput to check status

## Best Practices for Skill Authors

When writing `<claude-instructions>` blocks for skills:

- **Do**: Tell Claude to actively check tool results
- **Do**: Provide clear fallback logic for edge cases
- **Do**: Be specific about what to report to the user
- **Don't**: Use passive language like "wait for" or "will happen automatically"
- **Don't**: Create expectations that don't match how the framework actually works
- **Don't**: Leave Claude without clear next steps after a tool call

## Related

- Issue: dots-claude-plugins-ztt
- Bug: "Claude waiting indefinitely after Skill tool calls"
- Fix Date: 2026-01-18
