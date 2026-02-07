# Example: Building a Team Activity Feed

## Scenario

Your SaaS product needs a real-time activity feed showing team member actions (comments, status changes, file uploads) on a project dashboard. The feature spans three layers: a React frontend component with WebSocket updates, a Node.js backend API with event aggregation, and end-to-end tests covering the full flow. The API contract is well-defined in the PRD, and the UI mockups are approved.

## Why This Topology

The feature cleanly separates into frontend, backend, and test ownership. Each layer can be built independently once the API contract is agreed. A single agent trying to build all three would constantly context-switch between React components, Express routes, and Playwright tests -- burning context window on unrelated code. The Feature Pod lets three specialists work in parallel against a shared contract.

## Setup

```text
Create an agent team to implement the team activity feed feature.
Spawn:
- Frontend teammate: build the ActivityFeed React component with WebSocket
  subscription, virtual scrolling for large feeds, and optimistic UI updates.
  Files: src/components/ActivityFeed/, src/hooks/useActivityStream.ts
- Backend teammate: build the /api/v2/activity endpoint with cursor-based
  pagination, event aggregation from the events table, and WebSocket broadcast
  on new events. Files: src/routes/activity.ts, src/services/activity-service.ts
- QA teammate: write Playwright e2e tests covering feed loading, real-time
  updates, pagination, and error states. Files: tests/e2e/activity-feed.spec.ts

First task: agree on the API contract:
  GET /api/v2/activity?projectId=X&cursor=Y&limit=20
  Response: { items: ActivityItem[], nextCursor: string | null }
  WebSocket event: { type: "activity:new", payload: ActivityItem }

Then parallelize implementation and reconverge for integration testing.
```

**Team:** Lead + Frontend + Backend + QA
**Estimated duration:** ~18 minutes

## What Happened

**Contract phase (~2 minutes):** The lead created the contract task with the API shape, WebSocket event format, and `ActivityItem` type definition. The backend teammate proposed adding a `hasMore` boolean alongside `nextCursor` for simpler frontend logic. The frontend teammate agreed, and the contract was finalized. This small negotiation saved a mismatch that would have surfaced later during integration.

**Parallel implementation (~12 minutes):**

The **frontend teammate** built the `ActivityFeed` component with `useActivityStream` -- a custom hook managing both REST fetching and WebSocket subscription. It used `react-window` for virtual scrolling and implemented optimistic rendering for locally-triggered events. It created the component, hook, types, and a loading skeleton -- 4 files total.

The **backend teammate** built the activity service with cursor-based pagination against the `events` table, a WebSocket broadcast layer using the existing Socket.io setup, and event aggregation that collapses consecutive status changes by the same user. It added rate limiting on the WebSocket broadcast (max 10 events/second per project). 3 files total.

The **QA teammate** wrote 6 Playwright tests: feed initial load, cursor pagination, real-time update via WebSocket, empty state, error recovery on API failure, and virtual scroll performance with 500+ items. It used the existing test fixtures but needed to add a WebSocket test helper.

**Integration phase (~4 minutes):** The lead coordinated the final wiring. The frontend teammate adjusted its WebSocket message handler to match the actual event shape the backend emitted (the `payload` field was nested one level deeper than the contract specified -- see "What Went Wrong"). QA ran the full suite.

## What Went Wrong

The backend teammate wrapped the WebSocket payload in an extra envelope: `{ type: "activity:new", data: { payload: ActivityItem } }` instead of the agreed `{ type: "activity:new", payload: ActivityItem }`. The contract said `payload` at the top level, but the backend's Socket.io middleware automatically wrapped emissions. This surfaced during integration when the frontend's handler got `undefined` for the activity item.

**Fix:** The backend teammate removed the redundant wrapping by emitting directly on the namespace instead of going through the middleware. Total fix time: ~90 seconds. This could have been caught earlier if the contract task had included a concrete JSON example that both sides validated against.

The QA teammate's WebSocket test helper initially had a race condition -- it sometimes connected before the backend was ready during test setup. Adding a connection retry with backoff fixed it, but cost ~2 minutes of debugging.

## Results

- **Full feature delivered** in ~18 minutes: component, API, WebSocket integration, and 6 e2e tests
- **11 files created or modified** across the three layers
- **Zero test failures** after the integration fix
- The virtual scroll implementation handled 1000+ items smoothly in the performance test
- Rate limiting on the WebSocket prevented broadcast storms in high-activity projects

## Retrospective

**What worked:** The contract-first approach caught a design issue early (the `hasMore` addition) and gave all three teammates a clear target. Assigning non-overlapping file ownership eliminated merge conflicts entirely. The QA teammate writing tests in parallel meant the test suite was ready the moment implementation finished.

**What to do differently:** Include a concrete JSON example in the contract task, not just the type signature. The payload nesting bug would have been caught at contract time if both sides had validated against `{"type": "activity:new", "payload": {"id": "abc", ...}}`. Also, have the QA teammate stub the WebSocket connection in tests rather than depending on a live backend during setup -- it removes the race condition entirely.

**When to reuse this pattern:** Any feature that spans 2+ stack layers with a clear interface between them. The key signal is: "each layer can be built independently if we agree on the contract first." Poor fits include features where the layers are tightly coupled (e.g., server-side rendering where frontend and backend share templates).
