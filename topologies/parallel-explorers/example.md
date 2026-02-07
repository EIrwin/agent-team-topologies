---
title: "Example: Rails Monorepo Mapping"
parent: Parallel Explorers
grand_parent: Topologies
nav_order: 1
---

# Parallel Explorers: Mapping an Undocumented Rails Monorepo

## Scenario
A fintech startup called LedgerBase has a Rails 7 monorepo: 214 ActiveRecord models, a React 18 frontend in `client/`, 12 Sidekiq background job classes, a gRPC service layer for inter-service communication, and Terraform configs for AWS deployment. The two senior engineers who built it left six months ago. A new team of three has been hired, and their first week is spent staring at `app/models/` trying to figure out what `TransactionReconciliationBatch` does and why it has 14 associations.

There are no architecture docs. The README says "run `bin/setup`." The test suite takes 45 minutes and has 3,200 tests, 91 of which are currently failing.

## Why This Topology
This is a pure discovery problem across a codebase too large for a single agent to hold in context. No code changes are needed -- just understanding. Parallel Explorers lets three agents each take a non-overlapping slice of the system and report back structured findings, which the lead synthesizes into something a human can actually read. A Feature Pod or Task Queue would be overkill since there is nothing to build yet.

## Setup

### Team Creation
```text
Create an agent team to map how the LedgerBase monorepo works.
Spawn 3 teammates:
- Explorer A (backend): trace the core domain models and their relationships;
  map the request lifecycle from routes -> controllers -> services -> models;
  identify the most important 8 files in app/models/ and app/services/.
- Explorer B (frontend): map the React app in client/; trace state management
  (Redux? Context? React Query?); identify how the frontend communicates
  with the Rails API; list the 8 most important component files.
- Explorer C (infrastructure): map Sidekiq jobs, the gRPC layer, Terraform
  configs, and deployment pipeline; identify background processing patterns
  and external service dependencies.
Have each deliver: 10 bullet findings + the 8 most important file paths.
Then synthesize into a single architecture document.
```

### Task Breakdown

| Task | Owner | Deliverable |
|------|-------|-------------|
| Map core domain models and request lifecycle | Explorer A | 10 findings + 8 key files |
| Map React frontend architecture and API integration | Explorer B | 10 findings + 8 key files |
| Map infrastructure, jobs, gRPC, and deployment | Explorer C | 10 findings + 8 key files |
| Synthesize findings into architecture doc | Lead | Structured architecture document |

## What Happened

### [0:00] Lead assigns exploration zones
Lead created three tasks and spawned the explorers. Each got a focused prompt scoping them to their area. Within 30 seconds, all three were reading files independently.

### [0:02] Explorer A starts tracing the domain model
Explorer A began with `app/models/` and `config/routes.rb`, quickly identifying the core domain:

> "The system is organized around four bounded contexts: **Accounts** (User, Organization, Membership), **Transactions** (Transaction, TransactionLine, TransactionReconciliationBatch), **Ledger** (Account, JournalEntry, Balance), and **Compliance** (AuditLog, ComplianceCheck, RegulatoryReport). The Transaction model alone has 14 associations because it acts as the central join point between the ledger and compliance contexts."

Explorer A identified that `app/services/reconciliation/` contained the most critical business logic -- a 400-line `ReconciliationEngine` that orchestrated nightly batch processing.

### [0:05] Explorer B maps the React frontend
Explorer B found the frontend was a fairly standard React 18 + Redux Toolkit setup:

> "The client app uses Redux Toolkit with RTK Query for API communication. There are 47 feature slices under `client/src/features/`. The API layer is auto-generated from an OpenAPI spec at `client/src/api/generated/` -- this is important because it means the contract between frontend and backend is machine-enforced."

### [0:08] Explorer C hits the infrastructure layer
Explorer C quickly mapped the Sidekiq jobs and found the gRPC layer:

> "There are 12 Sidekiq job classes, but only 3 matter: `ReconciliationBatchJob`, `ComplianceCheckJob`, and `BalanceSnapshotJob`. These run on a nightly cron via `config/sidekiq_cron.yml`. The gRPC layer in `app/grpc/` exposes 4 services for a mobile app that was apparently started but never finished -- the proto files reference a `MobileAuthService` that has no implementation."

### [0:12] Explorer B gets stuck in a circular dependency
Explorer B started tracing the Redux store and got caught in a loop. The `transactionsSlice` imported from `accountsSlice`, which imported from `ledgerSlice`, which imported from `transactionsSlice` through a shared selector file. Explorer B kept reading the same four files trying to untangle it:

> "The dependency graph appears circular. `transactionsSlice.ts` imports `selectActiveAccount` from `accountsSlice.ts`, which imports `selectLedgerBalance` from `ledgerSlice.ts`, which imports `selectPendingTransactions` from `transactionsSlice.ts`. Tracing this further..."

After three passes through the same files, the lead noticed Explorer B was burning tokens without new findings and intervened:

> **Lead to Explorer B:** "You've identified a circular dependency in the Redux selectors -- that's a finding in itself. Log it as finding #7 and move on to mapping the routing structure in `client/src/routes/`. Don't try to fully resolve the circular dependency; just document it."

Explorer B acknowledged and shifted to routing, producing three more useful findings in the time it would have spent going in circles.

### [0:25] Explorers report back
All three explorers delivered their structured findings. Explorer A's were the most detailed (the backend was the most complex layer). Explorer C flagged a surprise: the Terraform configs referenced a staging environment that no longer existed in AWS, and the deploy script had a hardcoded IP address for a database that had been migrated.

### [0:35] Lead synthesizes
The lead combined all findings into a structured architecture document organized by bounded context, with a dependency map, key file index, and a "known risks" section that included:
- The circular Redux selector dependency
- 91 failing tests (Explorer A confirmed most were in the reconciliation module, related to a date-handling change)
- The orphaned gRPC mobile auth service
- The stale Terraform staging config

## What Went Wrong
**Explorer B's circular dependency loop** cost roughly 8 minutes and an estimated $0.35 in tokens before the lead redirected. The explorer kept re-reading the same files hoping to find the resolution instead of recognizing the circularity itself as the finding. This is a common failure mode with exploration tasks -- agents can get "curious" about a problem and spiral instead of documenting and moving on.

**Overlap between Explorer A and C:** Both explorers independently read `app/services/reconciliation/reconciliation_engine.rb` because it involved both domain logic (Explorer A's scope) and Sidekiq job orchestration (Explorer C's scope). This produced slightly redundant findings, though from different angles. Tighter boundary definitions in the spawn prompt would have avoided this.

## Results

| Metric | Value |
|--------|-------|
| Duration | 45 minutes |
| Token Cost | ~$2.50 |
| Key Deliverables | Architecture doc with 4 bounded contexts, dependency map, 24 key file paths, 6 known risks |

## Retrospective
- **What worked:** Splitting by layer (backend/frontend/infra) mapped naturally to the codebase structure. Each explorer's findings were genuinely non-overlapping. The structured "10 findings + 8 files" deliverable format kept reports focused and comparable.
- **What didn't:** Explorer B needed earlier intervention on the circular dependency. The lead should have set a time-box or instruction like "if you spend more than 3 minutes on a single issue, log it as a finding and move on."
- **Would use again?** Yes. This produced in 45 minutes what would have taken a new team member 2-3 days of manual code reading. The architecture doc became the team's onboarding reference for the next two hires.
- **Tip:** Include an explicit "escape hatch" instruction in explorer prompts: "If you find yourself re-reading the same files, document the complexity as a finding and move to your next area." This prevents the most common failure mode in exploration tasks.
