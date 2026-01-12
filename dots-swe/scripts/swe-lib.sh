#!/bin/bash
# Shared worktree management functions for dots-swe plugin

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

# Get the global SWE registry file path
get_swe_registry_file() {
  echo "$HOME/.claude/swe-registry.json"
}

# Get current bead ID from worktree
get_current_bead() {
  local bead_file=".swe-bead"
  if [ -f "$bead_file" ]; then
    cat "$bead_file"
  fi
}

# =============================================================================
# tmux + iTerm2 integration
# =============================================================================

# Claude options for new sessions
get_claude_options() {
  echo "--dangerously-skip-permissions --model opus"
}

# Get tmux session name from epic/feature ID
# yap-tsd.1 → yap-tsd (groups features under epic)
get_tmux_session_name() {
  local id="$1"
  # Extract epic portion: yap-tsd.1 → yap-tsd
  echo "${id%.*}"
}

# Check if tmux session exists
tmux_session_exists() {
  local session="$1"
  tmux has-session -t "$session" 2>/dev/null
}

# Create tmux session with first window
create_tmux_session() {
  local session="$1"
  local window_name="$2"
  local working_dir="$3"

  tmux new-session -d -s "$session" -n "$window_name" -c "$working_dir"
}

# Add window to existing tmux session
add_tmux_window() {
  local session="$1"
  local window_name="$2"
  local working_dir="$3"

  tmux new-window -t "$session:" -n "$window_name" -c "$working_dir"
}

# Start Claude in a tmux window
start_claude_in_window() {
  local session="$1"
  local window_name="$2"
  local claude_opts
  claude_opts=$(get_claude_options)

  tmux send-keys -t "$session:$window_name" "claude $claude_opts" Enter
}

# Attach iTerm2 to tmux session using control mode
attach_iterm_to_tmux() {
  local session="$1"

  osascript <<EOF
tell application "iTerm2"
    activate
    create window with default profile
    tell current session of current window
        write text "tmux -CC attach -t '$session'"
    end tell
end tell
EOF
}

# Open worktree in tmux (creates session/window as needed)
open_tmux_worktree() {
  local worktree_path="$1"
  local bead_id="$2"
  local window_name="${3:-$bead_id}"
  local abs_path session_name

  abs_path="$(cd "$worktree_path" && pwd)"
  session_name=$(get_tmux_session_name "$bead_id")

  if tmux_session_exists "$session_name"; then
    # Add window to existing session
    add_tmux_window "$session_name" "$window_name" "$abs_path"
  else
    # Create new session with this as first window
    create_tmux_session "$session_name" "$window_name" "$abs_path"
  fi

  # Start Claude in the window
  start_claude_in_window "$session_name" "$window_name"

  # Return session name for tracking
  echo "$session_name"
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
  registry_file=$(get_swe_registry_file)
  mkdir -p "$(dirname "$registry_file")"
  [ ! -f "$registry_file" ] && echo "{}" > "$registry_file"
}

# Register a worktree in the global registry
register_worktree() {
  local path="$1"
  local branch="$2"
  local tab_id="$3"
  local registry_file

  registry_file=$(get_swe_registry_file)
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

  registry_file=$(get_swe_registry_file)

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

  registry_file=$(get_swe_registry_file)

  if [ -f "$registry_file" ]; then
    jq -r --arg path "$path" --arg field "$field" '.[$path][$field] // ""' "$registry_file" 2>/dev/null
  fi
}

# Open iTerm tab with Claude session (legacy wrapper for tmux)
open_iterm_claude_session() {
  local worktree_path="$1"
  local bead_id
  bead_id=$(basename "$worktree_path")
  open_tmux_worktree "$worktree_path" "$bead_id"
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
# Argument parsing helpers
# =============================================================================

# Check if a flag is present in arguments
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

# Extract non-flag arguments
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
# Batch operations
# =============================================================================

# Validate that no worktree directories already exist
validate_no_existing_worktrees() {
  local worktrees_dir="$1"
  shift
  local branch worktree_dir

  for branch in "$@"; do
    worktree_dir="$worktrees_dir/$branch"
    if [ -d "$worktree_dir" ]; then
      echo "ERROR: Worktree directory already exists: $worktree_dir"
      echo "Use /dots-swe:worktree-delete $branch to remove it first."
      return 1
    fi
  done
  return 0
}

# Create multiple worktrees
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

    # Copy .claude directory to worktree if it exists
    local repo_root
    repo_root=$(get_repo_root)
    if [ -d "$repo_root/.claude" ]; then
      cp -r "$repo_root/.claude" "$worktree_dir/"
      echo "Copied .claude/ to worktree"
    fi
  done
  return 0
}

# Open tmux windows and register worktrees
open_and_register_worktrees() {
  local worktrees_dir="$1"
  shift
  local branch worktree_dir abs_path session_name
  local first_session=""

  ensure_registry

  for branch in "$@"; do
    worktree_dir="$worktrees_dir/$branch"
    abs_path="$(cd "$worktree_dir" && pwd)"

    echo "Creating tmux window for: $branch"
    session_name=$(open_tmux_worktree "$worktree_dir" "$branch")

    # Track first session for attachment
    [ -z "$first_session" ] && first_session="$session_name"

    # Store session name locally
    echo "$session_name" > "$worktree_dir/.tmux-session"

    # Register globally
    register_worktree "$abs_path" "$branch" "$session_name"
    echo "Registered worktree: $branch (session: $session_name)"
  done

  # Attach iTerm2 to the tmux session
  if [ -n "$first_session" ]; then
    echo ""
    echo "Attaching iTerm2 to tmux session: $first_session"
    attach_iterm_to_tmux "$first_session"
  fi
}

# Delete multiple worktrees
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
