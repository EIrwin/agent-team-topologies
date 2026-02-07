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

## How It Played Out

The lead assigned the three review lenses and pointed all reviewers at the same diff. All three started reading the changeset simultaneously.

The security reviewer found two must-fix issues within minutes. First, `jwt.go` was using `jwt.Parse()` without specifying allowed signing algorithms, which left it open to an algorithm-confusion attack where an attacker could switch from RS256 to HS256 using the public key as the HMAC secret. Second, the rate limiter stored client IPs in a `sync.Map` that never evicted entries -- a slow-leak DoS vector. Both findings included exact file:line references and suggested fixes.

The performance reviewer confirmed the `sync.Map` concern from a different angle: under load, the rate limiter would grow unbounded and cause GC pressure. They also flagged that the middleware chain created a new `slog.Logger` per request via `slog.With()`, which allocated on every call. Switching to a handler-level logger passed via context would eliminate ~2KB of allocations per request.

The test reviewer found that `middleware_test.go` covered the happy path well but had no tests for expired tokens, malformed JWTs, or the rate limiter's eviction behavior (because there was no eviction). They also noted the tests used `httptest.NewRecorder` but never asserted on response headers -- the `WWW-Authenticate` header was silently missing from 401 responses.

The lead merged all findings into a single prioritized review comment: two must-fix security issues, one must-fix performance issue (unbounded map), and three nice-to-have improvements (per-request allocations, missing header assertions, expired token tests).

## What Went Wrong

The security and performance reviewers both flagged the unbounded `sync.Map` -- one as a DoS vector, the other as a memory leak. The lead had to deduplicate and decided to present it as a security finding with a performance note. This overlap is inherent when a single code structure has implications across lenses. Tighter scope definitions could reduce it but never eliminate it entirely.

## Results

| Metric | Value |
|--------|-------|
| Duration | 22 minutes |
| Token Cost | ~$1.60 |
| Deliverables | Single review comment with 3 must-fix, 3 nice-to-have findings |

## Takeaway

- The highest-value findings came from the **intersection** of lenses -- the `sync.Map` issue was both a security and performance problem that a single generalist reviewer might have noted only once.
- Require reviewers to use a consistent output format (severity / file:line / evidence / fix) -- it makes the lead's synthesis step mechanical rather than interpretive.
- Three reviewers is the sweet spot for most PRs. A fourth (API compatibility) is worth adding only for public-facing API changes.
