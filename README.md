# Dots Claude Plugins

Claude Code plugin marketplace for Dots Workbench development and operations.

## Available Plugins

| Plugin | For | Context | Description |
|--------|-----|---------|-------------|
| **`dots-dev`** | Human developers | Outside Dots app | Worktree workflows with iTerm, bead integration |
| **`dots`** | Dominus (Claude) | Inside Dots app | Vibe management via tmux + dots-mcp |

### Which Plugin Should I Use?

**Use `dots-dev` if you are:**
- A human developer working on Dots
- Running Claude Code in a terminal (iTerm, Terminal.app)
- Working outside the Dots Workbench application
- Creating worktrees for feature development

**Use `dots` if you are:**
- Dominus (Claude running in the Dots App's Dominus Console)
- Spawning Servus workers to complete beads
- Operating inside the Dots Workbench application
- Managing vibes (worker sessions) programmatically

## Plugin Details

### dots-dev (Human Development)

For human developers building Dots. Creates worktrees with iTerm tabs running Claude sessions.

```bash
# Install
claude plugin install dots-dev@dots-claude-plugins

# Commands
/dots-dev:worktree-create <branch>  # Create worktree + iTerm tab
/dots-dev:worktree-list             # List all worktrees
/dots-dev:worktree-delete <branch>  # Delete worktree
/dots-dev:worktree-handoff          # Prepare for PR
/dots-dev:ship                      # Full ship protocol (test, lint, build, PR)
```

[Full Documentation](dots-dev/README.md)

### dots (Dominus Operations)

For Dominus managing Servi inside the Dots App. Creates worktrees with headless tmux sessions via dots-mcp.

```bash
# Install (in Dominus Console)
claude plugin install dots@dots-claude-plugins

# Commands
/dots:vibe-spawn <bead-id>           # Spawn Servus worker
/dots:vibe-list                      # List active vibes
/dots:vibe-kill <bead-id>            # Kill vibe and cleanup
/dots:vibe-status <bead-id> <status> # Report status to UI
```

[Full Documentation](dots/README.md)

## Installation

### For Human Developers

The Dots repository has this marketplace pre-configured. When you run `claude` in the Dots repo, plugins are automatically available.

To manually install:
```bash
claude plugin install dots-dev@dots-claude-plugins
```

### For Dominus (Dots App)

The Dots App configures the `dots` plugin automatically. Dominus can use `/dots:*` commands directly.

## Upgrading Plugins

### When to Upgrade

Upgrade your plugins when:
- New features are added (check the commit history)
- Bug fixes are released
- You see "plugin version mismatch" warnings

### How to Upgrade

```bash
# Check current version
claude plugin list

# Upgrade a specific plugin
claude plugin upgrade dots-dev@dots-claude-plugins
claude plugin upgrade dots@dots-claude-plugins

# Or reinstall to get the latest
claude plugin uninstall dots-dev@dots-claude-plugins
claude plugin install dots-dev@dots-claude-plugins
```

### Breaking Changes

**v2.0.0** (Plugin Separation)
- `dots-dev` no longer includes Dots UI registry functions
- `dots-dev` dispatch files use handoff workflow (not report_status)
- New `dots` plugin for Dominus operations
- If you were using `dots-dev` for Dominus operations, switch to `dots`

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Human Developer (Terminal)                                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ /dots-dev:worktree-create feature/my-branch             ││
│  │ → Creates worktree + opens iTerm tab with Claude        ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Dots App (Dominus Console)                                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ /dots:vibe-spawn dots-d82.3                             ││
│  │ → Creates worktree + tmux session via dots-mcp          ││
│  │ → Registers in ~/.dots/sessions.json                    ││
│  │ → Servus appears in UI sidebar                          ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Documentation

| Document | Description |
|----------|-------------|
| [dots-dev/README.md](dots-dev/README.md) | Human developer guide |
| [dots/README.md](dots/README.md) | Dominus operations guide |
| [CLAUDE.md](CLAUDE.md) | Project guidance for Claude Code |
| [AGENTS.md](AGENTS.md) | Instructions for beads workflow |

## Plugin Structure

```
dots-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json    # Marketplace manifest
├── dots-dev/               # Human development plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── commands/           # Slash commands
│   ├── agents/             # Specialist agents
│   └── scripts/            # Shared utilities
└── dots/                   # Dominus operations plugin
    ├── .claude-plugin/
    │   └── plugin.json
    ├── commands/           # Vibe management commands
    └── README.md
```

## Adding a New Plugin

1. Create a new directory: `my-plugin/`
2. Add `.claude-plugin/plugin.json` with at minimum: `{"name": "my-plugin"}`
3. Add components (commands/, agents/, skills/, hooks/)
4. Register in `.claude-plugin/marketplace.json`
