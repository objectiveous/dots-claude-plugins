# Dots Claude Plugins

Claude Code plugin marketplace for Dots Workbench development and operations.

## Available Plugins

| Plugin | Description | Guide |
|--------|-------------|-------|
| `dots-dev` | Parallel development workflows with worktrees, bead integration, and automation | [Developer Guide](dots-dev/README.md) |

## Documentation

| Document | Description |
|----------|-------------|
| [dots-dev/README.md](dots-dev/README.md) | Full developer guide - installation, commands, workflows, examples |
| [CLAUDE.md](CLAUDE.md) | Project guidance for Claude Code when working in this repo |
| [AGENTS.md](AGENTS.md) | Instructions for agents using the beads workflow |

## Installation

```bash
# Add marketplace (one-time)
# The marketplace is auto-configured in Dots repo's .claude/settings.json

# Install a plugin
claude plugin install dots-dev@dots-claude-plugins
```

## For Dots Team Members

The Dots repository already has this marketplace configured. Plugins are automatically available when you run Claude Code in the Dots repo.

## Plugin Structure

```
dots-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json    # Marketplace manifest
├── dots-dev/               # Developer tools plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── commands/           # Slash commands
│   ├── agents/             # Specialist agents
│   └── scripts/            # Shared utilities
└── dots-ops/               # (future) Operations plugin
```

## Adding a New Plugin

1. Create a new directory: `my-plugin/`
2. Add `.claude-plugin/plugin.json` with at minimum: `{"name": "my-plugin"}`
3. Add components (commands/, agents/, skills/, hooks/)
4. Register in `.claude-plugin/marketplace.json`
