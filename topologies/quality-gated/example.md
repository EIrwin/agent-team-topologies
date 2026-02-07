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

## Trade-offs

- **Configure gates for all layers before spawning teammates.** Adding gates mid-session means early tasks slip through ungated, giving a false sense of security. Think through every layer's toolchain upfront (Go lint, npm lint, test suites).
- **Gate overhead is minimal.** Lint and test checks typically add only seconds per completion. The rework they prevent (catching violations immediately vs. during integration) is far more expensive than the check itself.
- **Quality-Gated works best as a composable overlay.** Layer it on Feature Pod or Task Queue -- it doesn't change how you decompose work, just adds a checkpoint at every completion boundary.
- **Gates catch process failures, not design failures.** A passing test suite and clean lint don't guarantee the implementation is correct. Gates enforce a minimum bar, not a maximum quality standard.
