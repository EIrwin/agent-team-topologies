---
title: Review Board
parent: Topologies
has_children: true
nav_order: 2
---

# Review Board
> Parallel code review through distinct specialist lenses, synthesized into one verdict.

## At a Glance
| Field | Value |
|-------|-------|
| Best For | PR review, refactor review, pre-merge quality checks |
| Team Shape | Lead (editor-in-chief) + 3 Reviewers |
| Cost Profile | $$ -- moderate (small team, read-heavy) |
| Complexity | Low |
| Parallelism | High |

## When to Use
- A PR or changeset is large enough that one reviewer would miss things
- You want coverage across multiple dimensions (security, performance, correctness, tests)
- You need structured, evidence-based findings rather than a single "LGTM"
- Pre-merge review on high-risk or high-visibility changes

## When NOT to Use
- The change is small and a single reviewer can cover all dimensions
- You need implementation work done, not just review
- The code under review requires deep sequential understanding that cannot be split by lens

## How It Works
The lead assigns each reviewer a distinct lens (security, performance, test coverage, etc.). Reviewers work in parallel, each producing structured findings in a consistent format. The lead collects all reports and synthesizes a single review comment with prioritized action items.

```
         ┌──────┐
         │ Lead │      Editor-in-chief
         └──┬───┘
        ┌───┼───┐
        ▼   ▼   ▼
      ┌───┬───┬───┐
      │Sec│Prf│Tst│   Security / Performance / Tests
      └───┴───┴───┘   Each reviews with distinct lens
```

1. **Lead** identifies the changeset and assigns review lenses
2. **Reviewers** each analyze the code through their assigned lens
3. Each reviewer produces: Findings / Severity / Evidence / Suggested fix
4. **Lead** synthesizes into a single review with must-fix vs. nice-to-have

## Spawn Prompt
```text
Create an agent team to review PR #___.
Spawn three reviewers:
- Security implications
- Performance impact
- Test coverage & correctness
Have them each review and report findings with must-fix vs nice-to-have.
Then synthesize into one review comment.
```

## Task Breakdown Strategy
Split by **review dimension**, not by file region. Each reviewer gets the full changeset but examines it through their assigned lens:
- **Security reviewer:** injection risks, auth checks, data exposure, input validation
- **Performance reviewer:** algorithmic complexity, unnecessary allocations, N+1 queries, caching
- **Test reviewer:** coverage gaps, edge cases, assertion quality, test maintainability

Require each reviewer to produce structured output: findings with severity, evidence (file + line), and suggested fix.

## Configuration
- **Agents:** Use `reviewer.md` agent definitions scoped to a specific review lens
- **Hooks:** Use `TaskCompleted` hooks to ensure reviewers produce all required output sections before marking done
- **Team size:** 3 reviewers is standard; add a 4th for large or cross-cutting changes (e.g., API compatibility)

## Variations
- **Post-implementation variant:** Combine with Feature Pod -- the pod builds, then the review board inspects
- **Continuous review variant:** Reviewers stay active across multiple PRs in a session
- **Self-review variant:** The same team that implemented code spawns reviewers to check their own work before submitting

## Trade-offs
**Pros:**
- Catches blind spots that single-reviewer passes miss
- Structured output makes findings actionable and prioritized
- Parallel execution -- all reviewers work simultaneously
- Each lens gets a fresh context window, avoiding reviewer fatigue

**Cons:**
- Reviewers may flag the same issue from different angles (some duplication)
- Synthesis step requires judgment to reconcile conflicting recommendations
- Read-only -- produces review feedback, not fixes

## Related Patterns
- [Parallel Explorers](../parallel-explorers/) -- same fan-out structure, applied to discovery instead of review
- [Quality-Gated](../quality-gated/) -- layer on top to enforce review standards via hooks
- [Risky Refactor](../risky-refactor/) -- when review findings lead to a controlled refactor plan
