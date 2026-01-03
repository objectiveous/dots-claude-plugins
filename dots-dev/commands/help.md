---
description: "Show all dots-dev plugin commands and agents"
allowed-tools: ["Bash"]
---

# Dots Dev Plugin Help

Shows all available commands and agents in the dots-dev plugin.

**Usage:** `/dots-dev:help`

## Implementation

# Help flag (meta - help for help)
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:help"
  echo ""
  echo "Show all dots-dev plugin commands and agents."
  echo ""
  echo "Tip: All commands support --help for detailed usage."
  echo "Example: /dots-dev:ship --help"
  exit 0
fi

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                     dots-dev Plugin                          ║"
!echo "║        Developer tools for Dots Workbench                    ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!echo "WORKTREE MANAGEMENT"
!echo "───────────────────────────────────────────────────────────────"
!echo "  /dots-dev:worktree-create <branch> [...]  Create worktrees + Claude sessions"
!echo "  /dots-dev:worktree-delete <name> [...]    Delete worktrees + close tabs"
!echo "  /dots-dev:worktree-list                   List all worktrees"
!echo "  /dots-dev:worktree-status                 Dashboard with git status & beads"
!echo "  /dots-dev:worktree-sync [name]            Pull latest from main"
!echo "  /dots-dev:worktree-merge <name>           Merge worktree back to main"
!echo "  /dots-dev:worktree-cleanup [--prune-merged]  Remove stale worktrees"
!echo "  /dots-dev:worktree-from-bead <bead-id>    Create worktree from bead"
!echo "  /dots-dev:worktree-handoff                Capture session context"
!echo ""

!echo "COORDINATION"
!echo "───────────────────────────────────────────────────────────────"
!echo "  /dots-dev:broadcast <message>             Send message to all worktrees"
!echo ""

!echo "WORKFLOW"
!echo "───────────────────────────────────────────────────────────────"
!echo "  /dots-dev:ship                            Run full Ship It protocol"
!echo "  /dots-dev:doctor                          Health check for worktrees & beads"
!echo ""

!echo "SPECIALIST AGENTS"
!echo "───────────────────────────────────────────────────────────────"
!echo "  servus            Worker agent for dominus/servus architecture"
!echo "  product-designer  Feature specs and product ideation"
!echo "  kg-specialist     Knowledge Graph / TypeQL / gist ontology"
!echo ""

!echo "LEARNING"
!echo "───────────────────────────────────────────────────────────────"
!echo "  /dots-dev:tutorial              Interactive step-by-step tutorial"
!echo "  /dots-dev:tutorial --reset      Restart tutorial from beginning"
!echo "  /dots-dev:tutorial --status     Check tutorial progress"
!echo "  dots-dev/README.md              Full developer guide"
!echo ""

!echo "QUICK START"
!echo "───────────────────────────────────────────────────────────────"
!echo "  # Create parallel work sessions:"
!echo "  /dots-dev:worktree-create feature/auth feature/api"
!echo ""
!echo "  # Work from a bead:"
!echo "  /dots-dev:worktree-from-bead dots-abc"
!echo ""
!echo "  # When done with a feature:"
!echo "  /dots-dev:ship"
!echo ""
!echo "───────────────────────────────────────────────────────────────"
!echo "Tip: All commands support --help for detailed usage."
!echo "Example: /dots-dev:ship --help"
!echo ""
