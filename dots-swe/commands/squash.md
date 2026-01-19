---
description: "Squash commits in feature branch via interactive rebase"
allowed-tools: ["Bash"]
execution-mode: atomic-bash
---

<claude-instructions>
1. The bash script below will execute AUTOMATICALLY by the skill framework
2. DO NOT manually run individual bash commands from this skill
3. Wait for the skill execution output and report the result to the user
</claude-instructions>

# Squash Commits

Guides you through squashing commits in your feature branch before merging to main.

This makes the commit history cleaner by combining multiple work-in-progress commits into logical, well-described commits that follow Conventional Commits format.

**Usage:** `/dots-swe:squash`

**What it does:**
1. Checks you're on a feature branch (not main)
2. Shows commits ahead of main
3. Provides guidance for interactive rebase
4. Launches `git rebase -i main`

**Interactive Rebase Guide:**
- **pick**: Keep this commit as-is
- **squash** (or **s**): Combine with previous commit, keep both messages
- **fixup** (or **f**): Combine with previous commit, discard this message
- **reword** (or **r**): Keep commit but edit the message

**Typical workflow:**
1. Keep first commit as `pick`
2. Change work-in-progress commits to `squash` or `fixup`
3. Save and close the editor
4. Write a single Conventional Commit message for the combined work

**Example:**
```
pick abc123 feat(auth): add OAuth integration
fixup def456 wip: fix typo
fixup ghi789 wip: add tests
```
Results in one commit: `feat(auth): add OAuth integration`

## Implementation

!source "$(ls -td $HOME/.claude/plugins/cache/dots-claude-plugins/dots-swe/*/scripts/swe-lib.sh 2>/dev/null | head -1)"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-swe:squash"
  echo ""
  echo "Squash commits in feature branch via interactive rebase."
  echo ""
  echo "This command helps clean up your commit history before merging to main."
  echo ""
  echo "What it does:"
  echo "  1. Checks you're on a feature branch (not main)"
  echo "  2. Shows commits ahead of main"
  echo "  3. Provides guidance for interactive rebase"
  echo "  4. Launches git rebase -i main"
  echo ""
  echo "After squashing, your branch will have fewer, better-organized commits"
  echo "that follow Conventional Commits format."
  exit 0
fi

!echo "=================================================================="
!echo "                    Squash Feature Commits                        "
!echo "=================================================================="
!echo ""

# Get current branch
!BRANCH=$(git branch --show-current)
!echo "Current branch: $BRANCH"
!echo ""

# Check if on main branch
!if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "ERROR: Cannot squash commits on main/master branch."
  echo ""
  echo "Please checkout a feature branch first."
  echo ""
  echo "Example:"
  echo "  git checkout -b feature/my-work"
  exit 1
fi

# Detect main branch name
!MAIN_BRANCH="main"
!if git show-ref --verify --quiet refs/heads/master; then
  MAIN_BRANCH="master"
fi

# Check for uncommitted changes
!CHANGES=$(git status --porcelain | grep -v '^\?\? \.swe-' | wc -l | tr -d ' ')
!if [ "$CHANGES" -gt 0 ]; then
  echo "WARNING: You have uncommitted changes:"
  git status --short | grep -v '^\?\? \.swe-'
  echo ""
  echo "Please commit or stash your changes before squashing."
  exit 1
fi

# Count commits ahead of main
!COMMIT_COUNT=$(git rev-list --count "$MAIN_BRANCH".."$BRANCH")
!echo "Commits ahead of $MAIN_BRANCH: $COMMIT_COUNT"
!echo ""

# Exit if no commits to squash
!if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "No commits to squash."
  echo ""
  echo "Your branch is up to date with $MAIN_BRANCH."
  exit 0
fi

# Exit if only one commit
!if [ "$COMMIT_COUNT" -eq 1 ]; then
  echo "Only one commit ahead of $MAIN_BRANCH."
  echo ""
  echo "Nothing to squash. Consider using git commit --amend if you want to"
  echo "modify the commit message to follow Conventional Commits format."
  exit 0
fi

# Show commit list
!echo "Commits to squash:"
!echo "------------------------------------------------------------------"
!git log --oneline "$MAIN_BRANCH".."$BRANCH"
!echo ""

# Provide guidance
!echo "=================================================================="
!echo "                    Interactive Rebase Guide                      "
!echo "=================================================================="
!echo ""
!echo "In the editor that opens:"
!echo ""
!echo "1. Keep the FIRST commit as 'pick'"
!echo "2. Change other commits to:"
!echo "   - 'squash' (s) - combine with previous, keep message"
!echo "   - 'fixup' (f)  - combine with previous, discard message"
!echo ""
!echo "3. Save and close the editor"
!echo "4. Write a final Conventional Commit message:"
!echo "   - Format: type(scope): description"
!echo "   - Examples: feat(auth): add OAuth, fix(api): handle timeout"
!echo ""
!echo "Commands:"
!echo "  pick   = keep commit as-is"
!echo "  squash = combine with previous, keep both messages"
!echo "  fixup  = combine with previous, discard this message"
!echo "  reword = keep commit but edit message"
!echo ""
!echo "=================================================================="
!echo ""
!read -p "Press Enter to start interactive rebase (or Ctrl+C to cancel)..."
!echo ""

# Launch interactive rebase
!echo "Starting interactive rebase..."
!echo ""
!git rebase -i "$MAIN_BRANCH"

# Check result
!if [ $? -eq 0 ]; then
  echo ""
  echo "=================================================================="
  echo "Squash complete!"
  echo ""
  echo "Your commits have been combined. Review the result:"
  echo ""
  git log --oneline "$MAIN_BRANCH".."$BRANCH"
  echo ""
  echo "If you've already pushed this branch, you'll need to force push:"
  echo "  git push --force-with-lease"
  echo ""
  echo "Otherwise, push normally:"
  echo "  git push"
  echo ""
else
  echo ""
  echo "Rebase failed or was aborted."
  echo ""
  echo "To continue the rebase after fixing conflicts:"
  echo "  git rebase --continue"
  echo ""
  echo "To abort the rebase:"
  echo "  git rebase --abort"
  echo ""
  exit 1
fi
