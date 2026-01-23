#!/bin/bash
# Display dots-swe plugin version and environment information

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/swe-lib.sh"

echo "dots-swe Plugin Version"
echo ""

# Find plugin installation path
PLUGIN_ROOT=$(dirname "$SCRIPT_DIR")
PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"

# Extract version from plugin.json
if [ -f "$PLUGIN_JSON" ]; then
  VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_JSON" | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
  PLUGIN_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_JSON" | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
  DESCRIPTION=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_JSON" | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
else
  VERSION="unknown"
  PLUGIN_NAME="dots-swe"
  DESCRIPTION="unknown"
fi

echo "Plugin Information"
echo ""
echo "Name:        $PLUGIN_NAME"
echo "Version:     $VERSION"
echo "Description: $DESCRIPTION"
echo "Path:        $PLUGIN_ROOT"
echo ""

# Last updated timestamp
if [ -f "$PLUGIN_JSON" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    LAST_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$PLUGIN_JSON")
  else
    LAST_MODIFIED=$(stat -c "%y" "$PLUGIN_JSON" | cut -d'.' -f1)
  fi
  echo "Last updated: $LAST_MODIFIED"
else
  echo "Last updated: unknown"
fi
echo ""

# Git information (if in a git repository)
if [ -d "$PLUGIN_ROOT/.git" ]; then
  cd "$PLUGIN_ROOT" || exit 1
  GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null)
  GIT_BRANCH=$(git branch --show-current 2>/dev/null)
  GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null)

  if [ -n "$GIT_COMMIT" ]; then
    echo "Git commit:  $GIT_COMMIT"
  fi
  if [ -n "$GIT_BRANCH" ]; then
    echo "Git branch:  $GIT_BRANCH"
  fi
  if [ -n "$GIT_REMOTE" ]; then
    echo "Git remote:  $GIT_REMOTE"
  fi
  echo ""
fi

# Dependencies and requirements
echo "Dependencies & Requirements"
echo ""

check_dependency() {
  local cmd=$1
  local name=$2
  local version_flag=${3:---version}

  if command -v "$cmd" &>/dev/null; then
    local version_output
    version_output=$($cmd $version_flag 2>&1 | head -1)
    echo "✅ $name: $version_output"
    return 0
  else
    echo "❌ $name: not found"
    return 1
  fi
}

# Check required dependencies
check_dependency "git" "git"
check_dependency "bd" "beads" "--version"
check_dependency "gh" "GitHub CLI"

echo ""

# Check optional dependencies
echo "Optional tools:"
check_dependency "zmx" "zmx (session manager)" "--version" || true
check_dependency "tmux" "tmux (session manager)" "-V" || true

echo ""

# Development Mode Status
echo "Development Mode"
echo ""

if [ -n "${DOTS_SWE_DEV:-}" ]; then
  echo "✅ Enabled (DOTS_SWE_DEV is set)"
  echo "   Path: $DOTS_SWE_DEV"

  # Verify the path is valid
  if [ -d "$DOTS_SWE_DEV/scripts" ]; then
    echo "   Status: ✅ Valid development directory"

    # Show which scripts directory is being used
    RESOLVED_SCRIPTS=$(ls -td "${DOTS_SWE_DEV:-/nonexistent}/scripts" "$HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/"*/scripts 2>/dev/null | head -1)
    if [ "$RESOLVED_SCRIPTS" = "$DOTS_SWE_DEV/scripts" ]; then
      echo "   Active: ✅ Using development scripts"
    else
      echo "   Active: ⚠️  Using cache (dev path not prioritized)"
    fi
  else
    echo "   Status: ❌ Invalid (scripts directory not found)"
  fi

  echo ""
  echo "To disable: unset DOTS_SWE_DEV"
  echo "For details: cat $DOTS_SWE_DEV/DEV.md"
else
  echo "❌ Disabled (DOTS_SWE_DEV not set)"
  echo ""
  echo "To enable plugin development mode:"
  echo "  export DOTS_SWE_DEV=/path/to/dots-swe"
  echo ""
  echo "Or add to ~/.zshrc or ~/.bashrc for persistence"
  echo ""
  echo "For details: cat $(dirname "$PLUGIN_ROOT")/dots-swe/DEV.md"
fi

echo ""
echo ""
echo "For help, run: /dots-swe:help"
echo ""
