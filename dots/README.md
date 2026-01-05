# Dots Plugin

Dominus operations for managing Servi (worker agents) in the Dots App.

## Overview

This plugin is designed for **Dominus** (the orchestrator Claude running inside the Dots App). It provides slash commands for spawning, monitoring, and managing Servus workers via the `dots-mcp` MCP server.

**Note:** This plugin assumes execution context is the Dots App with `dots-mcp` available. For human development workflows (outside the Dots App), use `dots-dev` instead.

## Commands

| Command | Description |
|---------|-------------|
| `/dots:vibe-spawn <bead-id>` | Spawn a new Servus worker for a bead |
| `/dots:vibe-list` | List all active Servus workers |
| `/dots:vibe-kill <bead-id>` | Terminate a Servus and clean up |
| `/dots:vibe-status <bead-id> <status>` | Report Servus status to the UI |

## Requirements

- **dots-mcp**: The Python MCP server must be configured in Claude's MCP settings
- **Dots App**: This plugin is designed to run inside the Dots Workbench application

## Status Values

| Status | UI Category | Description |
|--------|-------------|-------------|
| `pending` | Beads | Created but not yet working |
| `working` | Vibing | Actively working |
| `blocked` | Escalation | Needs human help |
| `done` | (hidden) | Completed |

## Architecture

```
Dominus Console (Claude)
         │
         │ /dots:vibe-spawn
         ▼
    dots-mcp (Python MCP)
         │
         ├── Creates git worktree
         ├── Writes .servus-dispatch.md
         ├── Registers in ~/.dots/sessions.json
         └── Creates tmux session with Claude
                    │
                    ▼
              Servus Worker
                    │
                    │ report_status("bead-id", "working")
                    ▼
         ~/.dots/sessions.json updated
                    │
                    ▼
         Dots UI (Tauri) watches file
                    │
                    ▼
         Sidebar shows Servus in "Vibing"
```

## Installation

```bash
claude plugin install dots@dots-claude-plugins
```

## Related

- **dots-dev**: Human development workflows (iTerm-based, for developers)
- **dots-mcp**: Python MCP server providing the underlying tools
