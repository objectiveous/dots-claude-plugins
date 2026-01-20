---
description: "Remove git pre-commit hook that enforces code-complete workflow"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

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

# Uninstall Quality Hook

Removes the git pre-commit hook that enforces the code-complete workflow.

**Usage:** `/dots-swe:uninstall-quality-hook`

## Implementation

!REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

!if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not in a git repository"
  exit 1
fi

!HOOK_PATH="$REPO_ROOT/.git/hooks/pre-commit"

!if [ ! -f "$HOOK_PATH" ]; then
  echo "ℹ️  No pre-commit hook found"
  echo ""
  echo "Nothing to uninstall."
  exit 0
fi

# Check if it's our hook by looking for the quality gates pattern
!if ! grep -q "Quality Gates Check" "$HOOK_PATH" 2>/dev/null; then
  echo "⚠️  Found a pre-commit hook, but it doesn't appear to be the"
  echo "   quality gates hook installed by this plugin."
  echo ""
  echo "Hook location: $HOOK_PATH"
  echo ""
  read -p "Delete anyway? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Uninstall cancelled"
    exit 1
  fi
  echo ""
fi

!rm "$HOOK_PATH"

!echo "✅ Quality hook removed successfully!"
!echo ""
!echo "Commits will no longer check for the swe:code-complete label."
!echo ""
!echo "To reinstall, run: /dots-swe:install-quality-hook"
