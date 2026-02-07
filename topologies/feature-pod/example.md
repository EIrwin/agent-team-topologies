---
title: "Example: Building a Webhook Delivery System"
parent: Feature Pod
grand_parent: Topologies
nav_order: 1
---

# Feature Pod: Building a Webhook Delivery System

## Scenario

A SaaS platform needs a webhook delivery system: users configure webhook URLs through a React dashboard, the Go API accepts and queues events, a delivery worker sends HTTP requests with retry logic, and the whole thing needs E2E tests. The API contract is well-defined: `POST /webhooks`, `GET /webhooks`, `DELETE /webhooks/:id`, and a delivery status endpoint.

## Why This Topology

The feature spans three clear layers -- backend API, frontend dashboard, and test suite -- each of which can be built independently against a shared contract. Feature Pod lets each layer owner work in parallel after agreeing on the API shape, which is exactly how webhook systems are structured: the contract (event payload, delivery status codes) is the natural integration boundary.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Define contract, coordinate integration, final verification |
| Backend | 1 | Go API endpoints, delivery worker, retry logic |
| Frontend | 1 | React webhook config UI, delivery status dashboard |
| QA | 1 | E2E tests, edge cases, integration verification |

## Spawn Prompt

```text
Create an agent team to build a webhook delivery system.
Spawn:
- Backend: Go API (CRUD endpoints + delivery worker with exponential backoff).
- Frontend: React dashboard (webhook config form + delivery status table).
- QA: E2E tests covering creation, delivery, retry, and failure scenarios.
First task: agree on the contract (API shape, event payload, status codes).
Then parallelize by layer. Reconverge for integration testing.
```

## How It Played Out

The lead's first task was the contract: four REST endpoints, a JSON event payload schema, delivery status enum (`pending`, `delivered`, `failed`, `retrying`), and exponential backoff parameters (initial 1s, max 5 retries). All three teammates confirmed the contract before starting.

The backend teammate built the CRUD endpoints and delivery worker first, using a Postgres-backed queue with `SELECT ... FOR UPDATE SKIP LOCKED` for concurrency-safe dequeuing. The retry logic used exponential backoff with jitter. The critical design decision was making the delivery worker idempotent by tracking delivery attempts in a `webhook_deliveries` table with a unique constraint on `(webhook_id, event_id)`.

The frontend teammate built a two-page React UI: a webhook configuration form with URL validation and a delivery status table with auto-refresh. They worked against the agreed contract using mock API responses, which meant they never needed to wait for the backend to be ready. The status table used a polling interval of 5 seconds, matching the QA teammate's test timing expectations.

The QA teammate wrote E2E tests covering five scenarios: successful delivery, retry after 500 response, permanent failure after max retries, duplicate event deduplication, and webhook deletion while deliveries are in flight. The last scenario surfaced the only integration issue: the backend returned 404 for in-flight deliveries after webhook deletion, but the contract hadn't specified this behavior. The lead decided on a "soft delete" approach where the webhook is marked deleted but existing deliveries complete.

Integration went smoothly because the contract was explicit. The only wiring change was updating the frontend's base URL from the mock server to the real API.

## What Went Wrong

The contract didn't specify what happens when a webhook is deleted while deliveries are queued. The QA teammate's E2E test caught this gap during integration, requiring a 15-minute discussion to agree on the soft-delete behavior and a backend code change. This is the classic Feature Pod risk: contracts can't anticipate every edge case. The fix was small, but it shows why the QA teammate should write edge-case tests early -- they act as a contract stress test.

## Results

| Metric | Value |
|--------|-------|
| Duration | 52 minutes |
| Token Cost | ~$4.80 |
| Deliverables | 4 API endpoints, delivery worker with retry, React dashboard, 5 E2E tests |

## Takeaway

- The contract phase is the highest-leverage moment in a Feature Pod. Spend an extra five minutes specifying error cases and edge behaviors -- it saves rework during integration.
- QA should start writing edge-case tests before the backend is done. Those tests function as a **contract verification suite** that catches specification gaps early.
- Mock API responses let the frontend work completely in parallel. If your contract is explicit enough to mock, it's explicit enough to build against.
