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

## How It Played Out

The architect started by cataloging every raw SQL query across the 12 repository files. They found 34 queries total: 18 simple CRUD operations, 11 queries with dynamic filters built via string concatenation, and 5 complex joins. The architect flagged the 11 dynamic-filter queries as the highest risk because `sqlc` handles dynamic `WHERE` clauses differently than hand-written string building.

The migration plan proposed three phases: first, migrate the 18 simple CRUD queries (low risk, high volume); second, migrate the 5 complex joins (medium risk); third, migrate the 11 dynamic-filter queries using `sqlc`'s `sqlc.arg()` and `CASE WHEN` patterns. Each phase included a rollback step: keep the old repository methods as `_deprecated` suffixes until the phase's tests pass, then delete them. The architect estimated the whole migration at 45-60 minutes of implementation time.

The lead reviewed the plan and pushed back on one point: the architect had proposed migrating all 18 CRUD queries in a single commit. The lead required splitting into batches of 6 to keep each commit reviewable. The architect revised, the lead approved, and the implementer started.

The implementer worked through phase one methodically, writing `.sql` files in `queries/`, running `sqlc generate`, and updating each repository file to use the generated code. Phase two (complex joins) required rewriting two queries as CTEs to fit `sqlc`'s parser, but the generated types caught a field mismatch that had been silently truncating a `description` column in production -- exactly the kind of bug that motivated the migration.

The reviewer validated each phase against the plan, ran the full test suite, and confirmed that the generated types matched the existing struct definitions. On phase three, the reviewer caught that one dynamic-filter query had been migrated incorrectly -- the `CASE WHEN @filter != '' THEN column = @filter ELSE TRUE END` pattern was producing a full table scan because the query planner couldn't optimize the conditional. The implementer fixed it by splitting into two named queries (`ListUsersFiltered` and `ListUsersAll`) and selecting at runtime in Go.

## What Went Wrong

Phase three took twice as long as the architect estimated. The dynamic-filter queries required more creative `sqlc` patterns than expected, and two queries needed to be split into separate named queries rather than using the `CASE WHEN` approach. The architect's plan was good but underestimated the impedance mismatch between dynamic SQL and `sqlc`'s static analysis model. The lesson: when estimating, double the time for the "hard" category.

## Results

| Metric | Value |
|--------|-------|
| Duration | 1 hour 24 minutes |
| Token Cost | ~$5.20 |
| Deliverables | 34 queries migrated to sqlc, zero runtime type mismatches, 1 production bug found during migration |

## Takeaway

- Separating the architect and implementer genuinely helped -- the architect's query inventory caught patterns the implementer would have discovered mid-flight, causing costly context switches.
- The plan approval gate caught a real issue (batch size too large). Even brief pushback from the lead improves plan quality.
- Keep deprecated code until each phase's tests pass. The ability to `git diff` old vs. new repository methods side-by-side was invaluable for the reviewer.
