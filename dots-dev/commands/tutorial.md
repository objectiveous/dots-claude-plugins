---
description: "Interactive tutorial for learning the dots-dev workflow"
allowed-tools: ["Bash"]
---

# Interactive Tutorial

Step-by-step tutorial teaching the dots-dev parallel development workflow.

**Usage:** `/dots-dev:tutorial [--reset] [--status]`

**Options:**
- `--reset` - Start the tutorial from the beginning
- `--status` - Show current progress without advancing

## Implementation

!source "*/scripts/worktree-lib.sh"

!REPO_ROOT=$(get_repo_root)
!STATE_FILE="$REPO_ROOT/.claude-tutorial-state"
!TUTORIAL_BRANCH="tutorial-playground"
!TUTORIAL_WORKTREE="$REPO_ROOT/.worktrees/$TUTORIAL_BRANCH"

# Help flag
!if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: /dots-dev:tutorial [OPTIONS]"
  echo ""
  echo "Interactive tutorial for the dots-dev parallel development workflow."
  echo ""
  echo "Options:"
  echo "  --reset     Start from the beginning"
  echo "  --status    Show progress without advancing"
  echo "  --help      Show this help"
  echo ""
  echo "The tutorial walks through:"
  echo "  1. Creating worktrees"
  echo "  2. Understanding worktree structure"
  echo "  3. Checking status"
  echo "  4. Session handoffs"
  echo "  5. Broadcasting"
  echo "  6. The ship command"
  echo "  7. Cleanup"
  echo ""
  echo "Progress is saved - you can stop and resume anytime."
  exit 0
fi

# Reset flag
!if [ "$1" = "--reset" ]; then
  rm -f "$STATE_FILE"
  # Clean up tutorial worktree if it exists
  if [ -d "$TUTORIAL_WORKTREE" ]; then
    git worktree remove "$TUTORIAL_WORKTREE" --force 2>/dev/null
    git branch -D "$TUTORIAL_BRANCH" 2>/dev/null
  fi
  echo "Tutorial reset. Run /dots-dev:tutorial to start fresh."
  exit 0
fi

# Read current step
!CURRENT_STEP=0
!if [ -f "$STATE_FILE" ]; then
  CURRENT_STEP=$(cat "$STATE_FILE")
fi

# Status flag
!if [ "$1" = "--status" ]; then
  echo "Tutorial Progress: Step $CURRENT_STEP of 8"
  echo ""
  case $CURRENT_STEP in
    0) echo "Next: Introduction" ;;
    1) echo "Next: Create a worktree" ;;
    2) echo "Next: Explore the worktree" ;;
    3) echo "Next: Check worktree status" ;;
    4) echo "Next: Session handoffs" ;;
    5) echo "Next: Broadcasting" ;;
    6) echo "Next: The ship command" ;;
    7) echo "Next: Cleanup" ;;
    8) echo "Tutorial complete!" ;;
  esac
  exit 0
fi

# Helper to save step
!save_step() {
  echo "$1" > "$STATE_FILE"
}

# Tutorial steps
!case $CURRENT_STEP in
  0)
    # Introduction
    echo "dots-dev Tutorial - Parallel Development with Claude Code"
    echo ""
    echo "Welcome! This tutorial will teach you the dots-dev workflow for"
    echo "parallel development with Claude Code."
    echo ""
    echo "THE PROBLEM"
    echo ""
    echo "Traditional Claude Code usage is sequential:"
    echo "  • One conversation"
    echo "  • One task"
    echo "  • One branch"
    echo ""
    echo "But real work is parallel. You're fixing a bug when a review"
    echo "comes in, or you need to spike on an idea without losing context."
    echo ""
    echo "THE SOLUTION"
    echo ""
    echo "dots-dev uses git worktrees to enable parallel Claude sessions:"
    echo ""
    echo "  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐"
    echo "  │  Worktree 1 │     │  Worktree 2 │     │  Worktree 3 │"
    echo "  │  feature/a  │     │  feature/b  │     │  bugfix/c   │"
    echo "  │   Claude    │     │   Claude    │     │   Claude    │"
    echo "  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘"
    echo "         │                   │                   │"
    echo "         └───────────────────┼───────────────────┘"
    echo "                             │"
    echo "                    ┌────────┴────────┐"
    echo "                    │   Shared Git    │"
    echo "                    │    History      │"
    echo "                    └─────────────────┘"
    echo ""
    echo "Each worktree has:"
    echo "  • Its own branch"
    echo "  • Its own working directory"
    echo "  • Its own Claude session (in iTerm tab)"
    echo "  • Optional bead context"
    echo ""
    echo ""
    echo "Run /dots-dev:tutorial again to continue to Step 1."
    echo ""
    save_step 1
    ;;

  1)
    # Create a worktree
    echo "Step1 of 8 -Creating a Worktree"
    echo ""
    echo "Let's create a practice worktree. We'll use a special branch"
    echo "called 'tutorial-playground' that we'll clean up at the end."
    echo ""
    echo "CREATING THE WORKTREE"
    echo ""

    # Actually create the worktree (but don't open iTerm)
    ensure_worktrees_dir

    if [ -d "$TUTORIAL_WORKTREE" ]; then
      echo "Tutorial worktree already exists."
    else
      echo "Creating: .worktrees/$TUTORIAL_BRANCH"
      git worktree add -b "$TUTORIAL_BRANCH" "$TUTORIAL_WORKTREE" HEAD 2>/dev/null
      echo ""
      echo "✅ Worktree created!"
    fi

    echo ""
    echo "In normal usage, you'd run:"
    echo ""
    echo "  /dots-dev:worktree-create feature/my-feature"
    echo ""
    echo "This would:"
    echo "  1. Create .worktrees/feature/my-feature"
    echo "  2. Create or checkout the branch"
    echo "  3. Open an iTerm tab with Claude"
    echo "  4. Register in the worktree registry"
    echo ""
    echo "For beads, you'd use:"
    echo ""
    echo "  /dots-dev:worktree-from-bead dots-abc"
    echo ""
    echo "This additionally:"
    echo "  • Creates .claude-bead file with the bead ID"
    echo "  • Claims the bead (marks in_progress)"
    echo "  • Servus agent auto-detects the context"
    echo ""
    echo ""
    echo "Run /dots-dev:tutorial to continue to Step 2."
    echo ""
    save_step 2
    ;;

  2)
    # Explore the worktree
    echo "Step2 of 8 -Exploring the Worktree                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Let's look at what was created."
    echo ""
    echo "WORKTREE LOCATION"
    echo ""
    echo "Path: $TUTORIAL_WORKTREE"
    echo ""
    if [ -d "$TUTORIAL_WORKTREE" ]; then
      echo "Contents:"
      ls -la "$TUTORIAL_WORKTREE" | head -10
      echo "..."
    fi
    echo ""
    echo "GIT WORKTREE LIST"
    echo ""
    git worktree list
    echo ""
    echo "KEY INSIGHT"
    echo ""
    echo "The worktree is a FULL working copy. It shares git history"
    echo "with the main repo but has its own:"
    echo ""
    echo "  • Working directory (files you edit)"
    echo "  • Branch (independent commits)"
    echo "  • Index (staging area)"
    echo ""
    echo "Changes in one worktree don't affect others until merged."
    echo ""
    echo ""
    echo "Run /dots-dev:tutorial to continue to Step 3."
    echo ""
    save_step 3
    ;;

  3)
    # Check status
    echo "Step3 of 8 -Checking Worktree Status                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "When you have multiple worktrees, you need visibility into"
    echo "their state. dots-dev provides two commands for this."
    echo ""
    echo "/dots-dev:worktree-list"
    echo ""
    echo "Simple list showing worktrees and registered sessions:"
    echo ""
    git worktree list
    echo ""
    echo "/dots-dev:worktree-status"
    echo ""
    echo "Dashboard with detailed info for each worktree:"
    echo ""
    echo "  • Uncommitted changes count"
    echo "  • Unpushed commits count"
    echo "  • Associated bead (from .claude-bead or branch name)"
    echo "  • Creation timestamp"
    echo ""
    echo "Example output:"
    echo ""
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📁 feature/auth"
    echo "     Path: /repo/.worktrees/feature/auth"
    echo "     📝 3 uncommitted changes (1 staged)"
    echo "     ⬆️  2 commits to push"
    echo "     🔮 Bead: dots-abc"
    echo "     🕐 Created: 2024-01-15T10:30:00Z"
    echo ""
    echo ""
    echo "Run /dots-dev:tutorial to continue to Step 4."
    echo ""
    save_step 4
    ;;

  4)
    # Session handoffs
    echo "Step4 of 8 -Session Handoffs   "
    echo ""
    echo "Context is expensive. When you close a session, valuable"
    echo "information about what you were doing is lost."
    echo ""
    echo "THE HANDOFF COMMAND"
    echo ""
    echo "Before closing a worktree session, run:"
    echo ""
    echo "  /dots-dev:worktree-handoff"
    echo ""
    echo "This creates .claude-handoff with:"
    echo ""
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │ # Session Handoff: feature/auth        │"
    echo "  │                                         │"
    echo "  │ ## Bead                                 │"
    echo "  │ dots-abc                                │"
    echo "  │                                         │"
    echo "  │ ## Last Commit                          │"
    echo "  │ a1b2c3d Add auth middleware             │"
    echo "  │                                         │"
    echo "  │ ## Uncommitted Changes                  │"
    echo "  │ M  src/auth/handler.ts                  │"
    echo "  │                                         │"
    echo "  │ ## Session Summary                      │"
    echo "  │ <!-- What was accomplished -->          │"
    echo "  │                                         │"
    echo "  │ ## Remaining Work                       │"
    echo "  │ <!-- What still needs doing -->         │"
    echo "  │                                         │"
    echo "  │ ## Blockers                             │"
    echo "  │ <!-- Issues preventing progress -->     │"
    echo "  │                                         │"
    echo "  │ ## Notes for Next Session               │"
    echo "  │ <!-- Tips, context, gotchas -->         │"
    echo "  └─────────────────────────────────────────┘"
    echo ""
    echo "AUTOMATIC DETECTION"
    echo ""
    echo "When a new Claude session starts in a worktree, the servus"
    echo "agent automatically checks for:"
    echo ""
    echo "  1. .claude-bead    → Know which bead we're working on"
    echo "  2. .claude-handoff → Previous session's context"
    echo "  3. .claude-broadcast → Messages from dominus"
    echo ""
    echo "This means the new session starts with full context!"
    echo ""
    echo ""
    echo "Run /dots-dev:tutorial to continue to Step 5."
    echo ""
    save_step 5
    ;;

  5)
    # Broadcasting
    echo "Step5 of 8 -Broadcasting       "
    echo ""
    echo "When you have multiple parallel sessions, you need a way to"
    echo "communicate with all of them at once."
    echo ""
    echo "THE BROADCAST COMMAND"
    echo ""
    echo "From the main repo (dominus), run:"
    echo ""
    echo "  /dots-dev:broadcast <message>"
    echo ""
    echo "Examples:"
    echo ""
    echo "  /dots-dev:broadcast Main updated - run /dots-dev:worktree-sync"
    echo "  /dots-dev:broadcast Stopping for lunch - please handoff"
    echo "  /dots-dev:broadcast Standup in 5 minutes"
    echo ""
    echo "HOW IT WORKS"
    echo ""
    echo "  1. Broadcast writes .claude-broadcast to each worktree"
    echo "  2. Servus agents check for this file on startup"
    echo "  3. Message is displayed with timestamp"
    echo "  4. File is deleted after reading"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────┐"
    echo "  │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │"
    echo "  │ 📢 BROADCAST [14:32:15]                                 │"
    echo "  │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │"
    echo "  │                                                         │"
    echo "  │ Main updated - run /dots-dev:worktree-sync              │"
    echo "  │                                                         │"
    echo "  │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │"
    echo "  └─────────────────────────────────────────────────────────┘"
    echo ""
    echo "USE CASES"
    echo ""
    echo "  • Notify about main branch updates"
    echo "  • Coordinate breaks and meetings"
    echo "  • Alert about blocking issues"
    echo "  • Signal end of work session"
    echo ""
    echo ""
    echo "Run /dots-dev:tutorial to continue to Step 6."
    echo ""
    save_step 6
    ;;

  6)
    # The ship command
    echo "Step6 of 8 -The Ship Command   "
    echo ""
    echo "Shipping code involves many steps. dots-dev automates them all."
    echo ""
    echo "THE MANUAL WAY"
    echo ""
    echo "  git status                    # Check for uncommitted"
    echo "  pnpm test                     # Run tests"
    echo "  pnpm run lint                 # Lint"
    echo "  pnpm run build                # Build"
    echo "  git push -u origin branch     # Push"
    echo "  gh pr create --fill           # Create PR"
    echo "  gh pr checks --watch          # Wait for CI"
    echo "  bd update <id> --status=ready_to_merge  # Update bead"
    echo ""
    echo "That's 8 commands with waiting between them."
    echo ""
    echo "THE SHIP WAY"
    echo ""
    echo "  /dots-dev:ship"
    echo ""
    echo "That's it. One command does everything:"
    echo ""
    echo "  ┌────────────────────────────────────────────────────────┐"
    echo "  │ 1. VERIFY     Check for uncommitted changes           │"
    echo "  │               (fails if any found)                    │"
    echo "  │                                                        │"
    echo "  │ 2. TEST       pnpm test / npm test / cargo test       │"
    echo "  │                                                        │"
    echo "  │ 3. LINT       pnpm run lint / cargo clippy            │"
    echo "  │                                                        │"
    echo "  │ 4. BUILD      pnpm run build / cargo build --release  │"
    echo "  │                                                        │"
    echo "  │ 5. PUSH       git push -u origin <branch>             │"
    echo "  │                                                        │"
    echo "  │ 6. PR         gh pr create (or find existing)         │"
    echo "  │                                                        │"
    echo "  │ 7. CI         gh pr checks --watch                    │"
    echo "  │                                                        │"
    echo "  │ 8. BEAD       Update to ready_to_merge                │"
    echo "  │               (if .claude-bead exists)                │"
    echo "  └────────────────────────────────────────────────────────┘"
    echo ""
    echo "OPTIONS"
    echo ""
    echo "  /dots-dev:ship --skip-tests    # Skip test step"
    echo "  /dots-dev:ship --skip-lint     # Skip lint step"
    echo "  /dots-dev:ship --skip-build    # Skip build step"
    echo ""
    echo "ON FAILURE"
    echo ""
    echo "If any step fails, the command stops and reports the error."
    echo "Fix the issue and run /dots-dev:ship again - it's idempotent."
    echo ""
    echo ""
    echo "Run /dots-dev:tutorial to continue to Step 7."
    echo ""
    save_step 7
    ;;

  7)
    # Cleanup
    echo "Step7 of 8 -Cleanup            "
    echo ""
    echo "After merging, clean up worktrees to keep things tidy."
    echo ""
    echo "MERGE AND CLEANUP"
    echo ""
    echo "After a worktree's work is complete and PR merged:"
    echo ""
    echo "  /dots-dev:worktree-merge feature/auth --cleanup"
    echo ""
    echo "This:"
    echo "  1. Merges the branch to main"
    echo "  2. Pushes main to origin"
    echo "  3. Closes the iTerm tab"
    echo "  4. Removes the worktree"
    echo "  5. Deletes the branch"
    echo "  6. Removes from registry"
    echo ""
    echo "HEALTH CHECK"
    echo ""
    echo "Periodically run:"
    echo ""
    echo "  /dots-dev:doctor"
    echo ""
    echo "This checks for:"
    echo "  • Stale worktree references"
    echo "  • Uncommitted changes in worktrees"
    echo "  • Unpushed commits"
    echo "  • Stale registry entries"
    echo "  • Merged branches not deleted"
    echo "  • Main branch out of sync"
    echo ""
    echo "CLEANING UP TUTORIAL"
    echo ""
    echo "Let's clean up the tutorial worktree we created..."
    echo ""

    if [ -d "$TUTORIAL_WORKTREE" ]; then
      git worktree remove "$TUTORIAL_WORKTREE" --force 2>/dev/null
      git branch -D "$TUTORIAL_BRANCH" 2>/dev/null
      echo "✅ Tutorial worktree cleaned up"
    else
      echo "Tutorial worktree already cleaned up."
    fi

    echo ""
    echo ""
    echo "Run /dots-dev:tutorial to complete the tutorial."
    echo ""
    save_step 8
    ;;

  8)
    # Completion
    echo "Tutorial Complete!"
    echo ""
    echo "You've learned the dots-dev parallel development workflow!"
    echo ""
    echo "QUICK REFERENCE"
    echo ""
    echo "  Create worktrees:"
    echo "    /dots-dev:worktree-create <branch>"
    echo "    /dots-dev:worktree-from-bead <bead-id>"
    echo ""
    echo "  Monitor:"
    echo "    /dots-dev:worktree-status"
    echo "    /dots-dev:doctor"
    echo ""
    echo "  Coordinate:"
    echo "    /dots-dev:broadcast <message>"
    echo "    /dots-dev:worktree-handoff"
    echo ""
    echo "  Ship:"
    echo "    /dots-dev:ship"
    echo "    /dots-dev:worktree-merge <name> --cleanup"
    echo ""
    echo "  Help:"
    echo "    /dots-dev:help"
    echo "    /dots-dev:<command> --help"
    echo ""
    echo "NEXT STEPS"
    echo ""
    echo "  1. Read the full guide: dots-dev/README.md"
    echo "  2. Try creating a real worktree for your next task"
    echo "  3. Use /dots-dev:worktree-from-bead for bead-driven work"
    echo "  4. Always handoff before closing sessions"
    echo ""
    echo ""
    echo "To restart the tutorial: /dots-dev:tutorial --reset"
    echo ""

    # Clean up state file
    rm -f "$STATE_FILE"
    ;;

  *)
    echo "Unknown step. Resetting tutorial..."
    save_step 0
    echo "Run /dots-dev:tutorial to start fresh."
    ;;
esac
