# dots-dev Plugin

**Developer tools for parallel Claude Code workflows**

The dots-dev plugin transforms how you work with Claude Code by enabling parallel development sessions across git worktrees. Instead of context-switching between tasks, spawn isolated worktrees with dedicated Claude sessions - each with its own branch, bead context, and terminal tab.

## Why This Plugin?

Traditional development with Claude Code is sequential: one conversation, one task, one branch. But real work is parallel - you're fixing a bug while a feature review comes in, or you need to spike on an idea without disrupting your current work.

dots-dev solves this by:

1. **Parallel Sessions** - Spawn multiple Claude sessions, each in its own worktree
2. **Bead Integration** - Connect worktrees to beads for automatic context and status tracking
3. **Coordination** - Broadcast messages across sessions, capture handoffs between sessions
4. **Workflow Automation** - One command to run the full ship-it protocol (test, lint, build, PR, CI)

## Installation

The dots-dev plugin is distributed via the dots-claude-plugins marketplace.

```bash
# Install the plugin
claude plugin install dots-dev@dots-claude-plugins

# Verify installation
/dots-dev:help
```

For Dots team members, the plugin is auto-configured in the Dots repository's `.claude/settings.json`.

## Upgrading

To get the latest features and bug fixes:

```bash
# Update the plugin to latest version
claude plugin update dots-dev@dots-claude-plugins

# Or reinstall to force a fresh copy
claude plugin uninstall dots-dev@dots-claude-plugins
claude plugin install dots-dev@dots-claude-plugins
```

**When to upgrade:**
- After new commands are announced
- If you encounter bugs that may have been fixed
- Periodically to stay current

**After upgrading:**
- Run `/dots-dev:help` to see any new commands
- Check the changelog in `dots-dev/README.md` for what's new

## Quick Start

```bash
# See all available commands
/dots-dev:help

# Create two parallel work sessions
/dots-dev:worktree-create feature/auth feature/api

# Or work directly from a bead
/dots-dev:worktree-from-bead dots-abc

# When done with a feature
/dots-dev:ship
```

## Core Concepts

### Worktrees

Git worktrees let you have multiple working directories from a single repository. Each worktree has its own branch and working tree, but shares the git history. dots-dev creates worktrees in `.worktrees/` and opens each in a new iTerm tab with Claude.

### Bead Context

When you create a worktree from a bead (`/dots-dev:worktree-from-bead`), the plugin:
- Creates a `.claude-bead` file storing the bead ID
- Claims the bead (marks it `in_progress`)
- The servus agent automatically detects this context

### Session Handoffs

Before closing a session, run `/dots-dev:worktree-handoff` to capture:
- What was accomplished
- What remains
- Any blockers
- Notes for the next session

The next Claude session in that worktree sees this handoff automatically.

### Broadcasting

The dominus (coordinator) can send messages to all servus (worker) sessions:

```bash
/dots-dev:broadcast Main updated - please run /dots-dev:worktree-sync
```

---

## Command Reference

### Worktree Management

#### `/dots-dev:worktree-create <branch> [...]`

Create one or more worktrees and open Claude sessions.

```bash
# Single worktree
/dots-dev:worktree-create feature/auth

# Multiple worktrees
/dots-dev:worktree-create feature/api feature/ui bugfix/login

# Uses existing branch if found, creates new branch if not
```

**What happens:**
1. Creates `.worktrees/<branch>` directory
2. Either checks out existing branch or creates new from current
3. Opens iTerm tab with `claude` running in the worktree
4. Registers in `~/.claude/worktree-registry.json`

#### `/dots-dev:worktree-from-bead <bead-id>`

Create a worktree directly from a bead with full context setup.

```bash
/dots-dev:worktree-from-bead dots-abc
```

**What happens:**
1. Verifies bead exists via `bd show`
2. Creates worktree with branch named after bead
3. Writes `.claude-bead` file with bead ID
4. Claims bead (`bd update <id> --status=in_progress`)
5. Opens Claude session

**Why use this:** The servus agent automatically detects the bead context, so you don't need to specify it in the task. The agent will:
- Read the handoff if one exists
- Check for broadcasts
- Know which bead it's working on

#### `/dots-dev:worktree-delete <name> [...]`

Delete worktrees, close tabs, clean up branches.

```bash
/dots-dev:worktree-delete feature/auth
/dots-dev:worktree-delete dots-abc dots-def  # Multiple
```

#### `/dots-dev:worktree-list`

Simple list of all worktrees.

#### `/dots-dev:worktree-status`

Dashboard showing each worktree with:
- Branch and path
- Uncommitted changes count
- Unpushed commits count
- Associated bead
- Creation timestamp

```bash
/dots-dev:worktree-status
```

#### `/dots-dev:worktree-sync [name]`

Pull latest from main into a worktree via rebase.

```bash
/dots-dev:worktree-sync              # Current worktree
/dots-dev:worktree-sync feature/auth # Specific worktree
```

**Behavior:**
- Stashes uncommitted changes
- Rebases onto `origin/main`
- Restores stash

#### `/dots-dev:worktree-merge <name> [--cleanup]`

Merge a completed worktree back to main.

```bash
/dots-dev:worktree-merge feature/auth
/dots-dev:worktree-merge dots-abc --cleanup  # Also delete worktree
```

**Requirements:** No uncommitted changes in the worktree.

#### `/dots-dev:worktree-cleanup [--prune-merged]`

Clean up stale worktrees and registry entries.

```bash
/dots-dev:worktree-cleanup
/dots-dev:worktree-cleanup --prune-merged  # Also remove merged branches
```

---

### Coordination

#### `/dots-dev:broadcast <message>`

Send a message to all active worktree sessions.

```bash
/dots-dev:broadcast Stopping for lunch - save your work
/dots-dev:broadcast Main updated - run /dots-dev:worktree-sync
/dots-dev:broadcast Standup in 5 minutes
```

**How it works:**

1. Writes message to `.claude-broadcast` in each registered worktree
2. Servus agents check for this file on startup
3. Message is displayed and file is deleted after reading

**Use cases:**
- Notify workers that main has been updated
- Coordinate breaks or meetings
- Alert about blocking issues
- Signal end of work session

**Example broadcast file content:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📢 BROADCAST [14:32:15]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Main updated - run /dots-dev:worktree-sync

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### `/dots-dev:worktree-handoff`

Capture session context before closing a worktree.

```bash
/dots-dev:worktree-handoff
```

**Creates `.claude-handoff` containing:**
- Associated bead ID (from `.claude-bead`)
- Last commit hash and message
- List of uncommitted changes
- Unpushed commits
- Template sections to fill in:
  - **Session Summary** - What was accomplished
  - **Remaining Work** - What still needs doing
  - **Blockers** - Issues preventing progress
  - **Notes for Next Session** - Context, tips, gotchas

**Example handoff file:**
```markdown
# Session Handoff: dots-abc
Generated: 2024-01-15T14:30:00Z

## Bead
dots-abc

## Last Commit
a1b2c3d Add authentication middleware

## Uncommitted Changes
```
M  src/auth/handler.ts
A  src/auth/types.ts
```

## Session Summary
Implemented JWT validation middleware. Added type definitions for auth tokens.

## Remaining Work
- [ ] Add refresh token logic
- [ ] Write unit tests for middleware
- [ ] Update API docs

## Blockers
Need clarification on token expiry policy - asked in #backend channel.

## Notes for Next Session
The `validateToken` function is intentionally permissive right now -
tighten once we confirm requirements. See TODO on line 45.
```

**Why use this:** Context is expensive. When you (or another Claude session) return to this worktree, the handoff provides immediate orientation without re-reading code or guessing what was in progress.

---

### Workflow

#### `/dots-dev:ship`

Run the complete Ship It protocol in one command.

```bash
/dots-dev:ship
/dots-dev:ship --skip-tests      # Skip test step
/dots-dev:ship --skip-lint       # Skip lint step
/dots-dev:ship --skip-build      # Skip build step
```

**The protocol:**

1. **Verify** - Check for uncommitted changes (fails if any)
2. **Test** - Run `pnpm test` / `npm test` / `cargo test`
3. **Lint** - Run `pnpm run lint` / `npm run lint` / `cargo clippy`
4. **Build** - Run `pnpm run build` / `npm run build` / `cargo build --release`
5. **Push** - Push branch to origin
6. **PR** - Create pull request via `gh pr create`
7. **Watch CI** - Wait for CI checks via `gh pr checks --watch`
8. **Update Bead** - If `.claude-bead` exists, mark `ready_to_merge`

**Why one command:** The manual version of this is 7+ commands with waiting and checking. `/dots-dev:ship` automates the entire flow and handles failures gracefully.

**On failure:** The command stops and reports what failed. Fix the issue and run `/dots-dev:ship` again - it's idempotent.

#### `/dots-dev:doctor`

Health check for worktrees, branches, and beads.

```bash
/dots-dev:doctor
```

**Checks:**
1. Stale git worktree references
2. Worktrees with uncommitted changes
3. Worktrees with unpushed commits
4. Stale registry entries
5. Merged branches not deleted
6. Beads sync status
7. Main branch vs origin

---

### Help

#### `/dots-dev:help`

Show all commands and agents.

#### `/dots-dev:tutorial`

Interactive tutorial walking through the workflow.

#### `<command> --help`

All commands support `--help` for detailed usage:

```bash
/dots-dev:ship --help
/dots-dev:worktree-create --help
```

---

## Specialist Agents

### servus

Worker agent for the dominus/servus architecture. Designed to:
- Auto-detect bead context from `.claude-bead` or branch name
- Check for handoffs and broadcasts on startup
- Execute the Ship It protocol
- Escalate blockers properly

### product-designer

Feature specs and product ideation for Dots Workbench.

### kg-specialist

Knowledge Graph specialist for TypeQL schemas and gist ontology translation.

---

## Example Workflows

### Parallel Feature Development

```bash
# Dominus creates worktrees for two features
/dots-dev:worktree-create feature/auth feature/notifications

# Each worktree opens in its own iTerm tab with Claude
# Work proceeds in parallel

# Check status across all worktrees
/dots-dev:worktree-status

# When auth feature is done
# (in the auth worktree)
/dots-dev:ship

# Merge and cleanup
/dots-dev:worktree-merge feature/auth --cleanup
```

### Bead-Driven Development

```bash
# Find available work
bd ready

# Create worktree from bead (auto-claims it)
/dots-dev:worktree-from-bead dots-abc

# Servus agent automatically knows the context
# Work on the task...

# Ship when done (auto-updates bead status)
/dots-dev:ship

# Dominus merges when ready
/dots-dev:worktree-merge dots-abc --cleanup
```

### Coordinated Work Session

```bash
# Dominus sets up work
/dots-dev:worktree-from-bead dots-abc
/dots-dev:worktree-from-bead dots-def
/dots-dev:worktree-from-bead dots-ghi

# Later, main gets updated
/dots-dev:broadcast Main updated - run /dots-dev:worktree-sync

# Before lunch
/dots-dev:broadcast Stopping at 12:30 - please run worktree-handoff

# End of day - check health
/dots-dev:doctor
```

### Session Handoff

```bash
# Before closing your session
/dots-dev:worktree-handoff

# Fill in the sections that appear
# The next session will see this context
```

---

## File Conventions

| File | Purpose |
|------|---------|
| `.claude-bead` | Bead ID for this worktree |
| `.claude-handoff` | Session handoff document |
| `.claude-broadcast` | Pending broadcast message |
| `.claude-tab-id` | iTerm tab ID for this worktree |
| `~/.claude/worktree-registry.json` | Global worktree registry |

---

## Tips

1. **Always handoff** - Run `/dots-dev:worktree-handoff` before closing a session
2. **Ship early, ship often** - Use `/dots-dev:ship` to get feedback quickly
3. **Check health** - Run `/dots-dev:doctor` at start and end of work sessions
4. **Broadcast updates** - Keep parallel sessions informed
5. **Use beads** - `/dots-dev:worktree-from-bead` provides the best context setup
