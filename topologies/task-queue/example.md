---
title: "Example: Fixing 52 golangci-lint Violations"
parent: Task Queue
grand_parent: Topologies
nav_order: 1
---

# Task Queue: Fixing 52 golangci-lint Violations

## Scenario

After enabling `golangci-lint` with stricter rules (`errcheck`, `bodyclose`, `exhaustive`, `govet`), a Go API service reports 52 violations across 28 files. Each violation is independent -- fixing one doesn't affect another. The team wants them all resolved before merging the linter config change, but doing them one at a time would take forever.

## Why This Topology

The work is 52 small, independent items with no dependencies between them. This is the textbook Task Queue scenario: create a pool of self-contained tasks, let workers self-claim from the queue, and aggregate results when the queue is empty. Feature Pod or Orchestrator-Only would add unnecessary coordination overhead for work that doesn't need it.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Create task pool, monitor progress, aggregate results |
| Worker 1-5 | 5 | Self-claim violations, fix them, mark complete |

## Spawn Prompt

```text
Create an agent team to fix 52 golangci-lint violations.
Here's the lint output: [paste golangci-lint output].
Create one task per violation with the file path, line number, and rule.
Spawn 5 workers. Each should self-claim the next unblocked task, fix the violation,
run `golangci-lint run <file>` to verify, and immediately claim the next one.
I want a final summary of all fixes.
```

## How It Played Out

The lead parsed the lint output and created 52 tasks, each containing the file path, line number, rule name, and the lint message. Tasks were grouped by file but had no dependencies -- any worker could claim any task in any order.

Five workers started simultaneously, each claiming their first task from the queue. The initial pace was fast: most `errcheck` violations (31 of the 52) were straightforward additions of `if err != nil` checks. Workers averaged about 45 seconds per `errcheck` fix, including verification.

The `exhaustive` violations (8 tasks) were the most interesting category. These required adding missing cases to `switch` statements on enum types. Worker 3 hit a switch statement with 14 cases and realized the enum itself was defined in a generated proto file. Rather than adding 14 explicit cases, they added a `default` case with a descriptive comment -- a judgment call the lead confirmed was correct when Worker 3 asked.

The `bodyclose` violations (7 tasks) were all the same pattern: HTTP response bodies not being closed. Workers developed a rhythm for these -- add `defer resp.Body.Close()` after the error check, verify with lint. Worker 2 processed four of these in a row and finished them in under three minutes total.

The `govet` violations (6 tasks) were the trickiest. Two involved struct field alignment issues that required reordering fields, which risked changing JSON serialization order. Worker 5 flagged this to the lead, who decided to add `json` struct tags explicitly rather than reorder the fields -- a safer fix that resolved the lint violation without changing behavior.

By the 35-minute mark, 48 of 52 tasks were complete. The last four took longer because they were the edge cases: a `bodyclose` violation inside a retry loop, an `errcheck` on a deferred function call, and two `govet` issues requiring the struct tag approach. All 52 were done by minute 41.

## What Went Wrong

Workers 1 and 4 both claimed tasks in the same file (`handlers/orders.go`) at roughly the same time. Their fixes didn't conflict (different functions), but when Worker 4 ran the file-level lint check, it briefly showed Worker 1's not-yet-committed fix as a new violation. This caused a few minutes of confusion until Worker 4 realized the "new" violation was Worker 1's in-progress work. The fix: use function-level lint checks (`golangci-lint run --scope-path`) instead of file-level checks when multiple workers might touch the same file.

## Results

| Metric | Value |
|--------|-------|
| Duration | 41 minutes |
| Token Cost | ~$4.60 |
| Deliverables | 52 lint violations fixed across 28 files, zero regressions |

## Takeaway

- For bulk lint fixes, create **one task per violation**, not one task per file. Per-violation tasks let workers interleave across files and prevent any single complex file from becoming a bottleneck.
- When workers need to make judgment calls (like the `exhaustive` default case), they should ask the lead rather than guess. The 30 seconds spent confirming saves the rework from a wrong guess.
- Use function-scoped verification (`golangci-lint run --scope-path`) when multiple workers might edit the same file. File-level checks create false positives from in-progress work.
