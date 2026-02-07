---
title: "Example: Migrating from SQL Queries to sqlc"
parent: Risky Refactor
grand_parent: Topologies
nav_order: 1
---

# Risky Refactor: Migrating from SQL Queries to sqlc

## Scenario

A Go API service has 34 hand-written SQL queries spread across 12 repository files. The queries use string concatenation for some filters, there are no compile-time checks, and two production bugs in the last month were caused by query/struct field mismatches. The team decides to migrate to `sqlc` for type-safe generated code, but the migration touches every database interaction in the service.

## Why This Topology

This change has a high blast radius -- every repository file changes, and getting a query wrong means silent data corruption or runtime panics. Risky Refactor separates planning from execution: an architect maps every query and produces a migration plan, the lead approves it, an implementer executes it, and a reviewer validates the result. The sequential gates prevent compounding errors.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Review and approve the migration plan |
| Architect | 1 | Catalog queries, produce migration plan with rollback strategy |
| Implementer | 1 | Execute the approved plan, migrate queries to sqlc |
| Reviewer | 1 | Validate implementation against the plan, run tests |

## Spawn Prompt

```text
Spawn an architect to plan migrating our SQL queries to sqlc.
Require plan approval before any changes.
Approval criteria: full query inventory, migration order, rollback plan, test strategy.
After approval, spawn an implementer to execute the plan + a reviewer to validate.
```

## Trade-offs

- **Separating architect and implementer genuinely helps.** The architect's query inventory catches patterns the implementer would discover mid-flight, causing costly context switches. The upfront catalog pays for itself.
- **Plan approval gates catch real issues.** Even brief pushback from the lead (e.g., "batch size too large" or "migration order wrong") improves plan quality. Don't skip this step for speed.
- **Estimate double for the "hard" category.** Dynamic SQL, complex joins, and anything that doesn't map cleanly to the target tool's model will take longer than expected. Architects tend to underestimate impedance mismatch.
- **Keep deprecated code until tests pass.** The ability to diff old vs. new implementations side-by-side is invaluable for the reviewer. Delete the old code only after each phase is verified.
