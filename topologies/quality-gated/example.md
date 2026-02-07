---
title: "Example: Adding Quality Gates to a Feature Pod"
parent: Quality-Gated
grand_parent: Topologies
nav_order: 1
---

# Quality-Gated: Adding Quality Gates to a Feature Pod

## Scenario

A team is using a Feature Pod to build a payment processing module in Go -- backend API, React admin panel, and E2E tests. In a previous Feature Pod session, teammates marked tasks complete with failing tests and lint violations, which the lead discovered only during final integration. This time, the lead layers Quality-Gated on top to enforce standards automatically.

## Why This Topology

Quality-Gated is a composable overlay, not a standalone topology. The underlying Feature Pod handles task decomposition and parallel execution; Quality-Gated adds hooks that run `go test` and `golangci-lint` when any teammate marks a task complete. If checks fail, the hook blocks completion and sends the teammate specific feedback. This prevents the "works on my machine, tests are probably fine" pattern that caused rework last time.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Configure gates, run Feature Pod coordination |
| Backend | 1 | Go API for payment processing |
| Frontend | 1 | React admin panel |
| QA | 1 | E2E tests and integration verification |

## Spawn Prompt

```text
Create an agent team to build a payment processing module.
Spawn: Backend (Go API), Frontend (React admin), QA (E2E tests).
Quality gates: every task completion must pass `go test ./...` and `golangci-lint run`.
Use hooks to block task completion if gates fail -- send feedback with the failing output.
First define the contract, then parallelize by layer.
```

## How It Played Out

The lead configured two `TaskCompleted` hooks before spawning any teammates. The first ran `go test ./...` in the backend directory; the second ran `golangci-lint run`. Both were set to return exit code 2 on failure, which blocks task completion and sends the error output as feedback to the agent.

The Feature Pod started normally: contract definition, then parallel implementation by layer. The first gate trigger came when the backend teammate tried to mark the "create payment endpoint" task complete. The `golangci-lint` hook caught an `errcheck` violation -- the teammate had ignored the error return from `json.NewEncoder().Encode()`. The hook blocked completion and sent back: "golangci-lint: errcheck violation at handlers/payment.go:47 -- error return value not checked." The backend teammate fixed the issue in under a minute and re-completed the task, passing both gates.

The more interesting gate trigger came on the QA teammate's first task. Their E2E test called the payment endpoint but the test helper didn't close the HTTP response body. The `go test` hook passed (the test itself passed), but `golangci-lint` caught the `bodyclose` violation. The QA teammate added `defer resp.Body.Close()` and re-completed successfully.

The frontend teammate never triggered a gate failure because their React work didn't run through Go tooling. The lead noted this gap and added an `npm run lint` hook for the frontend directory mid-session. The frontend teammate's next task completion triggered the new hook, which caught a missing `key` prop in a list rendering -- a real bug that would have caused React reconciliation issues.

By the end of the session, the gates had fired 11 times across all teammates, blocking completion 4 times. Every blocked completion was fixed in under two minutes. Final integration was clean on the first attempt -- a sharp contrast to the previous session's 30 minutes of post-integration cleanup.

## What Went Wrong

The lead didn't initially configure a frontend lint hook, which meant the first two frontend tasks shipped without lint checks. The mid-session addition caught a real bug, but the earlier tasks had already been accepted. Lesson: configure gates for **all** layers before spawning teammates, not just the ones you think of first. An incomplete gate configuration gives a false sense of security.

## Results

| Metric | Value |
|--------|-------|
| Duration | 48 minutes |
| Token Cost | ~$5.40 |
| Deliverables | Payment module (API + admin panel + E2E tests), zero lint violations, all tests passing |

## Takeaway

- Gates should be configured **before** spawning teammates. Adding them mid-session means some tasks slip through ungated.
- The overhead per gate check was minimal (~5 seconds for `go test`, ~3 seconds for lint). The 4 blocked completions cost ~8 minutes of rework total -- far less than the 30 minutes of post-integration cleanup in the previous ungated session.
- Quality-Gated works best as a **composable overlay** on Feature Pod or Task Queue. It doesn't change how you decompose work -- it just adds a checkpoint at every completion boundary.
