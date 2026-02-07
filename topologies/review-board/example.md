# Review Board: OAuth2 Authentication PR Review

## Scenario
A Rails 7 application called FieldOps has used cookie-based session authentication since launch. A contractor submitted PR #342: "Add OAuth2 authentication via Google and GitHub," which adds a second auth path alongside existing sessions. The PR touches 23 files across auth controllers, session management, user model callbacks, and middleware configuration. It introduces the `omniauth` and `omniauth-rails_csrf_protection` gems, adds OAuth token storage, and modifies the existing `SessionsController`.

This is a high-stakes change. Auth bugs mean either locked-out users or unauthorized access. The contractor's code works in manual testing, but the team wants a thorough review before merging.

## Why This Topology
Auth changes need scrutiny from multiple angles that a single reviewer tends to blur together. A security expert looking at token storage has a different mindset than a performance expert checking query patterns or a test expert checking edge case coverage. The Review Board lets each lens get full attention without the "I already spent 20 minutes reviewing, it's probably fine" fatigue that kills thorough manual reviews.

## Setup

### Team Creation
```text
Create an agent team to review PR #342 which adds OAuth2 authentication.
Spawn three reviewers:
- Security reviewer: focus on token storage, session fixation, CSRF protection,
  OAuth state parameter validation, scope of permissions requested, and any
  data exposure risks. Check for OWASP auth guidelines compliance.
- Performance reviewer: focus on database query efficiency during token refresh,
  N+1 queries on user lookup, middleware overhead on every request, and
  caching strategy for OAuth tokens.
- Test reviewer: focus on test coverage gaps, missing edge cases (expired
  tokens, revoked permissions, concurrent sessions, account linking conflicts),
  and assertion quality.
Each reviewer should produce findings as: Finding / Severity (must-fix,
should-fix, nice-to-have) / Evidence (file + line) / Suggested fix.
Then synthesize into one unified review comment.
```

### Task Breakdown
| Task | Owner | Deliverable |
|------|-------|-------------|
| Review for security implications | Security reviewer | Structured findings report |
| Review for performance impact | Performance reviewer | Structured findings report |
| Review for test coverage and correctness | Test reviewer | Structured findings report |
| Synthesize into unified review | Lead | Prioritized review comment |

## What Happened

### [0:00] Reviewers begin parallel analysis
All three reviewers started reading the PR diff simultaneously. Each focused on their assigned lens from the first file they opened.

### [0:03] Security reviewer finds token storage vulnerability
The security reviewer flagged the first must-fix within three minutes:

> **Finding 1 (must-fix):** OAuth access tokens are stored in `localStorage` via the frontend JavaScript in `app/javascript/controllers/oauth_controller.js:34`. This exposes tokens to XSS attacks. Any script injected into the page can read `localStorage` and exfiltrate tokens.
>
> **Evidence:** `localStorage.setItem('oauth_token', response.token)` at line 34.
>
> **Suggested fix:** Store OAuth tokens in `httpOnly` cookies set by the server. The frontend should never directly handle tokens. Move token storage to `OauthCallbacksController#create` and set a `httpOnly; Secure; SameSite=Strict` cookie.

The security reviewer continued and found a second critical issue:

> **Finding 2 (must-fix):** The OAuth state parameter is generated but never validated on callback. `OauthCallbacksController#create` (line 18) extracts the token from the OAuth response but does not verify `params[:state]` against the value stored in the session. This allows CSRF attacks where an attacker can force a victim to link the attacker's OAuth account.
>
> **Evidence:** `app/controllers/oauth_callbacks_controller.rb:18` -- no `state` parameter check.
>
> **Suggested fix:** Add `validate_oauth_state!` before processing the callback. Compare `params[:state]` with `session[:oauth_state]` and reject mismatches with a 403.

### [0:06] Performance reviewer identifies query inefficiency
The performance reviewer found an N+1 pattern in the token refresh flow:

> **Finding 1 (should-fix):** On every token refresh, the `OauthTokenRefreshMiddleware` (line 42) queries the database for the user, then queries again for their OAuth credentials, then queries again for their organization membership to check OAuth scope. These are three separate queries that run on every authenticated request when the token is within 5 minutes of expiry.
>
> **Evidence:** `app/middleware/oauth_token_refresh_middleware.rb:42-58` -- three sequential `find_by` calls.
>
> **Suggested fix:** Use a single joined query: `User.includes(:oauth_credentials, :organization_memberships).find_by(id: user_id)`. Better yet, cache the refresh check result in the session so it does not hit the database on every request.

The performance reviewer also noted a less critical concern:

> **Finding 2 (nice-to-have):** The `omniauth` middleware initializer loads and parses the OAuth configuration on every request (including unauthenticated ones). This adds ~2ms of overhead. Consider lazy-loading the OAuth strategy only when the OAuth routes are hit.

### [0:09] Test reviewer flags missing edge cases
The test reviewer analyzed the existing test files and the new specs added in the PR:

> **Finding 1 (must-fix):** There are no tests for expired OAuth tokens. The `OauthTokenRefreshMiddleware` has a code path for when the refresh token itself has expired (line 67: `rescue OAuth2::Error`), which falls through to destroying the session. This path has zero test coverage and could silently log users out.
>
> **Evidence:** `spec/middleware/oauth_token_refresh_middleware_spec.rb` -- no test case for expired refresh tokens.
>
> **Suggested fix:** Add a spec that stubs an expired refresh token response and verifies the user is redirected to the login page with a flash message, not silently logged out.

> **Finding 2 (should-fix):** No test for account linking conflicts. If a user signs up with email, then tries to OAuth with a Google account that has a different email, the PR's `OauthCallbacksController#create` will create a duplicate user record. There's no test for this, and the code has no guard against it.
>
> **Evidence:** `app/controllers/oauth_callbacks_controller.rb:25` -- `User.find_or_create_by(email: auth_hash['info']['email'])` does not check if the current session already has a logged-in user.

> **Finding 3 (should-fix):** No tests for concurrent sessions. A user logged in via session auth on one browser and OAuth on another could have conflicting session states. The current session cleanup in `SessionsController#destroy` does not invalidate OAuth tokens.

### [0:12] The CSRF overlap
Both the security reviewer and the test reviewer independently flagged CSRF concerns. The security reviewer found the missing `state` parameter validation (a code-level vulnerability). The test reviewer found the absence of CSRF-related tests (a coverage gap). Both were valid findings, but they overlapped significantly.

The lead noticed when collecting reports:

> **Lead:** "Security and Test reviewers both flagged CSRF. I'm consolidating these: the security finding (missing state validation) is the must-fix. The test finding (no CSRF tests) becomes a sub-item: 'after fixing the state validation, add specs covering the CSRF attack vector.' Removing the duplicate from the test reviewer's list to keep the final review clean."

### [0:16] Lead synthesizes the unified review
The lead produced a single review comment organized by priority:

**Must-Fix (3 issues):**
1. Token storage: move from `localStorage` to `httpOnly` cookies (Security)
2. OAuth state parameter: validate on callback to prevent CSRF (Security)
3. Expired refresh token: add test coverage and verify the user experience (Test)

**Should-Fix (3 issues):**
4. Token refresh queries: consolidate three queries into one joined query (Performance)
5. Account linking conflict: guard against duplicate user creation (Test)
6. Concurrent session cleanup: invalidate OAuth tokens on session destroy (Test)

**Nice-to-Have (1 issue):**
7. Lazy-load OAuth middleware configuration (Performance)

### [0:20] Review posted
The lead formatted the review as a single PR comment with all findings, evidence links, and suggested fixes. Each finding included the severity, the file and line number, and a concrete code suggestion.

## What Went Wrong
**The CSRF duplication** was minor but illustrative. When review dimensions overlap (security and test coverage naturally intersect on auth), reviewers will flag the same root issue from different angles. The lead spent about 2 minutes reconciling the two findings. To avoid this in future reviews, the spawn prompt could include: "If you identify an issue that crosses into another reviewer's domain, note it briefly but focus your detailed analysis on your own lens."

**No major failures.** This topology is low-risk since reviewers are read-only. The main cost of failure is wasted tokens from redundant analysis, not broken code. The CSRF overlap cost roughly $0.15 in duplicated work.

## Results
| Metric | Value |
|--------|-------|
| Duration | 20 minutes |
| Token Cost | ~$1.80 |
| Key Deliverables | Unified review comment with 7 findings (3 must-fix, 3 should-fix, 1 nice-to-have) |

## Retrospective
- **What worked:** The multi-lens approach caught issues that a single reviewer would have missed. The security reviewer's `localStorage` finding and the test reviewer's account linking conflict are both the kind of thing that gets an "LGTM" in a tired Friday afternoon review. Having dedicated focus per dimension produced higher-quality findings.
- **What didn't:** The CSRF overlap between security and test reviewers shows that auth reviews have natural cross-cutting concerns. The deduplication was easy but could be avoided with clearer scope instructions.
- **Would use again?** Yes, for any PR touching authentication, authorization, payment processing, or data privacy. The $1.80 cost is trivial compared to the cost of shipping a token storage vulnerability to production.
- **Tip:** For auth-related reviews, consider adding a fourth reviewer for "user experience on failure paths" -- what happens when tokens expire, when OAuth providers are down, when account linking fails. The test reviewer partially covered this, but a dedicated UX-of-errors lens catches things like silent logouts and confusing redirect loops that are neither security nor performance issues.
