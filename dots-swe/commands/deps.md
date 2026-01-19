---
description: "Visualize bead dependency graphs and relationships"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Display the complete output EXACTLY as-is to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, display the complete output EXACTLY as-is to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- DO NOT summarize or interpret the output - show the complete visualization as-is
</claude-instructions>

# Dependency Visualization

Visualize bead dependencies to understand project structure, identify blockers, and see epic hierarchies.

**Usage:**
- `/dots-swe:deps` - Show project-wide dependency overview
- `/dots-swe:deps <bead-id>` - Show dependency tree for specific bead
- `/dots-swe:deps <bead-id> --up` - Show what this bead blocks (dependents)
- `/dots-swe:deps <bead-id> --down` - Show what blocks this bead (dependencies)
- `/dots-swe:deps <bead-id> --mermaid` - Output Mermaid diagram for documentation
- `/dots-swe:deps <bead-id> --status=<status>` - Filter by status (open, in_progress, blocked, closed)

**Shows:**
- **Project Overview** (no args) - Active epics with their children, blocked issues, ready work
- **Single Bead** (with ID) - Full dependency context, parent epic, blocking relationships
- **Mermaid Diagrams** - Rich visualizations for documentation

**Use when:**
- Understanding project structure and epic hierarchies
- Identifying what's blocking progress
- Finding ready work with no dependencies
- Generating dependency diagrams for documentation
- Planning work based on dependency chains

## Implementation

!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/deps.sh 2>/dev/null | head -1)" "$@"
