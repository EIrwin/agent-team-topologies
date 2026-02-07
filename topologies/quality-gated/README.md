# Quality-Gated
> Hooks as guardrails -- enforce completion standards before work is accepted.

## At a Glance
| Field | Value |
|-------|-------|
| Best For | Enforcing "Definition of Done", preventing premature completion, automated quality checks |
| Team Shape | Any topology + gate hooks |
| Cost Profile | +$ -- marginal cost on top of the base topology |
| Complexity | Low-Medium |
| Parallelism | Varies (inherits from base topology) |

## When to Use
- You want to enforce that tests pass, lint is clean, or docs are updated before a task is marked done
- Teammates tend to mark work complete prematurely
- You need automated checks at task completion or teammate idle boundaries
- You want a composable quality layer that works with any other topology

## When NOT to Use
- The base topology already has sufficient quality controls built in
- The overhead of running gate checks on every task completion is not worth it (very fast, low-stakes tasks)
- You do not have hooks configured in your project

## How It Works
Quality-Gated is a **composable topology** -- it layers on top of any other pattern. It uses Claude Code hooks (`TaskCompleted` and `TeammateIdle`) to intercept completion events and enforce quality criteria. If criteria are not met, the hook returns exit code 2, which blocks completion and sends feedback to the agent to fix the issues.

```
      ┌────────┐     ┌──────┐     ┌───┐
      │ Worker │────►│ Gate │────►│ ✓ │
      └────────┘     └──┬───┘     └───┘
                        │ fail
                        ▼
                   ┌──────────┐
                   │ feedback │   Composable: layer on
                   └──────────┘   any other topology
```

1. **Worker** completes their task and marks it done (or goes idle)
2. **Gate hook** runs automated checks (tests, lint, format, coverage, etc.)
3. If checks **pass**: task completion proceeds normally
4. If checks **fail**: hook returns exit code 2, blocks completion, and sends feedback describing what needs fixing
5. **Worker** receives feedback and continues working until the gate passes

## Spawn Prompt
```text
Create an agent team to deliver <goal>.
We have quality gates: tests must pass, lint clean, and a short changelog entry.
Use hooks to prevent task completion until gates pass; if not, send feedback and keep working.
```

## Task Breakdown Strategy
Quality-Gated does not change how you break down tasks -- it adds a **gate at the boundary** of each task:
- Define your "Definition of Done" as concrete, automatable checks
- Encode each check as a hook script that returns exit code 0 (pass) or 2 (fail + feedback)
- Apply gates at the granularity that matches your needs (per-task, per-teammate, or both)

Common gate checks:
- Test suite passes
- Linter reports zero errors
- Type checker passes
- Documentation is updated
- Changelog entry exists

## Configuration
- **Agents:** No special agent definitions needed -- this layers on top of existing agents
- **Hooks:**
  - `TaskCompleted` -- runs when a teammate marks a task as completed; exit code 2 blocks and sends feedback
  - `TeammateIdle` -- runs when a teammate goes idle; use to trigger "run tests / summarize / open PR" before shutdown
- **Team size:** Any -- this is a composable overlay

## Variations
- **Strict variant:** Every task must pass all gates -- no exceptions
- **Tiered variant:** Different gate strictness for different task types (critical tasks get full gates, minor tasks get lighter checks)
- **Progressive variant:** Gates get stricter as work progresses (early tasks only require lint, final tasks require full test suite + coverage thresholds)
- **Review Board + Quality-Gated:** Reviewers must produce all required output sections, enforced by hooks

## Trade-offs
**Pros:**
- Prevents premature completion and "looks done" failures
- Automated enforcement removes reliance on manual review
- Composable with any topology -- low integration cost
- Feedback loop keeps workers productive instead of context-switching

**Cons:**
- Gate checks add latency to every task completion
- Poorly written gate scripts can block workers on false positives
- Requires upfront investment in hook scripts
- Cannot catch subjective quality issues (only automatable checks)

## Related Patterns
- [Review Board](../review-board/) -- for subjective quality review that hooks cannot automate
- [Feature Pod](../feature-pod/) -- a natural pairing: per-layer gates ensure each layer meets standards
- [Risky Refactor](../risky-refactor/) -- gates complement the plan approval workflow
- All other topologies -- Quality-Gated composes with any of them
