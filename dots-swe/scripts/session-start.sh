#!/bin/bash
# Auto-context loading for SWE agent sessions
# Runs at SessionStart to load bead context automatically
# Calls enhanced prime.sh for quality gates enforcement

set -euo pipefail

# Get script directory for finding prime.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set hook environment variable so prime.sh outputs JSON
export CLAUDE_HOOK=1

# Call enhanced prime.sh which builds context with quality gates
exec "$SCRIPT_DIR/prime.sh"
