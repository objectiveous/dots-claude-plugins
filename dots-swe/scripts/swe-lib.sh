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

# Attach Ghostty to tmux session
attach_ghostty_to_tmux() {
  local session="$1"

  osascript <<EOF
tell application "Ghostty"
    activate
end tell
delay 0.3
tell application "System Events"
    tell process "Ghostty"
        keystroke "n" using command down
        delay 0.2
        keystroke "tmux attach -t '$session'"
        keystroke return
    end tell
end tell
EOF
}

# =============================================================================
# zmx + Ghostty integration
# =============================================================================

# Check if zmx session exists
zmx_session_exists() {
  local session="$1"
  zmx list 2>/dev/null | grep -q "session_name=$session"
}

# Kill zmx session if it exists
kill_zmx_session() {
  local session="$1"
  if zmx_session_exists "$session"; then
    zmx kill "$session" 2>/dev/null
    echo "Killed zmx session: $session"
  fi
}

# Open new Ghostty window with zmx session
open_ghostty_zmx_window() {
  local worktree_path="$1"
  local session_name="$2"
  local abs_path claude_opts

  abs_path="$(cd "$worktree_path" && pwd)"
  claude_opts=$(get_claude_options)

  # Open new Ghostty window with zmx attach command
  open -na Ghostty --args --title="$session_name" --working-directory="$abs_path" -e zmx attach "$session_name" claude $claude_opts
}

# Open new Ghostty tab with zmx session
open_ghostty_zmx_tab() {
  local worktree_path="$1"
  local session_name="$2"
  local abs_path claude_opts

  abs_path="$(cd "$worktree_path" && pwd)"
  claude_opts=$(get_claude_options)

  # Use AppleScript to open new tab and run command
  osascript <<EOF
tell application "ghostty"
    activate
end tell
delay 0.2
tell application "System Events"
    tell process "ghostty"
        keystroke "t" using command down
        delay 0.3
        keystroke "printf '\\\\033]0;$session_name\\\\007' && cd '$abs_path' && zmx attach '$session_name' claude $claude_opts"
        keystroke return
    end tell
end tell
EOF
}

# Open Ghostty with zmx session (window or tab based on SWE_GHOSTTY_MODE)
# Set SWE_GHOSTTY_MODE=window for windows, default is tab
open_ghostty_zmx_session() {
  local worktree_path="$1"
  local session_name="$2"
  local mode="${SWE_GHOSTTY_MODE:-tab}"

  case "$mode" in
    tab)
      open_ghostty_zmx_tab "$worktree_path" "$session_name"
      ;;
    *)
      open_ghostty_zmx_window "$worktree_path" "$session_name"
      ;;
  esac
}

# Start Claude in background zmx session (for batch operations)
start_zmx_session_background() {
  local worktree_path="$1"
  local session_name="$2"
  local abs_path claude_opts

  abs_path="$(cd "$worktree_path" && pwd)"
  claude_opts=$(get_claude_options)

  # zmx run starts session without attaching
  (cd "$abs_path" && zmx run "$session_name" claude $claude_opts)
}

# =============================================================================
# Terminal detection and dispatch
# =============================================================================

# Get current terminal from TERM_PROGRAM
# iTerm2 sets: iTerm.app
# Ghostty sets: ghostty
get_swe_terminal() {
  case "${TERM_PROGRAM:-}" in
    ghostty) echo "ghostty" ;;
    *)       echo "iterm" ;;
  esac
}

# Attach terminal to tmux session (dispatcher) - for iTerm only now
attach_terminal_to_tmux() {
  local session="$1"
  local terminal
  terminal=$(get_swe_terminal)

  case "$terminal" in
    ghostty)
      # Ghostty uses zmx, not tmux - this shouldn't be called
      echo "Warning: Ghostty should use zmx, not tmux" >&2
      attach_ghostty_to_tmux "$session"
      ;;
    *)
      attach_iterm_to_tmux "$session"
      ;;
  esac
}

# Open worktree session - main dispatcher
# Uses zmx+Ghostty for Ghostty, tmux+AppleScript for iTerm
open_worktree_session() {
  local worktree_path="$1"
  local session_name="$2"
  local terminal

  terminal=$(get_swe_terminal)

  case "$terminal" in
    ghostty)
      # Opens new Ghostty window/tab with zmx session
      open_ghostty_zmx_session "$worktree_path" "$session_name"
      ;;
    *)
      # iTerm: use tmux in background + AppleScript to attach
      open_tmux_worktree "$worktree_path" "$session_name"
      ;;
  esac
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

# Open sessions and register worktrees
# For Ghostty: uses zmx (starts in background, then attaches to first)
# For iTerm: uses tmux (creates windows, then attaches via AppleScript)
open_and_register_worktrees() {
  local worktrees_dir="$1"
  shift
  local branch worktree_dir abs_path session_name
  local first_session=""
  local terminal

  ensure_registry
  terminal=$(get_swe_terminal)

  for branch in "$@"; do
    worktree_dir="$worktrees_dir/$branch"
    abs_path="$(cd "$worktree_dir" && pwd)"

    if [ "$terminal" = "ghostty" ]; then
      echo "Creating zmx session for: $branch"
      start_zmx_session_background "$worktree_dir" "$branch"
      session_name="$branch"
      echo "$session_name" > "$worktree_dir/.zmx-session"
    else
      echo "Creating tmux window for: $branch"
      session_name=$(open_tmux_worktree "$worktree_dir" "$branch")
      echo "$session_name" > "$worktree_dir/.tmux-session"
    fi

    # Track first session for attachment
    [ -z "$first_session" ] && first_session="$session_name"

    # Register globally
    register_worktree "$abs_path" "$branch" "$session_name"
    echo "Registered worktree: $branch (session: $session_name)"
  done

  # Attach to the first session
  if [ -n "$first_session" ]; then
    echo ""
    if [ "$terminal" = "ghostty" ]; then
      local mode="${SWE_GHOSTTY_MODE:-tab}"
      echo "Opening Ghostty $mode for zmx session: $first_session"
      echo "(Other sessions running in background - use 'zmx attach <name>' to switch)"
      worktree_dir="$worktrees_dir/$first_session"
      open_ghostty_zmx_session "$worktree_dir" "$first_session"
    else
      echo "Attaching $terminal to tmux session: $first_session"
      attach_terminal_to_tmux "$first_session"
    fi
  fi
}

# Delete multiple worktrees
delete_worktrees() {
  local worktree_name worktree_path branch_name tab_id zmx_session

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

    # Get tab ID from registry (for iTerm/tmux)
    tab_id=$(get_worktree_info "$worktree_path" "tab_id")

    # Check for zmx session
    zmx_session=""
    if [ -f "$worktree_path/.zmx-session" ]; then
      zmx_session=$(cat "$worktree_path/.zmx-session")
    fi

    echo "  Branch: $branch_name"
    echo "  Path: $worktree_path"
    [ -n "$tab_id" ] && echo "  tmux session: $tab_id"
    [ -n "$zmx_session" ] && echo "  zmx session: $zmx_session"

    # Kill zmx session if exists
    if [ -n "$zmx_session" ]; then
      echo "  Killing zmx session..."
      kill_zmx_session "$zmx_session"
    fi

    # Close iTerm tab if we have a tab ID (legacy tmux)
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
