---
allowed-tools: Bash(bash:*)
description: Batch cleanup of merged swe:done work
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Batch Cleanup

Clean up merged `swe:done` labeled beads - closes bead, kills session, deletes worktree and branches.

**Usage:** `/dots-swe:cleanup [options] [bead-id...]`

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--force, -f` - Skip merge verification (use with caution)
- `--no-remote` - Skip remote branch deletion

**Behavior:**
- Without bead IDs: processes ALL swe:done beads that are merged
- With bead IDs: processes only specified beads

**For each bead:**
1. Verify merged to main (unless --force)
2. Kill zmx/tmux session
3. Delete worktree
4. Delete local branch
5. Delete remote branch (unless --no-remote)
6. Close bead
7. Remove swe:done label

**Examples:**
```bash
/dots-swe:cleanup                    # Clean all merged work
/dots-swe:cleanup dots-abc           # Clean specific bead
/dots-swe:cleanup --dry-run          # Preview what would happen
/dots-swe:cleanup --no-remote        # Keep remote branches
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/cleanup.sh 2>/dev/null | head -1)" "$@"
