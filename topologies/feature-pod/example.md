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

## Trade-offs

- **The contract phase is the highest-leverage moment.** Spend extra time specifying error cases and edge behaviors upfront -- it saves rework during integration. Contracts can't anticipate every edge case, but covering the obvious ones (e.g., what happens on deletion of in-flight items) prevents mid-build surprises.
- **QA should write edge-case tests early.** Those tests function as a contract verification suite that catches specification gaps before integration. Don't wait for the backend to be done.
- **Mock APIs enable true parallelism.** If your contract is explicit enough to mock, it's explicit enough to build against. The frontend can work completely independently using mock responses.
- **Integration is where gaps surface.** No matter how good the contract, some edge cases only emerge when layers connect. Keep integration as a distinct phase rather than treating it as a formality.
