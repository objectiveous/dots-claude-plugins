---
description: "Run quality gates: test, lint, build (no PR)"
allowed-tools: ["Bash"]
---

# Quality Check

Runs quality gates (test, lint, build) without creating a PR. Use this to verify your code before committing or shipping.

**Usage:** `/dots-swe:check [--skip-tests] [--skip-lint] [--skip-build]`

**Options:**
- `--skip-tests` - Skip running tests
- `--skip-lint` - Skip linting
- `--skip-build` - Skip build step

## Implementation

!source "*/scripts/swe-lib.sh"

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
  echo "Use /dots-swe:ship to run the full protocol with PR creation."
  exit 0
fi

!SKIP_TESTS=$(has_flag "--skip-tests" "$@" && echo true || echo false)
!SKIP_LINT=$(has_flag "--skip-lint" "$@" && echo true || echo false)
!SKIP_BUILD=$(has_flag "--skip-build" "$@" && echo true || echo false)

!echo "╔══════════════════════════════════════════════════════════════╗"
!echo "║                     Quality Check                            ║"
!echo "╚══════════════════════════════════════════════════════════════╝"
!echo ""

!BRANCH=$(git branch --show-current)
!echo "Branch: $BRANCH"
!echo ""

# Detect project type
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

!echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
!echo "✅ Quality check complete!"
!echo ""
!echo "All gates passed. Ready to commit or ship."
!echo ""
!echo "Next steps:"
!echo "  - Commit your changes"
!echo "  - Run /dots-swe:ship to create PR and watch CI"
