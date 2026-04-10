# Example: PR Review Workflow

This example shows how orchestrator mode handles reviewing and fixing multiple PRs in a repository.

## Scenario

You have 4 open PRs in `/home/user/webrtc-rs/rtc` with review comments that need addressing.

## Session

### Step 1: Enter Orchestrator Mode

```
/orchestrate
```

### Step 2: Describe the Task

```
I have 4 open PRs in /home/user/webrtc-rs/rtc that have review comments.
Please address all review comments on each PR.
```

### Step 3: Orchestrator Gathers State

The orchestrator runs administrative commands in the main context:

```bash
gh pr list --repo webrtc-rs/rtc --state open --json number,title,headRefName
gh pr view 42 --comments
gh pr view 43 --comments
gh pr view 44 --comments
gh pr view 45 --comments
```

### Step 4: Orchestrator Creates Progress Table

```
## PR Review Progress

| # | PR   | Branch              | Status  | Review Comments |
|---|------|---------------------|---------|-----------------|
| 1 | #42  | fix/ice-gathering   | pending | 3 comments      |
| 2 | #43  | feat/turn-relay     | pending | 1 comment       |
| 3 | #44  | fix/mdns-routing    | pending | 5 comments      |
| 4 | #45  | refactor/srtp       | pending | 2 comments      |
```

### Step 5: Process PR #42

The orchestrator dispatches an agent with a fully self-contained prompt:

```
Task: Address 3 review comments on PR #42

Repository: /home/user/webrtc-rs/rtc
Branch: fix/ice-gathering

Review comments to address:

1. src/ice/gatherer.rs line 127: reviewer says "use `if let` instead of match
   with single arm". Change the match statement to an if-let.

2. src/ice/gatherer.rs line 203: reviewer says "missing error context".
   Add `.context("failed to gather ICE candidates")` to the error chain.
   The `anyhow` crate is already in Cargo.toml.

3. src/ice/gatherer_test.rs line 45: reviewer says "add timeout to this test".
   Wrap the test body in `tokio::time::timeout(Duration::from_secs(10), async { ... })`.

Steps:
1. git checkout fix/ice-gathering
2. Edit src/ice/gatherer.rs — apply fixes 1 and 2
3. Edit src/ice/gatherer_test.rs — apply fix 3
4. Run: cargo fmt && cargo check && cargo clippy && cargo test
5. git add -A && git commit -m "address review comments"
6. git push
7. git checkout master

Context:
- This is a Rust project using tokio for async, anyhow for errors
- The test file uses #[tokio::test]
```

### Step 6: Verify and Update

After the agent completes, the orchestrator:

1. Checks the result: "Agent completed: addressed 3 review comments, all tests pass"
2. Verifies independently:
   ```bash
   git -C /home/user/webrtc-rs/rtc log --oneline -1 fix/ice-gathering
   gh pr view 42 --json commits --jq '.commits[-1].oid'
   ```
3. Replies to the review comments on GitHub:
   ```bash
   gh pr review 42 --comment -b "Addressed all 3 comments: used if-let, added error context, added test timeout."
   ```
4. Updates the progress table:
   ```
   | 1 | #42  | fix/ice-gathering   | done    | 3/3 addressed   |
   ```

### Step 7: Continue to Next PR

Repeats steps 5-6 for PRs #43, #44, #45, processing them sequentially (never in parallel on the same repo).

### Step 8: Final Summary

```
## Summary

All 4 PRs processed. 11 review comments addressed total.

| # | PR   | Branch              | Status | Comments |
|---|------|---------------------|--------|----------|
| 1 | #42  | fix/ice-gathering   | done   | 3/3      |
| 2 | #43  | feat/turn-relay     | done   | 1/1      |
| 3 | #44  | fix/mdns-routing    | done   | 5/5      |
| 4 | #45  | refactor/srtp       | done   | 2/2      |

Repo left on master branch, working tree clean.
```

## Key Takeaways

- Each agent got a complete, standalone prompt with exact file paths and line numbers
- PRs were processed one at a time to avoid git conflicts
- The orchestrator verified each agent's work independently
- Progress was tracked and communicated throughout
- The repo was left in a clean state
