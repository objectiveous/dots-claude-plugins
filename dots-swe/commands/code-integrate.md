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

Integrate `swe:code-complete` work into main and clean up resources. Choose between local merge or GitHub PR workflow explicitly.

**Usage:** `/dots-swe:code-integrate [options] [bead-id...]`

**Required Merge Mode (choose one):**
- `--local` - Merge branch directly to main (no PR)
- `--remote` - Create/use GitHub PR for merge

**Options:**
- `--dry-run, -n` - Show what would happen without doing it
- `--force, -f` - Skip merge verification (use with caution)
- `--no-remote` - Skip remote branch deletion

**Behavior:**
- Without bead IDs: processes ALL swe:code-complete beads
- With bead IDs: processes only specified beads

**Merge Modes:**
- **--local mode:** Merges branch directly to main, pushes to origin
- **--remote mode:** Creates/finds PR, waits for manual merge if open

**For each bead:**
1. Merge to main if not already merged (per merge mode)
2. Kill zmx/tmux session
3. Delete worktree
4. Delete local branch
5. Delete remote branch (unless --no-remote)
6. Close bead
7. Remove swe:code-complete label

**Examples:**
```bash
/dots-swe:code-integrate --remote                  # PR workflow for all
/dots-swe:code-integrate --local dots-abc          # Local merge for one
/dots-swe:code-integrate --remote --dry-run        # Preview PR workflow
/dots-swe:code-integrate --local --no-remote       # Local merge, keep remote
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/code-integrate.sh 2>/dev/null | head -1)" "$@"
