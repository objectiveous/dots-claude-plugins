---
allowed-tools: Bash(bash:*), Bash(gh:*), Bash(git:*), Bash(zmx:*), Bash(tmux:*)
description: Finish work on a bead - verify PR merged, close bead, cleanup
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Finish Work

Complete work on a bead after the PR is merged.

**Usage:** `/dots-swe:finish [options] [bead-id]`

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--force, -f` - Skip PR merge check

**What it does:**
1. Verifies PR was opened and merged to main
2. Closes the bead
3. Kills the session (zmx/tmux)
4. Deletes the worktree and branch

**Examples:**
```bash
/dots-swe:finish              # Finish current worktree's bead
/dots-swe:finish dots-abc     # Finish specific bead
/dots-swe:finish --dry-run    # Preview what would happen
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/finish.sh 2>/dev/null | head -1)" "$@"
