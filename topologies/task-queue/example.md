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

## Trade-offs

- **Create one task per violation, not one task per file.** Per-violation tasks let workers interleave across files and prevent any single complex file from becoming a bottleneck.
- **Workers will need judgment calls.** Not every lint fix is mechanical -- some require design decisions (e.g., adding a `default` case vs. enumerating all cases in a switch). Workers should ask the lead rather than guess. The 30 seconds spent confirming saves the rework from a wrong guess.
- **Same-file collisions happen.** When multiple workers edit the same file, their verification checks can show false positives from each other's in-progress work. Use function-scoped verification when possible.
- **Edge cases cluster at the end.** The easy fixes go fast, but the last 10% of tasks take disproportionately longer. Don't extrapolate completion time from the initial pace.
