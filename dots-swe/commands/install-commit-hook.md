---
description: "Install git commit-msg hook for Conventional Commits validation"
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

# Install Commit Hook

Installs a git commit-msg hook that validates commit messages follow Conventional Commits format.

**Usage:** `/dots-swe:install-commit-hook`

The hook will validate that commits follow the pattern:
- `type(scope): description`
- Valid types: feat, fix, docs, chore, refactor, test
- Description must be lowercase and not end with a period

## Implementation

!REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

!if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not in a git repository"
  exit 1
fi

!HOOK_DIR="$REPO_ROOT/.git/hooks"
!HOOK_PATH="$HOOK_DIR/commit-msg"

# Find the hook script in the plugin cache
!HOOK_SCRIPT=$(ls -t $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/commit-msg-hook.sh 2>/dev/null | head -1)

!if [ -z "$HOOK_SCRIPT" ] || [ ! -f "$HOOK_SCRIPT" ]; then
  echo "❌ Could not find commit-msg-hook.sh in plugin cache"
  exit 1
fi

# Check if hook already exists
!if [ -f "$HOOK_PATH" ]; then
  echo "⚠️  A commit-msg hook already exists at:"
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

!echo "✅ Commit hook installed successfully!"
!echo ""
!echo "Location: $HOOK_PATH"
!echo ""
!echo "The hook will now validate all commit messages to ensure they follow"
!echo "Conventional Commits format. Examples:"
!echo ""
!echo "  ✅ feat(api): add user authentication"
!echo "  ✅ fix: resolve null pointer in parser"
!echo "  ✅ chore: bump version to 1.2.0"
!echo ""
!echo "To uninstall, run: /dots-swe:uninstall-commit-hook"
