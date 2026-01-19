---
allowed-tools: Bash(bash:*)
description: Integrate code to main and clean up resources
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Report the complete output to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, report the complete output to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- Report the complete output without summarizing
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

**--local mode:**
1. Creates integration branch (integrate/<bead-id>) from main
2. Merges feature branch into integration branch
3. Runs tests on integration branch
4. If tests pass: merges to main, pushes to origin, proceeds to cleanup
5. If tests fail: preserves integration branch for debugging

**--remote mode:**
- Creates PR if needed (or finds existing)
- Tests run via GitHub CI/Actions
- Waits for manual PR merge
- Once merged, proceeds to cleanup

**For each successfully merged bead:**
1. Kill zmx/tmux session
2. Delete worktree
3. Delete local branch
4. Delete remote branch (unless --no-remote)
5. Close bead
6. Remove swe:code-complete label

**Examples:**
```bash
/dots-swe:code-integrate --remote                  # PR workflow for all
/dots-swe:code-integrate --local dots-abc          # Local merge for one
/dots-swe:code-integrate --remote --dry-run        # Preview PR workflow
/dots-swe:code-integrate --local --no-remote       # Local merge, keep remote
```

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/code-integrate.sh 2>/dev/null | head -1)" "$@"
