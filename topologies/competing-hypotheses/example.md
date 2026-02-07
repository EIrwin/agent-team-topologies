---
title: "Example: Investigating a Flaky Integration Test"
parent: Competing Hypotheses
grand_parent: Topologies
nav_order: 1
---

# Competing Hypotheses: Investigating a Flaky Integration Test

## Scenario

A Go service's integration test suite has a test (`TestOrderProcessing`) that fails roughly once every five CI runs. The failure is always a context deadline exceeded on a gRPC call to the inventory service. Local runs pass consistently. The team has spent two days adding log lines and re-running CI without finding the root cause.

## Why This Topology

Flaky tests are ambiguous by nature -- the symptom (timeout) could have many causes. A single investigator would anchor on their first theory and pursue it linearly. Competing Hypotheses forces three investigators to each champion a different theory and actively disprove each other, which is the fastest way to narrow down an intermittent issue.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Arbiter -- evaluate evidence, declare root cause |
| Investigator A | 1 | Hypothesis: race condition in test setup |
| Investigator B | 1 | Hypothesis: resource contention in CI environment |
| Investigator C | 1 | Hypothesis: non-deterministic data ordering |

## Spawn Prompt

```text
TestOrderProcessing fails ~20% of CI runs with context deadline exceeded on a gRPC call.
Passes locally every time. Spawn 3 investigators:
- Investigator A: race condition in test setup (goroutine timing, shared state).
- Investigator B: CI resource contention (CPU throttling, connection pool exhaustion).
- Investigator C: non-deterministic data ordering (map iteration, DB query order).
Have them exchange evidence and disprove each other's theories.
End with: (1) root cause, (2) reproducer, (3) fix plan, (4) verification steps.
```

## Trade-offs

- **Root causes are often combinations.** A race condition might only manifest under CI resource pressure -- neither theory alone is sufficient. Competing Hypotheses prevents anchoring on a single explanation and surfaces these compound causes.
- **Disproved hypotheses still have value.** An investigator whose theory is wrong for the primary symptom often uncovers latent bugs along the way. Capture these as follow-up issues rather than discarding them.
- **Redirect disproved investigators.** When a theory is clearly wrong, have that investigator pivot to supporting or attacking the remaining theories rather than going idle. They bring fresh eyes.
- **Tool limitations matter.** `go test -race` only catches data races, not synchronization races (e.g., a missing `WaitGroup`). Investigators should state what their evidence rules out and what it doesn't.
