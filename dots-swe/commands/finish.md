---
allowed-tools: Bash(bash:*), Bash(gh:*), Bash(git:*), Bash(zmx:*), Bash(tmux:*)
description: Finish work on a bead - verify merged to main, close bead, cleanup
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Finish Work

Complete work on a bead after merging to main.

**Usage:** `/dots-swe:finish [options] [bead-id]`

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--force, -f` - Skip merge verification

**What it does:**
1. Verifies branch was merged to main (locally or via PR)
2. Closes the bead
3. Kills the session (zmx/tmux)
4. Deletes the worktree and branch

**Merge Verification:**
- First checks if branch merged to main locally
- If not, checks for merged PR on GitHub
- Use `--force` to skip verification

**Workflows Supported:**
- **Local merge**: Merge branch to main locally, then finish
- **PR workflow**: Create PR, merge on GitHub, then finish

**Examples:**
```bash
/dots-swe:finish              # Finish current worktree's bead
/dots-swe:finish dots-abc     # Finish specific bead
/dots-swe:finish --dry-run    # Preview what would happen
/dots-swe:finish --force      # Skip merge check
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/finish.sh 2>/dev/null | head -1)" "$@"
