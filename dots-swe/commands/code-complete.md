---
description: "Mark code complete: test, lint, build, push, update bead"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
**IMPORTANT - Check if skill is already loaded:**

If you see a `<command-name>` tag in the current conversation turn:
- The skill has ALREADY been loaded by the system
- DO NOT call the Skill tool
- Execute the bash script below directly using the Bash tool
- Report the complete output to the user

If there is NO `<command-name>` tag in the current conversation turn:
- Call the Skill tool to load and execute this skill
- Check the tool result immediately - it may contain execution output or status information
- If the bash script executed, report the complete output to the user
- If you see a task_id or background process reference, use TaskOutput to check its status
- DO NOT wait passively - actively check results and report to the user

In BOTH cases:
- DO NOT manually run individual bash commands from this skill definition
- Report the complete output without summarizing
</claude-instructions>

# Code Complete

Marks code as complete by running quality gates, pushing to remote, and updating bead status.

**Note:** This command does NOT create a PR. The `swe:code-complete` label signals to another agent or human reviewer that work is ready for PR creation and merge.

**Usage:** `/dots-swe:code-complete [--skip-tests] [--skip-lint] [--skip-build]`

**Options:**
- `--skip-tests` - Skip running tests
- `--skip-lint` - Skip linting
- `--skip-build` - Skip build step

**Supported projects:**
- Makefile (any language with make targets)
- JavaScript/TypeScript (pnpm, npm, yarn)
- Rust (cargo)
- Swift (SPM, Xcode)
- Python (pytest, ruff/flake8)
- Go (go test, golangci-lint)
- Java (Maven, Gradle)
- Ruby (rspec, rubocop)

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:code-complete [OPTIONS]"
  echo ""
  echo "Mark code as complete: tests, linting, build, push, update bead."
  echo ""
  echo "Options:"
  echo "  --skip-tests    Skip running tests"
  echo "  --skip-lint     Skip linting"
  echo "  --skip-build    Skip build step"
  echo "  --help, -h      Show this help"
  echo ""
  echo "The command will:"
  echo "  0. Fetch and rebase onto origin/main"
  echo "  1. Verify no uncommitted changes"
  echo "  2. Run tests"
  echo "  3. Run linter"
  echo "  4. Run build"
  echo "  5. Push to remote (with --force-with-lease after rebase)"
  echo "  6. Add comment to bead"
  echo "  7. Add swe:code-complete label (keeps status: in_progress)"
  echo ""
  echo "Note: PR creation is handled separately by a reviewer agent or human."
  exit 0
fi

!SKIP_TESTS=$(has_flag "--skip-tests" "$@" && echo true || echo false)
!SKIP_LINT=$(has_flag "--skip-lint" "$@" && echo true || echo false)
!SKIP_BUILD=$(has_flag "--skip-build" "$@" && echo true || echo false)

!echo "=================================================================="
!echo "                      Code Complete                               "
!echo "=================================================================="
!echo ""

!BRANCH=$(git branch --show-current)
!echo "Branch: $BRANCH"
!echo ""

# Check for uncommitted changes (excluding swe metadata files)
!CHANGES=$(git status --porcelain | grep -v '^?? \.swe-' | wc -l | tr -d ' ')
!if [ "$CHANGES" -gt 0 ]; then
  echo "WARNING: You have uncommitted changes:"
  git status --short | grep -v '^?? \.swe-'
  echo ""
  echo "Commit your changes before marking code complete."
  exit 1
fi

# Step 0: Fetch and rebase onto main
!echo "------------------------------------------------------------------"
!echo "Step 0: Fetching latest and rebasing onto main..."
!echo ""

# Fetch latest from origin
!if ! git fetch origin; then
  echo "ERROR: Failed to fetch from origin"
  exit 1
fi

# Check if we're already up to date with origin/main
!BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
!if [ "$BEHIND" = "0" ]; then
  echo "Already up to date with origin/main"
else
  echo "Behind origin/main by $BEHIND commits, rebasing..."

  # Attempt rebase
  if git rebase origin/main; then
    echo "Rebase successful"
  else
    echo ""
    echo "ERROR: Rebase failed due to conflicts"
    echo ""
    echo "To resolve:"
    echo "  1. Fix conflicts in the files listed above"
    echo "  2. Stage resolved files: git add <file>"
    echo "  3. Continue rebase: git rebase --continue"
    echo "  4. Or abort: git rebase --abort"
    echo ""
    echo "After resolving conflicts, run /dots-swe:code-complete again"
    exit 1
  fi
fi
!echo ""

# Detect project type and commands
!eval "$(detect_project_commands)"
!echo "Detected project type: $PROJECT_TYPE"
!echo ""

# Step 1: Tests
!echo "------------------------------------------------------------------"
!if [ "$SKIP_TESTS" = true ]; then
  echo "Step 1: Tests (skipped)"
else
  echo "Step 1: Running tests..."
  if [ -n "$TEST_CMD" ]; then
    if eval "$TEST_CMD"; then
      echo "Tests passed"
    else
      echo "Tests failed"
      exit 1
    fi
  else
    echo "No test command detected"
  fi
fi
!echo ""

# Step 2: Lint
!echo "------------------------------------------------------------------"
!if [ "$SKIP_LINT" = true ]; then
  echo "Step 2: Lint (skipped)"
else
  echo "Step 2: Running linter..."
  if [ -n "$LINT_CMD" ]; then
    if eval "$LINT_CMD"; then
      echo "Lint passed"
    else
      echo "Lint failed"
      exit 1
    fi
  else
    echo "No linter detected"
  fi
fi
!echo ""

# Step 3: Build
!echo "------------------------------------------------------------------"
!if [ "$SKIP_BUILD" = true ]; then
  echo "Step 3: Build (skipped)"
else
  echo "Step 3: Building..."
  if [ -n "$BUILD_CMD" ]; then
    if eval "$BUILD_CMD"; then
      echo "Build passed"
    else
      echo "Build failed"
      exit 1
    fi
  else
    echo "No build command detected"
  fi
fi
!echo ""

# Step 4: Push to remote
!echo "------------------------------------------------------------------"
!echo "Step 4: Pushing to remote..."
# Use --force-with-lease if we rebased (safer than --force)
!if [ "$BEHIND" != "0" ]; then
  echo "Using --force-with-lease after rebase..."
  git push --force-with-lease -u origin "$BRANCH"
else
  git push -u origin "$BRANCH"
fi
!echo "Push complete"
!echo ""

# Step 5: Update bead with completion marker
!echo "------------------------------------------------------------------"
!echo "Step 5: Marking code complete..."
!CURRENT_BEAD=$(get_current_bead)
!if [ -n "$CURRENT_BEAD" ]; then
  echo "Adding completion marker to bead $CURRENT_BEAD..."
  bd comment "$CURRENT_BEAD" "Code complete - quality gates passed, ready for PR and merge" 2>/dev/null
  bd label add "$CURRENT_BEAD" swe:code-complete 2>/dev/null
  bd sync --message "chore: sync beads database" 2>/dev/null
  echo "Bead updated (status: in_progress, label: swe:code-complete)"
else
  echo "No bead associated with this worktree"
fi
!echo ""

!echo "------------------------------------------------------------------"
!echo "Code complete!"
!echo ""
!echo "Branch: $BRANCH"
!echo "Status: Ready for integration into main repository"
!echo ""
!echo "Next steps:"
!echo "  - For GitHub PR workflow:"
!echo "    /dots-swe:code-integrate --remote"
!echo ""
!echo "  - For local merge (with tests):"
!echo "    /dots-swe:code-integrate --local"
!echo ""
!echo "  - Check what's ready to integrate:"
!echo "    /dots-swe:code-integrate-status"
!echo ""

# Display bead summary
!CURRENT_BEAD=$(get_current_bead)
!if [ -n "$CURRENT_BEAD" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Bead Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Fetch bead metadata using JSON output for reliable parsing
  # Extract only the fields we need to avoid control character issues
  BEAD_ID=$(bd show "$CURRENT_BEAD" --json 2>/dev/null | jq -r '.[0].id // ""' 2>/dev/null)
  BEAD_TITLE=$(bd show "$CURRENT_BEAD" --json 2>/dev/null | jq -r '.[0].title // ""' 2>/dev/null)
  BEAD_DESC=$(bd show "$CURRENT_BEAD" --json 2>/dev/null | jq -r '.[0].description // ""' 2>/dev/null)
  BEAD_TYPE=$(bd show "$CURRENT_BEAD" --json 2>/dev/null | jq -r '.[0].issue_type // ""' 2>/dev/null)
  BEAD_STATUS=$(bd show "$CURRENT_BEAD" --json 2>/dev/null | jq -r '.[0].status // ""' 2>/dev/null)
  BEAD_PARENT=$(bd show "$CURRENT_BEAD" --json 2>/dev/null | jq -r '.[0].parent // ""' 2>/dev/null)

  if [ -n "$BEAD_ID" ]; then
    echo "ID:          $BEAD_ID"
    echo "Title:       $BEAD_TITLE"
    if [ -n "$BEAD_DESC" ]; then
      echo "Description: $BEAD_DESC"
    fi
    echo "Type:        $BEAD_TYPE"
    echo "Status:      $BEAD_STATUS (marked swe:code-complete)"

    # Display parent if it exists
    if [ -n "$BEAD_PARENT" ] && [ "$BEAD_PARENT" != "null" ]; then
      # Get parent title
      PARENT_TITLE=$(bd show "$BEAD_PARENT" --json 2>/dev/null | jq -r '.[0].title // ""' 2>/dev/null)
      if [ -n "$PARENT_TITLE" ]; then
        echo "Parent: $BEAD_PARENT - $PARENT_TITLE"
      else
        echo "Parent: $BEAD_PARENT"
      fi
    fi
    echo ""
  else
    echo "Unable to fetch bead metadata for: $CURRENT_BEAD"
    echo ""
  fi
fi
