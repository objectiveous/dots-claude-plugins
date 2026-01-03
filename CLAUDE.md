# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **dots-claude-plugins** marketplace - a collection of Claude Code plugins for Dots Workbench development. The marketplace provides plugin discovery and installation for the main Dots repository.

## Architecture

```
dots-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace manifest (lists available plugins)
├── dots-dev/                  # Developer tools plugin
│   ├── .claude-plugin/
│   │   └── plugin.json        # Plugin manifest
│   ├── commands/              # Slash commands (markdown files)
│   ├── agents/                # Specialist agent definitions
│   └── scripts/               # Shared bash utilities
└── (future plugins)/
```

### Plugin Components

**Commands** (`commands/*.md`): Slash commands invoked as `/plugin-name:command-name`. Use frontmatter for metadata:
```yaml
---
description: "Short description"
allowed-tools: ["Bash"]
---
```
Commands use `!` prefix for shell execution lines and `!source` for imports.

**Agents** (`agents/*.md`): Specialist agents with frontmatter defining `name`, `description`, and `tools` list. These are persona definitions for domain-specific work.

**Scripts** (`scripts/*.sh`): Shared bash functions sourced by commands via `!source "${CLAUDE_PLUGIN_ROOT}/scripts/file.sh"`.

## Available Plugin: dots-dev

Run `/dots-dev:help` for full command reference.

### Worktree Management

| Command | Purpose |
|---------|---------|
| `/dots-dev:worktree-create <branch>` | Create worktree + open Claude session |
| `/dots-dev:worktree-delete <name>` | Delete worktree + close tab |
| `/dots-dev:worktree-list` | Show all worktrees |
| `/dots-dev:worktree-status` | Dashboard with git status & bead info |
| `/dots-dev:worktree-sync [name]` | Pull latest from main |
| `/dots-dev:worktree-merge <name>` | Merge worktree back to main |
| `/dots-dev:worktree-cleanup` | Prune stale entries |
| `/dots-dev:worktree-from-bead <id>` | Create worktree from bead with auto-context |
| `/dots-dev:worktree-handoff` | Capture session context before closing |

### Coordination & Workflow

| Command | Purpose |
|---------|---------|
| `/dots-dev:broadcast <msg>` | Send message to all worktree sessions |
| `/dots-dev:ship` | Full Ship It protocol (test, lint, build, PR, CI) |
| `/dots-dev:doctor` | Health check for worktrees & beads |

### Specialist Agents

- `servus` - Worker agent for dominus/servus architecture
- `product-designer` - Feature specs and product ideation
- `kg-specialist` - Knowledge Graph / TypeQL / gist ontology

### Learning

- `/dots-dev:tutorial` - Interactive step-by-step tutorial
- `dots-dev/README.md` - Full developer guide with examples

## Adding a New Plugin

1. Create directory: `my-plugin/`
2. Add manifest: `my-plugin/.claude-plugin/plugin.json` with `{"name": "my-plugin"}`
3. Add components in `commands/`, `agents/`, `skills/`, or `hooks/` subdirectories
4. Register in `.claude-plugin/marketplace.json` plugins array

## Issue Tracking

This project uses **bd** (beads) for issue tracking:
```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress
bd close <id>
bd sync               # Sync with git
```

## Session Completion Protocol

Before ending work, complete all steps:
1. Run quality gates if code changed
2. Update beads status
3. Commit and push changes
4. Verify `git status` shows up to date with origin
