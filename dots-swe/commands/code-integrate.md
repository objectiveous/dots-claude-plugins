---
allowed-tools: Bash(bash:*)
description: Integrate code to main and clean up resources
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Code Integration

Integrate `swe:code-complete` work into main and clean up resources. Automatically detects GitHub PR workflow vs local merge workflow, performs the integration, then cleans up worktrees, sessions, and branches.

**Usage:** `/dots-swe:code-integrate [options] [bead-id...]`

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--force, -f` - Skip merge verification (use with caution)
- `--no-remote` - Skip remote branch deletion

**Behavior:**
- Without bead IDs: processes ALL swe:code-complete beads
- With bead IDs: processes only specified beads

**Workflow Detection:**
- **GitHub mode:** Creates/finds PR for unmerged work, waits for manual merge
- **Local mode:** Merges branch directly to main

**For each bead:**
1. Merge to main if not already merged (auto-detects GitHub/local)
2. Kill zmx/tmux session
3. Delete worktree
4. Delete local branch
5. Delete remote branch (unless --no-remote)
6. Close bead
7. Remove swe:code-complete label

**Examples:**
```bash
/dots-swe:code-integrate                    # Integrate all code-complete work
/dots-swe:code-integrate dots-abc           # Integrate specific bead
/dots-swe:code-integrate --dry-run          # Preview what would happen
/dots-swe:code-integrate --no-remote        # Keep remote branches
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/code-integrate.sh 2>/dev/null | head -1)" "$@"
