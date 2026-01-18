---
description: "Remove git commit-msg hook for Conventional Commits validation"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Uninstall Commit Hook

Removes the git commit-msg hook that validates Conventional Commits format.

**Usage:** `/dots-swe:uninstall-commit-hook`

## Implementation

!REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

!if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not in a git repository"
  exit 1
fi

!HOOK_PATH="$REPO_ROOT/.git/hooks/commit-msg"

!if [ ! -f "$HOOK_PATH" ]; then
  echo "ℹ️  No commit-msg hook found"
  echo ""
  echo "Nothing to uninstall."
  exit 0
fi

# Check if it's our hook by looking for the Conventional Commits pattern
!if ! grep -q "Conventional Commits" "$HOOK_PATH" 2>/dev/null; then
  echo "⚠️  Found a commit-msg hook, but it doesn't appear to be the"
  echo "   Conventional Commits validator installed by this plugin."
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

!echo "✅ Commit hook removed successfully!"
!echo ""
!echo "Commit messages will no longer be validated for Conventional Commits format."
!echo ""
!echo "To reinstall, run: /dots-swe:install-commit-hook"
