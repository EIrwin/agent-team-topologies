# Example: Multi-Lens Review of an Auth Middleware Rewrite

## Scenario

A teammate submitted a PR rewriting the authentication middleware from a custom JWT implementation to using Passport.js with multiple strategy support (local, OAuth, API key). The PR touches 34 files: the middleware itself, 8 route files that change how they access `req.user`, a new session store configuration, and updated tests. The change is security-critical and performance-sensitive -- auth middleware runs on every request.

## Why This Topology

No single reviewer can hold security implications, performance characteristics, and test correctness in mind simultaneously across 34 files. The change is high-stakes (auth middleware = every request), making thorough review essential. Three specialist reviewers working in parallel will catch issues that a single sequential review would miss due to fatigue or tunnel vision.

## Setup

```text
Create an agent team to review PR #287 -- auth middleware rewrite to Passport.js.
Spawn three reviewers:
- Security reviewer: check for auth bypass paths, session fixation, token
  handling, CSRF protection, and OAuth state parameter validation. Verify
  that all protected routes still enforce authentication.
- Performance reviewer: check for unnecessary middleware overhead, session
  store latency, strategy selection cost, and whether the change introduces
  any per-request database queries. Compare against the previous implementation.
- Test reviewer: verify test coverage for all auth strategies, check edge
  cases (expired tokens, revoked sessions, concurrent logins), and ensure
  integration tests cover the actual middleware chain, not just unit tests
  with mocks.
Each reviewer: produce findings as must-fix / should-fix / nice-to-have
with file paths, line numbers, and evidence.
Then synthesize into one review comment for the PR.
```

**Team:** Lead + 3 Reviewers
**Estimated duration:** ~10 minutes

## What Happened

**Security reviewer** found 3 issues:
1. **Must-fix:** The OAuth callback route did not validate the `state` parameter, leaving it vulnerable to CSRF attacks during the OAuth flow. The old implementation had a custom state check that was not ported to the Passport strategy configuration. (`src/middleware/oauth-callback.ts:47`)
2. **Must-fix:** API key authentication fell through to the next strategy on failure instead of returning 401 immediately. This meant an invalid API key would silently try session auth, potentially granting access with stale session cookies. (`src/strategies/api-key.ts:23`)
3. **Should-fix:** The `deserializeUser` callback did not check whether the user account was disabled. A disabled user with an existing session could continue making requests until the session expired. (`src/config/passport.ts:34`)

**Performance reviewer** found 2 issues:
1. **Must-fix:** The session store was configured with the default in-memory store, not the Redis store used in production. In production this would mean sessions are not shared across server instances and would be lost on restart. (`src/config/session.ts:12`)
2. **Nice-to-have:** Passport's `initialize()` middleware was being applied twice -- once at the app level and once inside the auth router. The duplication has negligible performance impact but adds unnecessary overhead. (`src/app.ts:45`, `src/routes/auth.ts:8`)

**Test reviewer** found 2 issues:
1. **Should-fix:** No integration tests for the strategy fallback chain. Unit tests mock each strategy independently, but nothing tests what happens when the first strategy fails and falls through to the next. This is exactly the scenario where the security reviewer's API key finding would surface. (`tests/auth/`)
2. **Should-fix:** The OAuth flow tests mock the provider response but do not test the `state` parameter validation (which is currently missing anyway). Once the security fix lands, these tests need to cover the happy path and the CSRF rejection path. (`tests/auth/oauth.test.ts`)

**Lead synthesis** produced a single review comment prioritizing the 3 must-fix items at the top (OAuth CSRF, API key fallthrough, session store config), followed by the 3 should-fix items. The synthesis noted that the security and test findings were linked -- the missing strategy fallback test would have caught the API key issue, and the missing OAuth state test would have caught the CSRF issue.

## What Went Wrong

The performance reviewer spent significant time analyzing Passport's internal middleware overhead by tracing through `node_modules` source code. This was thorough but low-value -- Passport's per-request overhead is well-documented and negligible. Better scoping in the spawn prompt ("focus on our code, not library internals") would have redirected that effort toward more impactful analysis, like checking whether the session store change affected cache hit rates.

The security and test reviewers both flagged the OAuth state parameter issue independently. The duplication was not wasted (it confirmed severity from two angles), but the lead's synthesis step took extra time reconciling the overlapping findings.

## Results

- **3 must-fix issues** identified: OAuth CSRF vulnerability, API key auth bypass, wrong session store
- **3 should-fix issues** identified: disabled user session check, missing integration tests, missing OAuth state tests
- **1 nice-to-have:** duplicate middleware initialization
- The PR author fixed all must-fix items before merge and created follow-up tickets for the should-fix items
- The OAuth CSRF finding alone justified the review board -- it would have shipped to production otherwise

## Retrospective

**What worked:** The specialist lens approach caught a real security vulnerability (OAuth CSRF) that a general-purpose review likely would have missed. The structured output format (must-fix / should-fix / nice-to-have with evidence) made the review actionable and easy to prioritize. Running reviewers in parallel meant the full review completed in ~10 minutes despite covering 34 files.

**What to do differently:** Scope the performance reviewer away from library internals ("only review our application code for performance issues"). Add explicit instructions for reviewers to note when their findings overlap with another reviewer's domain ("flag for cross-reference") to make the synthesis step faster. Consider adding a 4th reviewer for API compatibility when the PR changes public interfaces.

**When to reuse this pattern:** Any PR that is security-sensitive, performance-sensitive, or large enough that a single reviewer would suffer fatigue. The key signal is: "this change has multiple risk dimensions that require different expertise." Poor fits include small PRs, cosmetic changes, or changes where all risk is in a single dimension.
