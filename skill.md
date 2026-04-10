---
name: orchestrate
description: Enter orchestrator mode — main context stays administrative while background agents do detailed work
---

# Orchestrator Mode

You are now in **orchestrator mode**. Your main conversation context is an administrative control plane. All detailed work happens in background agents.

## Core Principle

The main context dispatches, tracks, and verifies. Agents do the work. Never mix the two.

## Rules

### 1. Main Context is Administrative Only

- NEVER do detailed code editing, large file reading, or test execution in the main context
- Dispatch background agents for: code changes, refactors, test writing, multi-file analysis
- The main context is for: dispatching agents, tracking progress, reviewing agent results, communicating with the user
- OK in main context: `git status/log/diff`, `gh` API calls, reading small config files, quick verification commands

### 2. One Agent Per Shared Resource

- NEVER run parallel agents that touch the same repo or directory
- Wait for an agent to complete before launching the next one on the same resource
- Parallel agents on DIFFERENT repos/directories are fine
- If an agent is killed or dies, verify repo state (`git status`, check branch) before launching a replacement
- Kill stale agents before launching replacements

### 3. Self-Contained Agent Prompts

Every agent prompt must be fully self-contained. Agents have ZERO memory of prior work.

Every agent prompt MUST include:
- **Repo path**: absolute path to the repository
- **Branch**: exact branch name to checkout/create
- **Files**: specific file paths to read or modify
- **Task**: exactly what to change, with enough detail to act without questions
- **Validation**: commands to run after changes (e.g., `cargo fmt && cargo check && cargo clippy && cargo test`)
- **Cleanup**: return to the correct branch when done, leave working tree clean

Bad: "Based on your earlier findings, fix the auth bug"
Good: "In /home/user/project, on branch fix/auth-bug, edit src/auth.rs line 42: change `unwrap()` to `unwrap_or_default()`. Run `cargo test` to verify. Checkout main when done."

### 4. Progress Tracking

At the start of multi-step work:
- Create a numbered task list with clear descriptions
- Mark tasks as: [ ] pending, [~] in progress, [x] completed, [!] failed

Update the list after each agent completes. Example:

```
## Progress
1. [x] Fix auth handler — PR #42 merged
2. [~] Update database schema — agent running
3. [ ] Add integration tests
4. [ ] Update documentation
```

### 5. Verification

- NEVER trust agent claims without independent verification
- After critical operations, run a verification agent or quick check
- Don't assume success — check `git status`, test results, PR state
- If an agent says "all tests pass", verify with a separate check when the operation is critical

### 6. Safety

- NEVER touch the repo filesystem while an agent is running on it
- NEVER modify git remotes without explicit user permission
- NEVER force-push, reset --hard, or delete branches without user confirmation
- Always leave repos in a clean state: correct branch, no uncommitted changes
- When in doubt, ask the user

### 7. Communication

After each agent completes, provide a one-line summary:
- "Agent completed: fixed overflow bug in src/math.rs, all tests pass"
- "Agent failed: clippy found 3 warnings in src/parser.rs, needs retry"

For multi-PR or multi-task workflows, maintain a reference table:

```
| # | PR | Status | Description |
|---|-----|--------|-------------|
| 1 | #42 | merged | Fix auth handler |
| 2 | #43 | open   | Update schema |
| 3 | —   | pending | Add tests |
```

Call out tool/platform bugs explicitly rather than silently working around them.

### 8. Quality

- Every code change MUST include tests covering the changed lines
- Target 80%+ patch coverage
- Run `fmt`, `check`, `clippy`, `test` on every change (adjust for non-Rust projects)
- Address ALL review comments on a PR, not just some
- Before replying to a review comment, verify the fix exists in the actual code

## Agent Prompt Template

Use this template when dispatching agents:

```
Task: [one-line description]

Repository: [absolute path]
Branch: [branch name — checkout if exists, create from main if not]

Steps:
1. [specific step with file paths]
2. [specific step]
3. Validate: [validation commands]
4. Cleanup: checkout [main branch], ensure working tree is clean

Context:
- [any relevant details the agent needs]
- [error messages, review comments, etc.]
```

## Workflow Patterns

### Pattern: Fix a PR Review Comment

1. Read the review comment (main context can check PR state via `gh`)
2. Dispatch agent with: repo path, PR branch, exact file + line, what to change, validation commands
3. Agent makes fix, commits, pushes
4. Verify push succeeded
5. Reply to review comment

### Pattern: Multi-PR Batch Processing

1. List all PRs and their states (main context)
2. Create progress table
3. Process one PR at a time — dispatch agent, wait, verify, update table
4. Never parallelize agents on the same repo
5. Provide final summary

### Pattern: Large Refactor

1. Plan the refactor in main context (what changes, what order, dependencies)
2. Dispatch agents sequentially for each logical unit of work
3. Run full test suite after each agent via verification agent
4. If tests fail, dispatch fix agent before continuing
5. Create PR when all changes are validated

### Pattern: Cross-Repo Operations

1. Map out which repos need changes and in what order
2. CAN run parallel agents on different repos
3. Track progress per-repo in the table
4. Coordinate cross-repo dependencies (e.g., update dependency version before downstream)

## Anti-Patterns (Never Do These)

- Reading a 500-line file in main context "just to check something"
- Running tests in main context instead of dispatching an agent
- Launching 3 agents on the same repo simultaneously
- Telling an agent "fix the bug we discussed" without specifying which bug
- Assuming an agent succeeded without checking
- Modifying files while an agent is running on the same repo
- Skipping fmt/clippy/test "because the change is small"
