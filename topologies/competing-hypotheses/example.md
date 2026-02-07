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

## How It Played Out

All three investigators began by reading the failing test and the gRPC client code. Within the first few minutes, each had staked out their position.

Investigator A found that `TestOrderProcessing` launched a background goroutine to seed test data but didn't wait for it to complete before making the gRPC call. They argued this was a textbook race: if the seeder goroutine was slow, the gRPC call would hit unseeded data and the inventory service would block waiting for a database row that didn't exist yet, eventually timing out.

Investigator B countered that the seeder goroutine took <10ms locally, so timing alone couldn't explain the failure. They pointed to CI resource limits -- the GitHub Actions runner was a 2-core machine running the test suite alongside three other services in Docker. Under CPU contention, the seeder goroutine could be starved long enough to cause the timeout. Investigator B ran `go test -race` on the failing test and found no reported races, which they argued weakened A's pure-race-condition theory.

Investigator C traced the inventory service's handler and found it used `ORDER BY` in its query but the test assertions didn't account for insertion order. However, they couldn't connect this to the timeout behavior -- wrong ordering would cause an assertion failure, not a deadline exceeded. Investigator C conceded their hypothesis was a real bug but not the root cause of the flakiness, and pivoted to supporting Investigator A's theory with additional evidence.

The pivotal moment came when Investigator A found a `sync.WaitGroup` in a nearby test helper that was used correctly in other tests but was missing from `TestOrderProcessing`. The seeder goroutine had been added in a later commit without the corresponding `wg.Add(1)` / `wg.Wait()`. Combined with Investigator B's point about CI resource contention, the picture was clear: the race existed in the code (A's theory), but only manifested under CPU pressure (B's theory). Locally, the seeder always won the race because there was no contention.

The lead declared consensus: root cause was a missing `WaitGroup` synchronization combined with CI resource constraints. Fix: add `wg.Wait()` before the gRPC call. Verification: run the test 50 times with `GOMAXPROCS=1` to simulate contention.

## What Went Wrong

Investigator C's data-ordering hypothesis was a dead end for the flakiness question but uncovered a real latent bug in the test assertions. This is common in Competing Hypotheses -- not every theory hits the target, but disproved hypotheses often surface secondary findings. The lead should capture these as follow-up issues rather than discarding them.

## Results

| Metric | Value |
|--------|-------|
| Duration | 31 minutes |
| Token Cost | ~$3.40 |
| Deliverables | Root cause, reproducer (`GOMAXPROCS=1`), one-line fix, verification plan, bonus latent bug |

## Takeaway

- The root cause was a **combination** of two hypotheses -- neither the race nor the contention alone was sufficient. This is exactly why Competing Hypotheses works: it prevents anchoring on a single explanation.
- When an investigator's theory is disproved for the primary symptom, have them pivot to supporting or attacking the remaining theories rather than going idle.
- Running `go test -race` not detecting an issue doesn't rule out race conditions -- it only catches data races, not synchronization races like a missing `WaitGroup`.
