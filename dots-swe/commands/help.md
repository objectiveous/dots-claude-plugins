---
description: "Show all dots-swe commands and agents"
allowed-tools: ["Bash"]
---

# dots-swe Plugin Help

Software engineering tools for Claude Code - worktree management, beads integration, and ship workflows.

**Usage:** `/dots-swe:help`

## Commands

### Worktree Management

| Command | Description |
|---------|-------------|
| `/dots-swe:worktree-create <branch>` | Create worktree(s) with Claude sessions |
| `/dots-swe:worktree-list` | List all worktrees |
| `/dots-swe:worktree-sync [name]` | Sync worktree with main branch |
| `/dots-swe:worktree-status` | Dashboard showing all worktrees |
| `/dots-swe:worktree-attach [session]` | Re-attach iTerm2 to tmux sessions |
| `/dots-swe:worktree-delete <name>` | Delete worktree(s) and clean up |

### Beads Integration

| Command | Description |
|---------|-------------|
| `/dots-swe:work <bead-id>` | Start work from bead (creates worktree, claims task) |
| `/dots-swe:beads` | Show available work and beads reference |

### Ship Workflow

| Command | Description |
|---------|-------------|
| `/dots-swe:check` | Run quality gates: test, lint, build (no PR) |
| `/dots-swe:ship` | Full protocol: test, lint, build, PR, CI watch |
| `/dots-swe:doctor` | Health check for repository and worktrees |

### Help

| Command | Description |
|---------|-------------|
| `/dots-swe:help` | Show this help |

## Agents

### SWE Agent

**Invoke:** Load the `/swe` agent from the dots-swe plugin

**Description:** Senior software engineer agent for independent development work. Focuses on best practices, quality code, and pragmatic solutions.

**Use when:** Working on development tasks that require:
- Code implementation with tests
- Following quality standards
- Independent problem-solving
- Beads task tracking

## Quick Start

**Starting work from a bead:**
```bash
/dots-swe:work dots-abc
# Creates worktree, claims bead, opens Claude session
```

**Creating worktrees manually:**
```bash
/dots-swe:worktree-create feature/auth
# Creates worktree and opens Claude session
```

**Quality workflow:**
```bash
/dots-swe:check  # Verify tests, lint, build locally
git commit -m "feat: Add feature"
/dots-swe:ship   # Push, create PR, watch CI
```

## Configuration

**Registry:** Worktrees are tracked in `~/.claude/swe-registry.json`

**Context Files:**
- `.swe-bead` - Bead ID for current worktree
- `.swe-context` - Task context and quick reference
- `.tmux-session` - tmux session name for this worktree

**tmux Integration:**
- Worktrees from the same epic share a tmux session (appear as tabs)
- Re-attach after iTerm2 restart: `/dots-swe:worktree-attach <session>`
- Sessions persist even when iTerm2 closes

## Learn More

For detailed command help, use:
```bash
/dots-swe:<command> --help
```

Example:
```bash
/dots-swe:ship --help
/dots-swe:work --help
```
