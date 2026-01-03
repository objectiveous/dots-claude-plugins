#!/bin/bash
# Shared worktree management functions for dots-dev plugin

# Get the git repository root
get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

# Get the worktrees directory path
get_worktrees_dir() {
  local repo_root
  repo_root=$(get_repo_root)
  echo "$repo_root/.worktrees"
}

# Get the global registry file path
get_registry_file() {
  echo "$HOME/.claude/worktree-registry.json"
}

# Ensure worktrees directory exists and is in .gitignore
ensure_worktrees_dir() {
  local repo_root worktrees_dir
  repo_root=$(get_repo_root)
  worktrees_dir=$(get_worktrees_dir)

  mkdir -p "$worktrees_dir"

  if ! grep -q "^\.worktrees/$" "$repo_root/.gitignore" 2>/dev/null; then
    echo ".worktrees/" >> "$repo_root/.gitignore"
    echo "Added .worktrees/ to .gitignore"
  fi
}

# Ensure registry file exists
ensure_registry() {
  local registry_file
  registry_file=$(get_registry_file)
  mkdir -p "$(dirname "$registry_file")"
  [ ! -f "$registry_file" ] && echo "{}" > "$registry_file"
}

# Register a worktree in the global registry
register_worktree() {
  local path="$1"
  local branch="$2"
  local tab_id="$3"
  local registry_file

  registry_file=$(get_registry_file)
  ensure_registry

  jq --arg path "$path" \
     --arg branch "$branch" \
     --arg tab_id "$tab_id" \
     --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.[$path] = {branch: $branch, tab_id: $tab_id, created: $created}' \
    "$registry_file" > "$registry_file.tmp" && mv "$registry_file.tmp" "$registry_file"
}

# Unregister a worktree from the global registry
unregister_worktree() {
  local path="$1"
  local registry_file

  registry_file=$(get_registry_file)

  if [ -f "$registry_file" ]; then
    jq --arg path "$path" 'del(.[$path])' "$registry_file" > "$registry_file.tmp" \
      && mv "$registry_file.tmp" "$registry_file"
  fi
}

# Get worktree info from registry
get_worktree_info() {
  local path="$1"
  local field="$2"
  local registry_file

  registry_file=$(get_registry_file)

  if [ -f "$registry_file" ]; then
    jq -r --arg path "$path" --arg field "$field" '.[$path][$field] // ""' "$registry_file" 2>/dev/null
  fi
}

# Open iTerm tab with Claude session
open_iterm_claude_session() {
  local worktree_path="$1"
  local abs_path

  abs_path="$(cd "$worktree_path" && pwd)"

  osascript -e "tell application \"iTerm\"
    activate
    tell current window
      create tab with default profile
      tell current session
        write text \"cd '$abs_path' && claude\"
      end tell
    end tell
    return id of current window
  end tell"
}

# Close iTerm tab by ID
close_iterm_tab() {
  local tab_id="$1"

  if [ -n "$tab_id" ]; then
    osascript -e "tell application \"Terminal\"
      close (first tab of first window whose id is $tab_id)
    end tell" 2>/dev/null || echo "Warning: Could not close tab $tab_id (may already be closed)"
  fi
}

# Check if a branch exists (local or remote)
branch_exists() {
  local branch="$1"

  # Check local
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "local"
    return 0
  fi

  # Check remote
  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    echo "remote"
    return 0
  fi

  echo "none"
  return 1
}

# Find worktree path by name
find_worktree_path() {
  local name="$1"
  git worktree list | grep "/$name " | awk '{print $1}' | head -1
}

# Get branch name from worktree path
get_worktree_branch() {
  local path="$1"
  git worktree list | grep "$path" | awk '{print $3}' | tr -d '[]'
}

# =============================================================================
# Argument parsing helpers (for skill commands that can't use inline loops)
# =============================================================================

# Check if a flag is present in arguments
# Usage: has_flag "--cleanup" "$@" && echo "has it"
has_flag() {
  local flag="$1"
  shift
  local arg
  for arg in "$@"; do
    if [ "$arg" = "$flag" ]; then
      return 0
    fi
  done
  return 1
}

# Extract non-flag arguments (arguments not starting with --)
# Usage: NAME=$(get_positional_arg "$@")
get_positional_arg() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --*) continue ;;
      *) echo "$arg"; return ;;
    esac
  done
}

# =============================================================================
# Batch operations (for skill commands that can't use inline loops)
# =============================================================================

# Validate that no worktree directories already exist
# Usage: validate_no_existing_worktrees "$WORKTREES_DIR" branch1 branch2 ...
validate_no_existing_worktrees() {
  local worktrees_dir="$1"
  shift
  local branch worktree_dir

  for branch in "$@"; do
    worktree_dir="$worktrees_dir/$branch"
    if [ -d "$worktree_dir" ]; then
      echo "ERROR: Worktree directory already exists: $worktree_dir"
      echo "Use /dots-dev:worktree-delete $branch to remove it first."
      return 1
    fi
  done
  return 0
}

# Create multiple worktrees
# Usage: create_worktrees "$CURRENT_BRANCH" "$WORKTREES_DIR" branch1 branch2 ...
create_worktrees() {
  local current_branch="$1"
  local worktrees_dir="$2"
  shift 2
  local branch worktree_dir branch_status

  for branch in "$@"; do
    worktree_dir="$worktrees_dir/$branch"

    echo ""
    echo "Creating worktree: $worktree_dir"

    branch_status=$(branch_exists "$branch")

    case "$branch_status" in
      "local")
        echo "Using existing local branch: $branch"
        git worktree add "$worktree_dir" "$branch"
        ;;
      "remote")
        echo "Using existing remote branch: origin/$branch"
        git worktree add "$worktree_dir" "$branch"
        ;;
      *)
        echo "Creating new branch: $branch (from $current_branch)"
        git worktree add -b "$branch" "$worktree_dir" "$current_branch"
        ;;
    esac

    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to create worktree for: $branch"
      return 1
    fi
  done
  return 0
}

# Open iTerm tabs and register worktrees
# Usage: open_and_register_worktrees "$WORKTREES_DIR" branch1 branch2 ...
open_and_register_worktrees() {
  local worktrees_dir="$1"
  shift
  local branch worktree_dir abs_path tab_id

  ensure_registry

  for branch in "$@"; do
    worktree_dir="$worktrees_dir/$branch"
    abs_path="$(cd "$worktree_dir" && pwd)"

    echo "Opening iTerm tab for: $branch"
    tab_id=$(open_iterm_claude_session "$worktree_dir")

    # Store tab ID locally
    echo "$tab_id" > "$worktree_dir/.claude-tab-id"

    # Register globally
    register_worktree "$abs_path" "$branch" "$tab_id"
    echo "Registered worktree: $branch (tab ID: $tab_id)"
  done
}

# Delete multiple worktrees
# Usage: delete_worktrees worktree1 worktree2 ...
delete_worktrees() {
  local worktree_name worktree_path branch_name tab_id

  for worktree_name in "$@"; do
    echo "Processing worktree: $worktree_name"

    # Find worktree path
    worktree_path=$(find_worktree_path "$worktree_name")

    if [ -z "$worktree_path" ]; then
      echo "ERROR: Worktree '$worktree_name' not found"
      git worktree list
      continue
    fi

    # Get branch name
    branch_name=$(get_worktree_branch "$worktree_path")

    # Get tab ID from registry
    tab_id=$(get_worktree_info "$worktree_path" "tab_id")

    echo "  Branch: $branch_name"
    echo "  Path: $worktree_path"
    echo "  Tab ID: ${tab_id:-none}"

    # Close terminal tab if we have a tab ID
    if [ -n "$tab_id" ]; then
      echo "  Closing terminal tab..."
      close_iterm_tab "$tab_id"
    fi

    # Remove git worktree
    echo "  Removing git worktree..."
    git worktree remove "$worktree_path" --force

    # Delete branch
    echo "  Deleting branch: $branch_name"
    git branch -D "$branch_name" 2>/dev/null || echo "  Warning: Branch $branch_name not found"

    # Remove from registry
    unregister_worktree "$worktree_path"
    echo "  Removed from registry"

    echo ""
    echo "Worktree '$worktree_name' deleted."
    echo ""
  done
}
