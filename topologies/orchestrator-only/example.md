---
title: "Example: Coordinating a Multi-Service API Versioning"
parent: Orchestrator-Only
grand_parent: Topologies
nav_order: 1
---

# Orchestrator-Only: Coordinating a Multi-Service API Versioning

## Scenario

A platform with four Go microservices (`gateway`, `users`, `billing`, `inventory`) needs to ship API v2 while maintaining v1 for existing clients. Each service has its own proto definitions, HTTP handlers, and integration tests. The versioning must be coordinated so that all four services ship v2 simultaneously -- a partial rollout would break cross-service contracts.

## Why This Topology

This is a coordination-heavy problem across four parallel workstreams. The lead needs to manage dependencies (gateway can't route v2 until all downstream services expose v2 handlers), resolve conflicts (shared proto changes), and track progress without getting pulled into implementation details. Orchestrator-Only puts the lead in delegate mode: pure coordination, never touches code.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Delegate mode -- task decomposition, dependency management, synthesis |
| Worker A | 1 | `gateway` service: v2 routing, header-based version detection |
| Worker B | 1 | `users` service: v2 handlers, backward-compatible proto changes |
| Worker C | 1 | `billing` service: v2 handlers, new pricing fields |
| Worker D | 1 | `inventory` service: v2 handlers, batch endpoint addition |

## Spawn Prompt

```text
Create an agent team to version our API from v1 to v2 across 4 Go microservices.
I want the lead to focus on orchestration only -- never touch code.
Break work into tasks per service with clear dependencies:
- All downstream services must expose v2 handlers before gateway routes to them.
- Shared proto changes must land before service-specific handlers.
Have workers self-claim unblocked tasks. Lead tracks progress and resolves blockers.
```

## How It Played Out

The lead began by decomposing the work into 18 tasks across the four services, organized into three dependency tiers. Tier 1: shared proto updates (4 tasks, one per service's `.proto` file). Tier 2: v2 handler implementations (8 tasks, two per service). Tier 3: gateway routing and integration tests (6 tasks, blocked by Tier 2). The dependency graph ensured no worker could start Tier 2 until the relevant proto task from Tier 1 was complete.

Workers self-claimed Tier 1 tasks immediately. Worker B finished the `users` proto update first and moved to their Tier 2 handler tasks. Worker C hit a blocker in `billing`: the v2 pricing fields required a new proto message type that `gateway` also needed to import. Worker C messaged the lead, who recognized this as a cross-service dependency that wasn't in the original task graph. The lead created a new blocking task for the shared proto type and assigned it to Worker C since they understood the requirement.

The most interesting coordination moment came when Worker A (gateway) was ready for Tier 3 but Worker D (inventory) was still finishing their v2 batch endpoint. The lead didn't reassign Worker A to help -- in delegate mode, the lead can't evaluate code. Instead, they created a gateway integration test task that Worker A could start with mock responses, unblocking them without waiting for inventory. When Worker D finished 12 minutes later, Worker A swapped in the real service and the tests passed on the first run.

The lead synthesized final results after all 19 tasks (the original 18 plus the added shared proto task) were complete: a coordinated v2 rollout with all four services exposing both v1 and v2 endpoints, header-based version routing in the gateway, and 14 new integration tests.

## What Went Wrong

The original task decomposition missed the cross-service proto dependency. This is the Orchestrator-Only trade-off: the lead plans from a high level without reading code, so they can miss implementation-level dependencies. The fix was quick (one new task), but it blocked Worker C for 8 minutes. Having the lead do a quick proto-level scan before decomposing tasks would have caught it upfront.

## Results

| Metric | Value |
|--------|-------|
| Duration | 1 hour 8 minutes |
| Token Cost | ~$7.50 |
| Deliverables | v2 API across 4 services, header-based routing, 14 integration tests, v1 backward compatibility |

## Takeaway

- When a worker is blocked waiting for another service, create a **mock-based task** they can start immediately. Worker A's gateway mock tests saved 12 minutes of idle time.
- The lead should scan shared dependencies (proto files, shared libraries) before decomposing tasks -- cross-service coupling is the most common source of missed dependencies.
- Orchestrator-Only is expensive ($7.50 for 4 workers + lead) but justified when coordination is the bottleneck. A single agent couldn't have tracked the dependency graph across four services without losing context.
