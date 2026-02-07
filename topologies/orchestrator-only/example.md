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

## Trade-offs

- **The lead plans without reading code, so they miss implementation-level dependencies.** Cross-service coupling (shared proto types, common libraries) is the most common source of missed dependencies. Have the lead scan shared dependencies before decomposing tasks.
- **When a worker is blocked, create a mock-based task.** Rather than letting a worker idle waiting for another service, give them a task they can start immediately using mock responses. Swap in real dependencies when they're ready.
- **Orchestrator-Only is the most expensive topology.** Multiple workers plus a non-coding lead adds up. It's justified when coordination is genuinely the bottleneck -- a single agent couldn't track the dependency graph across four services without losing context.
- **Task graphs evolve mid-session.** Accept that the original decomposition will need new tasks as implementation-level dependencies surface. The lead should be ready to create and insert blocking tasks on the fly.
