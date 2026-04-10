# Orchestrator Mode for Claude Code

A reusable Claude Code skill that puts Claude into an orchestrator mode where the main conversation stays clean and administrative while background agents handle detailed work.

Developed from a real session managing 27 PRs across 2 repositories.

## What It Does

Orchestrator mode separates **planning and coordination** from **execution**:

- **Main context**: dispatches agents, tracks progress, reviews results, talks to you
- **Background agents**: read files, edit code, run tests, push commits

This keeps the main context window clean and focused, even during complex multi-hour sessions.

## Why Use It

- **Context window management** — detailed code work burns context fast; keeping it in agents preserves the main conversation
- **Progress tracking** — built-in task lists and status tables so you always know where things stand
- **Parallel safety** — enforces one-agent-per-repo to prevent git conflicts and race conditions
- **Verification** — agents' claims are independently verified, not blindly trusted
- **Reproducibility** — self-contained agent prompts mean work can be retried without context loss

## Installation

### Option 1: Install Script

```bash
cd ~/dev/orchestrator-mode
chmod +x install.sh
./install.sh
```

### Option 2: Manual

```bash
mkdir -p ~/.claude/skills
cp skill.md ~/.claude/skills/orchestrator-mode.md
```

## Usage

In any Claude Code conversation, invoke the skill:

```
/orchestrate
```

Then describe your task. Claude will switch to orchestrator mode and begin dispatching agents.

## Example Workflows

### PR Review and Fix

```
/orchestrate
I have 5 open PRs in /home/user/my-project that need review comments addressed. Process them one at a time.
```

### Large Refactor

```
/orchestrate
Refactor the auth module in /home/user/app to use the new token format. The changes span src/auth/, src/middleware/, and tests/.
```

### Multi-Repo Coordination

```
/orchestrate
Update the shared library in /home/user/lib (bump version, add new API), then update /home/user/app to use the new version.
```

## Key Rules

1. Main context never reads/edits code directly
2. One agent at a time per repo
3. Agent prompts are fully self-contained (no "based on earlier work")
4. Progress tracked with task lists updated after each agent
5. Agent results are independently verified
6. Repos are always left in a clean state

## Project Structure

```
orchestrator-mode/
├── README.md              # This file
├── skill.md               # The skill definition (core)
├── install.sh             # Installation script
└── examples/
    └── pr-review.md       # Example: PR review workflow
```
