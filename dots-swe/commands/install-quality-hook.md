---
description: "Install git pre-commit hook to enforce code-complete workflow"
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

# Install Quality Hook

Installs a git pre-commit hook that enforces the code-complete workflow for SWE beads.

**Usage:** `/dots-swe:install-quality-hook`

The hook will check if a bead has the `swe:code-complete` label before allowing commits.
If the label is missing, it prompts the user to run `/dots-swe:code-complete` first.

This ensures quality gates (tests, lint, build) are executed before committing completed work.

## Implementation

!REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

!if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not in a git repository"
  exit 1
fi

!HOOK_DIR="$REPO_ROOT/.git/hooks"
!HOOK_PATH="$HOOK_DIR/pre-commit"

# Find the hook script in the plugin cache
!HOOK_SCRIPT=$(ls -t $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/pre-commit-quality-hook.sh 2>/dev/null | head -1)

!if [ -z "$HOOK_SCRIPT" ] || [ ! -f "$HOOK_SCRIPT" ]; then
  echo "❌ Could not find pre-commit-quality-hook.sh in plugin cache"
  exit 1
fi

# Check if hook already exists
!if [ -f "$HOOK_PATH" ]; then
  echo "⚠️  A pre-commit hook already exists at:"
  echo "   $HOOK_PATH"
  echo ""
  read -p "Overwrite? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Installation cancelled"
    exit 1
  fi
  echo ""
fi

# Copy hook and make executable
!cp "$HOOK_SCRIPT" "$HOOK_PATH"
!chmod +x "$HOOK_PATH"

!echo "✅ Quality hook installed successfully!"
!echo ""
!echo "Location: $HOOK_PATH"
!echo ""
!echo "The hook will now check for the swe:code-complete label before allowing"
!echo "commits. If the label is missing, you'll be prompted to run:"
!echo "  /dots-swe:code-complete"
!echo ""
!echo "Benefits:"
!echo "  • Ensures quality gates (test/lint/build) run before commits"
!echo "  • Prevents skipping the code-complete workflow"
!echo "  • Allows WIP commits when needed"
!echo ""
!echo "To bypass the hook temporarily, use: git commit --no-verify"
!echo "To uninstall, run: /dots-swe:uninstall-quality-hook"
