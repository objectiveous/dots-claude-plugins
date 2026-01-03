---
description: "Run the full Ship It protocol: test, lint, build, PR, CI watch"
allowed-tools: ["Bash"]
---

# Ship It Protocol

Runs the complete shipping workflow: tests, linting, build, create PR, and watch CI.

**Usage:** `/dots-dev:ship [--skip-tests] [--skip-lint] [--skip-build]`

**Options:**
- `--skip-tests` - Skip running tests
- `--skip-lint` - Skip linting
- `--skip-build` - Skip build step

## Implementation

!source "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-lib.sh"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:ship [OPTIONS]"
  echo ""
  echo "Run the complete Ship It protocol: tests, linting, build, PR creation, and CI watch."
  echo ""
  echo "Options:"
  echo "  --skip-tests    Skip running tests"
  echo "  --skip-lint     Skip linting"
  echo "  --skip-build    Skip build step"
  echo "  --help, -h      Show this help"
  echo ""
  echo "The command will:"
  echo "  1. Verify no uncommitted changes"
  echo "  2. Run tests (pnpm/npm/cargo)"
  echo "  3. Run linter"
  echo "  4. Run build"
  echo "  5. Push and create PR"
  echo "  6. Watch CI checks"
  echo "  7. Update bead status if .claude-bead exists"
  exit 0
fi

!SKIP_TESTS=$(has_flag "--skip-tests" "$@" && echo true || echo false)
!SKIP_LINT=$(has_flag "--skip-lint" "$@" && echo true || echo false)
!SKIP_BUILD=$(has_flag "--skip-build" "$@" && echo true || echo false)

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                      Ship It Protocol                        ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!BRANCH=$(git branch --show-current)
!echo "Branch: $BRANCH"
!echo ""

# Check for uncommitted changes
!CHANGES=$(git status --porcelain | wc -l | tr -d ' ')
!if [ "$CHANGES" -gt 0 ]; then
  echo "⚠️  You have uncommitted changes:"
  git status --short
  echo ""
  echo "Commit your changes before shipping."
  exit 1
fi

# Detect project type and available commands
!HAS_PNPM=false
!HAS_NPM=false
!HAS_CARGO=false

![ -f "pnpm-lock.yaml" ] && HAS_PNPM=true
![ -f "package-lock.json" ] && HAS_NPM=true
![ -f "Cargo.toml" ] && HAS_CARGO=true

# Step 1: Tests
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!if [ "$SKIP_TESTS" = true ]; then
  echo "⏭️  Step 1: Tests (skipped)"
else
  echo "🧪 Step 1: Running tests..."

  if [ "$HAS_PNPM" = true ]; then
    if pnpm test 2>/dev/null; then
      echo "✅ Tests passed"
    else
      echo "❌ Tests failed"
      exit 1
    fi
  elif [ "$HAS_NPM" = true ]; then
    if npm test 2>/dev/null; then
      echo "✅ Tests passed"
    else
      echo "❌ Tests failed"
      exit 1
    fi
  elif [ "$HAS_CARGO" = true ]; then
    if cargo test 2>/dev/null; then
      echo "✅ Tests passed"
    else
      echo "❌ Tests failed"
      exit 1
    fi
  else
    echo "⏭️  No test runner detected"
  fi
fi
!echo ""

# Step 2: Lint
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!if [ "$SKIP_LINT" = true ]; then
  echo "⏭️  Step 2: Lint (skipped)"
else
  echo "🔍 Step 2: Running linter..."

  if [ "$HAS_PNPM" = true ]; then
    if pnpm run lint 2>/dev/null; then
      echo "✅ Lint passed"
    else
      echo "❌ Lint failed"
      exit 1
    fi
  elif [ "$HAS_NPM" = true ]; then
    if npm run lint 2>/dev/null; then
      echo "✅ Lint passed"
    else
      echo "❌ Lint failed"
      exit 1
    fi
  elif [ "$HAS_CARGO" = true ]; then
    if cargo clippy 2>/dev/null; then
      echo "✅ Lint passed"
    else
      echo "❌ Lint failed"
      exit 1
    fi
  else
    echo "⏭️  No linter detected"
  fi
fi
!echo ""

# Step 3: Build
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!if [ "$SKIP_BUILD" = true ]; then
  echo "⏭️  Step 3: Build (skipped)"
else
  echo "🔨 Step 3: Building..."

  if [ "$HAS_PNPM" = true ]; then
    if pnpm run build 2>/dev/null; then
      echo "✅ Build passed"
    else
      echo "❌ Build failed"
      exit 1
    fi
  elif [ "$HAS_NPM" = true ]; then
    if npm run build 2>/dev/null; then
      echo "✅ Build passed"
    else
      echo "❌ Build failed"
      exit 1
    fi
  elif [ "$HAS_CARGO" = true ]; then
    if cargo build --release 2>/dev/null; then
      echo "✅ Build passed"
    else
      echo "❌ Build failed"
      exit 1
    fi
  else
    echo "⏭️  No build command detected"
  fi
fi
!echo ""

# Step 4: Push and create PR
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "🚀 Step 4: Pushing and creating PR..."

# Push to origin
!echo "Pushing to origin..."
!git push -u origin "$BRANCH"

# Check if PR already exists
!EXISTING_PR=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null)

!if [ -n "$EXISTING_PR" ]; then
  echo "PR #$EXISTING_PR already exists for this branch"
  PR_URL=$(gh pr view "$EXISTING_PR" --json url --jq '.url')
else
  echo "Creating PR..."
  PR_URL=$(gh pr create --base main --fill 2>&1)

  if echo "$PR_URL" | grep -q "https://"; then
    echo "✅ PR created: $PR_URL"
  else
    echo "❌ Failed to create PR:"
    echo "$PR_URL"
    exit 1
  fi
fi
!echo ""

# Step 5: Watch CI
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "👀 Step 5: Watching CI..."
!echo ""
!echo "Waiting for CI checks to complete..."

!if gh pr checks --watch 2>/dev/null; then
  echo ""
  echo "✅ All CI checks passed!"
else
  echo ""
  echo "❌ CI checks failed"
  echo "Review the failures and push fixes."
  exit 1
fi

!echo ""
!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "🎉 Ship It complete!"
!echo ""
!echo "PR: $PR_URL"
!echo ""

# Update bead if associated
!if [ -f ".claude-bead" ]; then
  BEAD_ID=$(cat .claude-bead)
  echo "Updating bead $BEAD_ID to ready_to_merge..."
  bd update "$BEAD_ID" --status=ready_to_merge 2>/dev/null
  bd comment "$BEAD_ID" "PR ready - CI passed" 2>/dev/null
  bd sync 2>/dev/null
  echo "✅ Bead updated"
fi
