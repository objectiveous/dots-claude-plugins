# Quality Gates Enforcement

## Overview

The `dots-swe:prime` command enhances session context loading to ensure SWE agents run quality gates (tests, lint, build) before committing code. It addresses a critical gap where agents would skip verification steps despite having automated quality checks available.

## Problem Statement

SWE agents consistently skipped quality gates before committing code, leading to:
- Code committed without verification
- Broken fixes that don't actually work
- Violation of established protocols
- Bugs slipping through that should be caught in development

**Root Cause:** The `bd prime` command (from beads-marketplace) outputs a SESSION CLOSE PROTOCOL without quality gates as a required step.

## Solution

The `dots-swe:prime` command provides an enhanced context loader that:

1. **Detects project type** - Identifies available test/lint/build commands
2. **Injects quality gates** - Adds Step 0 to SESSION CLOSE PROTOCOL when quality gates are available
3. **Provides clear checklist** - Gives agents a prominent enforcement checklist
4. **Adapts to project** - Skips quality gates recommendation when no tests/lint/build detected

## Architecture

### Components

1. **dots-swe/commands/prime.md** - Command interface
   - Callable via `/dots-swe:prime`
   - Used automatically by SessionStart hook
   - Outputs enhanced context with quality gates

2. **dots-swe/scripts/prime.sh** - Implementation
   - Detects project type (Makefile, npm, cargo, go, python, etc.)
   - Builds enhanced SESSION CLOSE PROTOCOL
   - Outputs markdown (command mode) or JSON (hook mode)

3. **dots-swe/scripts/session-start.sh** - Hook integration
   - Calls prime.sh automatically on SessionStart
   - Provides context to all SWE agent sessions

### Detection Logic

The script uses `detect_project_commands()` from `swe-lib.sh` to identify:

**Priority 1: Makefile**
- Tests: `make test` or `make check`
- Lint: `make lint` or `make fmt`
- Build: `make build`

**Priority 2: JavaScript/TypeScript**
- pnpm > npm > yarn
- Tests: `pnpm test` / `npm test` / `yarn test`
- Lint: `pnpm run lint` / `npm run lint` / `yarn lint`
- Build: `pnpm run build` / `npm run build` / `yarn build`

**Priority 3-8:** Rust, Swift, Python, Go, Java, Ruby (see `swe-lib.sh` for details)

## Enhanced SESSION CLOSE PROTOCOL

### With Quality Gates (when detected)

```
[ ] 0. /dots-swe:process-check    (run tests, lint, build)
[ ] 1. git status                  (check what changed)
[ ] 2. git add <files>             (stage code changes)
[ ] 3. bd sync --from-main         (pull beads updates from main)
[ ] 4. git commit -m "..."         (commit code changes)
```

**Quality Gates Detected:**
- Tests: `npm test`
- Lint: `npm run lint`
- Build: `npm run build`

### Without Quality Gates (when not detected)

```
[ ] 1. git status              (check what changed)
[ ] 2. git add <files>         (stage code changes)
[ ] 3. bd sync --from-main     (pull beads updates from main)
[ ] 4. git commit -m "..."     (commit code changes)
```

**Note:** No quality gates detected (no tests/lint/build commands found).

## Usage

### Automatic (SessionStart Hook)

The enhanced context is automatically loaded when you start a session in an SWE worktree (identified by `.swe-bead` file).

No action required - the hook runs automatically.

### Manual Invocation

You can manually refresh the context:

```bash
/dots-swe:prime
```

This outputs the enhanced context including:
- Current task (from .swe-bead)
- Task description (from .swe-context)
- Enhanced SESSION CLOSE PROTOCOL
- Git status and recent commits
- Project conventions (CLAUDE.md)
- Dependencies (from bead metadata)

## Output Modes

### Command Mode (Interactive)

Outputs markdown-formatted context:

```bash
./dots-swe/scripts/prime.sh
```

### Hook Mode (JSON)

Outputs JSON for Claude Code system messages:

```bash
CLAUDE_HOOK=1 ./dots-swe/scripts/prime.sh
```

Returns:
```json
{
  "systemMessage": "## Current Task: ...\n\n...",
  "continue": true
}
```

## Implementation Details

### Project Type Detection

Uses `detect_project_commands()` which returns:
- `PROJECT_TYPE` - Detected type (make, npm, cargo, etc.)
- `TEST_CMD` - Command to run tests
- `LINT_CMD` - Command to run linter
- `BUILD_CMD` - Command to build project

### Quality Gates Decision

Quality gates (Step 0) are added if **any** of these are detected:
- Test command
- Lint command
- Build command

If none are detected, the protocol reverts to original bd prime format (no Step 0).

### Integration with Existing Workflow

The enhanced context:
- Preserves all original bd prime functionality
- Adds quality gates enforcement without breaking existing workflows
- Works with ephemeral branch workflow (no upstream push)
- Compatible with beads workflow (bd sync --from-main)

## Testing

### Test in Project with Quality Gates

1. Navigate to a project with tests (e.g., Node.js project with package.json)
2. Create SWE worktree: `/dots-swe:dispatch <bead-id>`
3. Verify context includes Step 0 with quality gates
4. Complete work and verify agent runs quality gates before committing

### Test in Project without Quality Gates

1. Navigate to a project without tests (e.g., markdown-only repo)
2. Create SWE worktree: `/dots-swe:dispatch <bead-id>`
3. Verify context omits Step 0
4. Verify agent can commit without quality gates

### Test Manual Invocation

```bash
cd <swe-worktree>
/dots-swe:prime
```

Expected: Outputs enhanced context with current status

## Troubleshooting

### Prime command not found

Ensure dots-swe plugin is installed:
```bash
ls ~/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/commands/prime.md
```

### Quality gates not detected

Check that your project has recognizable build files:
- Makefile
- package.json (with test/lint/build scripts)
- Cargo.toml
- go.mod
- pyproject.toml
- etc.

### Hook not running

Verify hooks are enabled:
```bash
cat .claude/settings.json | jq '.hooks'
```

Should show hooks enabled globally or for dots-swe plugin.

## Future Enhancements

### Planned Improvements

1. **Custom quality gate commands** - Allow projects to specify custom commands via `.swe-quality` config file
2. **Pre-commit hook integration** - Automatically install git hooks that enforce quality gates
3. **Skip flags** - Add `--skip-quality-gates` flag for emergency commits
4. **Quality gate results caching** - Cache results to avoid re-running on subsequent context loads
5. **Integration with TodoWrite** - Automatically add quality gates as final todo item

### Compatibility

- **beads-marketplace**: Does not modify bd prime, works alongside it
- **MCP mode**: Compatible with Model Context Protocol
- **Stealth mode**: Works in stealth mode (no bd available)
- **Multiple terminals**: Works with iTerm2 (tmux) and Ghostty (zmx)

## References

- [SWE Workflow Documentation](../dots-swe/README.md)
- [Quality Check Command](../dots-swe/commands/process-check.md)
- [Code Complete Command](../dots-swe/commands/code-complete.md)
- [Project Type Detection](../dots-swe/scripts/swe-lib.sh#L421-L551)

## Related Issues

- [dots-claude-plugins-65l] - Original issue for quality gates enforcement
- [dots-claude-plugins-ztt] - Example of agent skipping quality gates
