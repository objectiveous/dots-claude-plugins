# Skill Tool Usage Pattern

## Evolution of the Pattern

This document tracks the evolution of claude-instructions for skill files to address two key issues.

### Issue 1: Passive Waiting (Fixed 2026-01-18)

**Problem:** Skill command files told Claude to wait passively for "AUTOMATIC" execution output.

**Root Cause:** Instructions told Claude to "wait" for output when Claude actually needs to actively check the tool result.

**Solution:** Changed from passive "wait for" language to active "check the tool result immediately" instructions.

### Issue 2: Calling Skill Tool When Already Loaded (Fixed 2026-01-18)

**Problem:** When a user types `/dots-swe:status`, the system injects the skill content with `<command-name>` tags, but Claude was still calling the Skill tool instead of executing the bash script directly.

**Root Cause:** The claude-instructions only addressed what to do "After calling the Skill tool" but didn't tell Claude WHEN to call the tool vs when the skill is already loaded.

**Impact:**
- Extra round trip (wasted context/time)
- No output shown until user interrupts
- Confusing UX

**Solution:** Updated instructions to check for `<command-name>` tag first and handle both scenarios.

## Current Best Practice Pattern

The recommended `<claude-instructions>` block now handles both scenarios:

```markdown
<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Report the complete output to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, report the complete output to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- Report the complete output without summarizing
</claude-instructions>
```

## Key Improvements

1. **Skill Load Detection**: Checks for `<command-name>` tag to determine if skill is already loaded
2. **Two-Path Logic**: Explicit instructions for both "already loaded" and "needs loading" scenarios
3. **Active vs Passive**: Changed from "Wait for..." to "Check the tool result immediately"
4. **Actionable Steps**: Tells Claude exactly what to do in each scenario
5. **Fallback Logic**: Provides guidance for checking background tasks if needed
6. **Clarity**: Removes misleading language about "AUTOMATIC" execution
7. **Preserves Intent**: Still prevents manual execution of individual commands from the skill definition

## Files Updated

All 16 dots-swe command files were updated with the new pattern (2026-01-18):

1. `beads.md`
2. `code-complete.md`
3. `code-integrate.md`
4. `code-integrate-status.md`
5. `continue.md` (custom variant)
6. `delete.md`
7. `dispatch.md`
8. `doctor.md`
9. `install-commit-hook.md`
10. `prime.md` (custom variant)
11. `process-check.md`
12. `reconnect.md`
13. `squash.md`
14. `status.md`
15. `uninstall-commit-hook.md`

Note: `continue.md` and `prime.md` have custom variants of the pattern to accommodate their specific behaviors.

## Testing

To verify the fix for Issue 1 (passive waiting):
1. Call a skill command like `/dots-swe:code-integrate --local <bead-id>`
2. Observe that Claude immediately checks the tool result and reports output
3. Confirm Claude does not hang waiting for output
4. Verify that if a background task is spawned, Claude uses TaskOutput to check status

To verify the fix for Issue 2 (calling Skill tool when already loaded):
1. Call a skill command like `/dots-swe:status`
2. Observe that Claude immediately executes the bash script (no extra Skill tool call)
3. Confirm output is shown immediately
4. Verify no wasted round trip or waiting behavior

## Best Practices for Skill Authors

When writing `<claude-instructions>` blocks for skills:

- **Do**: Check for `<command-name>` tag first to determine if skill is already loaded
- **Do**: Provide explicit instructions for both scenarios (loaded vs needs loading)
- **Do**: Tell Claude to actively check tool results (not passively wait)
- **Do**: Provide clear fallback logic for edge cases
- **Do**: Be specific about what to report to the user
- **Don't**: Use passive language like "wait for" or "will happen automatically"
- **Don't**: Create expectations that don't match how the framework actually works
- **Don't**: Leave Claude without clear next steps after a tool call
- **Don't**: Assume the Skill tool always needs to be called - check if skill is already loaded first

## Related Issues

- **Issue 1**: dots-claude-plugins-ztt - "Claude waiting indefinitely after Skill tool calls"
  - Fixed: 2026-01-18
  - Solution: Active checking vs passive waiting

- **Issue 2**: dots-claude-plugins-3e5 - "Claude calls Skill tool when command already loaded"
  - Fixed: 2026-01-18
  - Solution: Check for `<command-name>` tag before calling Skill tool
