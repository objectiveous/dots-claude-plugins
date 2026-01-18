---
description: "Show all dots-swe commands and agents"
allowed-tools: ["Bash"]
---

# dots-swe Plugin Help

Software engineering tools for Claude Code - work management, beads integration, and ship workflows.

**Usage:** `/dots-swe:help`

## Commands

### Work Management

| Command | Description |
|---------|-------------|
| `/dots-swe:start <bead-id>` | Start work on a bead (creates workspace, opens Claude) |
| `/dots-swe:continue [bead-id]` | Continue work (reattach to existing session) |
| `/dots-swe:finish [bead-id]` | Finish work (verify PR merged, cleanup) |

### Quality & Shipping

| Command | Description |
|---------|-------------|
| `/dots-swe:check` | Run quality gates: test, lint, build |
| `/dots-swe:ship` | Full protocol: test, lint, build, PR, CI watch |
| `/dots-swe:doctor` | Health check for repository |

### Beads

| Command | Description |
|---------|-------------|
| `/dots-swe:beads` | Show available work and beads reference |

### Git Hooks

| Command | Description |
|---------|-------------|
| `/dots-swe:install-commit-hook` | Install Conventional Commits validator |
| `/dots-swe:uninstall-commit-hook` | Remove Conventional Commits validator |

### Help

| Command | Description |
|---------|-------------|
| `/dots-swe:help` | Show this help |

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  bd ready          # Find available work                    │
│       ↓                                                     │
│  /dots-swe:start dots-abc    # Start work                   │
│       ↓                                                     │
│  ... work in new Claude session ...                         │
│       ↓                                                     │
│  /dots-swe:ship              # Create PR, watch CI          │
│       ↓                                                     │
│  ... PR reviewed and merged ...                             │
│       ↓                                                     │
│  /dots-swe:finish            # Cleanup                      │
└─────────────────────────────────────────────────────────────┘
```

**If you need to step away:**
```bash
# Detach with ctrl+\ (Ghostty) or close window (iTerm)
# Later, continue with:
/dots-swe:continue dots-abc
```

## Terminal Support

**Auto-detected via TERM_PROGRAM:**

| Terminal | Session Manager | Detach | Reattach |
|----------|----------------|--------|----------|
| Ghostty | zmx | ctrl+\ | `/dots-swe:continue` or `zmx attach <id>` |
| iTerm2 | tmux | close window | `/dots-swe:continue` or tmux attach |

**Options for Ghostty:**
- `--tab` (default): Open in new tab
- `--window`: Open in new window

## Context Files

In each workspace:
- `.swe-bead` - Bead ID
- `.swe-context` - Task details and checklist
- `.zmx-session` or `.tmux-session` - Session name

## More Help

```bash
/dots-swe:start --help
/dots-swe:finish --help
/dots-swe:ship --help
```
