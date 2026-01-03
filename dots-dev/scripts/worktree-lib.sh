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
