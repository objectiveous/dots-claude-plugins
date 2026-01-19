---
description: "Run quality gates: test, lint, build (no PR)"
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

# Quality Check

Runs quality gates (test, lint, build) without creating a PR. Use this to verify your code before committing or shipping.

**Usage:** `/dots-swe:check [--skip-tests] [--skip-lint] [--skip-build]`

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
  echo "Usage: /dots-swe:check [OPTIONS]"
  echo ""
  echo "Run quality gates without creating a PR."
  echo ""
  echo "Options:"
  echo "  --skip-tests    Skip running tests"
  echo "  --skip-lint     Skip linting"
  echo "  --skip-build    Skip build step"
  echo "  --help, -h      Show this help"
  echo ""
  echo "Use /dots-swe:code-complete to run the full protocol (tests + push + mark complete)."
  exit 0
fi

!SKIP_TESTS=$(has_flag "--skip-tests" "$@" && echo true || echo false)
!SKIP_LINT=$(has_flag "--skip-lint" "$@" && echo true || echo false)
!SKIP_BUILD=$(has_flag "--skip-build" "$@" && echo true || echo false)

!echo "=================================================================="
!echo "                     Quality Check                                "
!echo "=================================================================="
!echo ""

!BRANCH=$(git branch --show-current)
!echo "Branch: $BRANCH"
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

!echo "------------------------------------------------------------------"
!echo "Quality check complete!"
!echo ""
!echo "All gates passed. Ready to commit or ship."
!echo ""
!echo "Next steps:"
!echo "  - Commit your changes"
!echo "  - Run /dots-swe:code-complete to push and mark complete"
