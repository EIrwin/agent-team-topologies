# Example: Mapping an Unfamiliar Payment Service

## Scenario

Your team just acquired ownership of a payment processing service -- 180k lines of TypeScript across 12 packages in a monorepo. The previous team left minimal documentation. You have a P1 ticket to add a new payment method, but nobody on your team understands the request lifecycle, the retry logic, or where the provider integrations live. You need a mental model of the system before you can safely make changes.

## Why This Topology

A single agent would exhaust its context window before finishing even one subsystem. The codebase naturally divides into independent areas (request handling, provider integrations, persistence, error recovery) that can be explored simultaneously. You need breadth-first understanding, not a code change -- this is pure discovery work.

## Setup

```text
Create an agent team to map how our payment processing service works.
Spawn 3 teammates:
- Explorer A: trace a payment request end-to-end from API entry to provider
  callback. List the key files, middleware chain, and sequence of operations.
- Explorer B: map the data model and persistence layer. Identify all database
  tables, their relationships, and the key repository/DAO files.
- Explorer C: investigate error handling and retry logic. Find how failures
  are caught, retried, and escalated. List the retry policies and dead-letter
  behavior.
Each explorer: deliver a 10-bullet summary + the 8 most critical file paths.
Then synthesize into a single architecture overview.
```

**Team:** Lead + 3 Explorers
**Estimated duration:** ~8 minutes

## What Happened

The lead spawned three explorers and they fanned out immediately.

**Explorer A** traced the request lifecycle and discovered the service uses a custom middleware pipeline (not Express -- a homegrown router in `packages/core/src/pipeline/`). It found 6 distinct stages: auth, validation, idempotency check, provider dispatch, callback handling, and settlement. The handoff between dispatch and callback was async via a Redis queue, which was not obvious from the code structure alone.

**Explorer B** mapped 14 database tables across two schemas (`payments` and `audit`). It identified that the `payment_attempts` table has a polymorphic `provider_data` JSONB column that stores provider-specific response payloads. It flagged that there were no foreign key constraints between the `payments` and `audit` schemas -- they rely on application-level consistency.

**Explorer C** found three separate retry mechanisms: an immediate retry in the provider adapter, a delayed retry via a SQS dead-letter queue, and a cron-based reconciliation job that catches anything the first two miss. The retry policies were defined in `packages/providers/src/config/retry-policies.ts` but were partially overridden per-provider in individual adapter files.

**Lead synthesis** combined the three reports into a single architecture document: a request lifecycle diagram, a data model summary, and a risk register. The synthesis caught a key connection that no individual explorer saw on its own -- the retry logic in Explorer C's findings interacted with the idempotency check in Explorer A's findings, and the `payment_attempts` table from Explorer B was the shared state between them.

## What Went Wrong

Explorer A and Explorer C both examined `packages/core/src/pipeline/error-handler.ts` from different angles and produced partially overlapping findings about error propagation. Better boundary definition (explicitly assigning error handling to Explorer C only) would have avoided the ~90 seconds of duplicated work.

Explorer B's summary was initially too detailed -- it listed all 14 tables with full column descriptions, which consumed unnecessary tokens. A second pass from the lead asked it to distill down to the 5 most important tables, which was more useful for the synthesis.

## Results

- **Architecture document** produced in ~8 minutes covering request lifecycle, data model, and error recovery
- **23 critical file paths** identified across the three exploration areas
- **3 risks flagged:** missing FK constraints, scattered retry policy overrides, undocumented Redis queue dependency
- The team used this map to scope the new payment method ticket into 4 concrete implementation tasks

## Retrospective

**What worked:** Splitting by subsystem (lifecycle / data / errors) gave each explorer a coherent investigation scope. The 10-bullet + 8-files deliverable format kept reports concise and synthesizable.

**What to do differently:** Draw sharper boundaries around cross-cutting concerns like error handling. When a file is relevant to multiple explorers, assign it to one and have others reference that explorer's findings. Also, constrain output length in the spawn prompt ("max 500 words per explorer") to prevent verbose reports that slow down synthesis.

**When to reuse this pattern:** Any time you inherit a codebase, onboard to a new service, or need to build understanding before making changes. The key signal is: "we need to understand this before we can change it."
