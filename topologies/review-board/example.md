---
title: "Example: Reviewing an Auth Middleware PR"
parent: Review Board
grand_parent: Topologies
nav_order: 1
---

# Review Board: Reviewing an Auth Middleware PR

## Scenario

A senior engineer opens a 340-line PR adding JWT authentication middleware to a Go HTTP API. The PR touches `pkg/auth/middleware.go`, `pkg/auth/jwt.go`, a new `pkg/ratelimit/` package, and structured logging additions across four handlers. It's the kind of PR where a single reviewer would focus on correctness and miss the security or performance angles.

## Why This Topology

The changeset crosses three review dimensions -- security (JWT validation, token handling), performance (rate limiting, middleware overhead), and test coverage. A single reviewer would likely anchor on one dimension. Review Board assigns each dimension to a specialist who reviews the full diff through their lens, producing structured findings the lead merges into one review comment.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Assign lenses, synthesize findings into single review comment |
| Security Reviewer | 1 | JWT handling, token validation, auth bypass risks |
| Performance Reviewer | 1 | Middleware chain overhead, rate limiter efficiency, allocations |
| Test Reviewer | 1 | Coverage gaps, edge cases, assertion quality |

## Spawn Prompt

```text
Create an agent team to review PR #247 adding auth middleware.
Spawn three reviewers:
- Security: JWT validation, token storage, auth bypass risks, input sanitization.
- Performance: middleware overhead, rate limiter memory usage, hot path allocations.
- Test coverage: missing edge cases, assertion quality, error path coverage.
Have each report findings as must-fix vs nice-to-have with file:line evidence.
Then synthesize into one review comment.
```

## Trade-offs

- **Lens overlap is inherent.** When a single code structure has implications across dimensions (e.g., an unbounded map is both a security DoS vector and a performance leak), multiple reviewers will flag it independently. The lead must deduplicate during synthesis.
- **Require consistent output format.** Severity / file:line / evidence / fix -- this structure makes the lead's synthesis step mechanical rather than interpretive. Without it, merging three free-form reviews is painful.
- **Three reviewers is the sweet spot for most PRs.** A fourth lens (e.g., API compatibility) is worth adding only for public-facing API changes. Beyond four, the coordination cost outweighs the marginal findings.
- **The best findings come from intersections.** Issues that span multiple lenses are exactly what a single generalist reviewer would note only once (if at all). The multi-lens approach surfaces these systematically.
