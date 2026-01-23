# Development Workflow for dots-swe

This document explains how to develop and test the dots-swe plugin locally.

## Development Mode

The plugin supports a development mode that allows you to test changes without installing the plugin to the cache.

### Setup

Add this to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export DOTS_SWE_DEV=/Users/kenpo/SoftwareProjects/collection-one/dots-claude-plugins/dots-swe
```

Or use [direnv](https://direnv.net/) with a `.envrc` file in the project root:

```bash
export DOTS_SWE_DEV=$(pwd)/dots-swe
```

### How It Works

When `DOTS_SWE_DEV` is set:
1. All command files check `$DOTS_SWE_DEV/scripts` first
2. If not found, they fall back to the installed cache location
3. This allows you to test script changes immediately without reinstalling

When `DOTS_SWE_DEV` is NOT set:
1. Commands only check the installed cache location
2. This is the production mode that end-users experience

### Testing Changes

After modifying scripts or commands:

1. **Ensure `DOTS_SWE_DEV` is set** in your current shell
2. **Test the command** (e.g., `/dots-swe:version`)
3. **Verify it uses local scripts** by checking the output or adding debug echo statements

Example:
```bash
# Set development mode
export DOTS_SWE_DEV=/path/to/dots-claude-plugins/dots-swe

# Test a command
/dots-swe:version

# Verify path resolution
echo "Test path: $(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)"
```

### Modified Files

The following files have been updated to support development mode:

**Commands (21 files):**
- `commands/version.md`
- `commands/status.md`
- `commands/dispatch.md`
- `commands/delete.md`
- `commands/deps.md`
- `commands/doctor.md`
- `commands/ready.md`
- `commands/reconnect.md`
- `commands/code-integrate.md`
- `commands/code-integrate-status.md`
- `commands/code-complete.md`
- `commands/prime.md`
- `commands/process-check.md`
- `commands/squash.md`
- `commands/install-commit-hook.md`
- `commands/install-quality-hook.md`
- `commands/lead-start.md`
- `commands/lead-status.md`
- `commands/lead-stop.md`

**Scripts:**
- `scripts/dispatch.sh`

**Agents:**
- `agents/lead.md`

### Pattern Used

**Before:**
```bash
!bash "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/version.sh 2>/dev/null | head -1)"
```

**After:**
```bash
!bash "$(ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null | head -1)/version.sh"
```

This pattern:
1. If `DOTS_SWE_DEV` is set, lists that directory first
2. Falls back to `/nonexistent/scripts` if not set (which won't match)
3. Also lists all cache directories
4. Uses the most recent match (dev takes priority when set)
5. Appends the script name

## Installation for End Users

End users don't need to set `DOTS_SWE_DEV`. The plugin will automatically use the installed cache location.

## Troubleshooting

**Commands not finding scripts:**
- Ensure `DOTS_SWE_DEV` is exported: `export DOTS_SWE_DEV=/path/to/dots-swe`
- Verify scripts directory exists: `ls -la $DOTS_SWE_DEV/scripts`
- Check path resolution: `ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts`

**Using wrong version:**
- Unset and re-set `DOTS_SWE_DEV` in your current shell
- Verify the path: `echo $DOTS_SWE_DEV`
- Check which scripts would be found: `ls -td ${DOTS_SWE_DEV:-/nonexistent}/scripts $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts 2>/dev/null`
