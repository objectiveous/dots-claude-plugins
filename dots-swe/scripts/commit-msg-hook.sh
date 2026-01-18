#!/bin/bash
# Conventional Commits validator
# This hook validates that commit messages follow the Conventional Commits format

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Pattern for Conventional Commits: type(scope): description
# Types: feat, fix, docs, chore, refactor, test
# Scope is optional
# Description should be lowercase and not end with a period

PATTERN="^(feat|fix|docs|chore|refactor|test)(\(.+\))?: .+"

# Extract just the first line (subject) for validation
SUBJECT=$(echo "$COMMIT_MSG" | head -n 1)

if ! echo "$SUBJECT" | grep -qE "$PATTERN"; then
  echo "❌ Commit message does not follow Conventional Commits format"
  echo ""
  echo "Expected format: type(scope): description"
  echo ""
  echo "Valid types:"
  echo "  - feat:     new features"
  echo "  - fix:      bug fixes"
  echo "  - docs:     documentation changes"
  echo "  - chore:    maintenance (version bumps, deps, config)"
  echo "  - refactor: code changes that don't add features or fix bugs"
  echo "  - test:     adding or updating tests"
  echo ""
  echo "Scope is optional but recommended (e.g., 'feat(auth): add login')"
  echo ""
  echo "Description should:"
  echo "  - Start with lowercase letter"
  echo "  - Use imperative mood ('add' not 'added' or 'adds')"
  echo "  - Not end with a period"
  echo "  - Be concise (50 chars or less)"
  echo ""
  echo "Examples:"
  echo "  ✅ feat(api): add user authentication endpoint"
  echo "  ✅ fix: resolve null pointer in config parser"
  echo "  ✅ chore: bump version to 1.2.0"
  echo ""
  echo "Your commit message:"
  echo "  ❌ $SUBJECT"
  exit 1
fi

# Check if description starts with lowercase
DESC=$(echo "$SUBJECT" | sed -E 's/^[^:]+: //')
FIRST_CHAR=$(echo "$DESC" | cut -c1)

if ! echo "$FIRST_CHAR" | grep -qE "^[a-z0-9]"; then
  echo "⚠️  Warning: Description should start with lowercase letter"
  echo "   Current: $DESC"
  echo ""
  echo "Continuing anyway, but consider fixing for consistency..."
fi

# Check if description ends with period
if echo "$DESC" | grep -qE "\.$"; then
  echo "⚠️  Warning: Description should not end with a period"
  echo "   Current: $DESC"
  echo ""
  echo "Continuing anyway, but consider fixing for consistency..."
fi

exit 0
