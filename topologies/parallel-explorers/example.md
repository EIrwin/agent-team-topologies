---
title: "Example: Mapping an Undocumented Microservices Repo"
parent: Parallel Explorers
grand_parent: Topologies
nav_order: 1
---

# Parallel Explorers: Mapping an Undocumented Microservices Repo

## Scenario

A platform team inherits a Go monorepo containing six microservices (`gateway`, `users`, `billing`, `notifications`, `inventory`, `reports`), all communicating over gRPC. The original authors left no architecture docs. The README says `make run` and the CI pipeline is a 400-line Makefile nobody wants to touch.

## Why This Topology

This is pure discovery -- no code changes needed, just understanding. The repo is too large for one agent's context window, but it splits naturally by service boundary. Parallel Explorers lets three agents each take a slice and report structured findings, which the lead synthesizes into a single architecture document.

## Team Shape

| Role | Count | Responsibility |
|------|-------|----------------|
| Lead | 1 | Assign zones, synthesize findings into architecture doc |
| Explorer A | 1 | Core services: `gateway`, `users`, `billing` |
| Explorer B | 1 | Supporting services: `notifications`, `inventory`, `reports` |
| Explorer C | 1 | Infrastructure: proto definitions, Makefile, CI, shared libs |

## Spawn Prompt

```text
Create an agent team to map how this Go microservices monorepo works.
Spawn 3 teammates:
- Explorer A: trace gateway, users, and billing services; map gRPC contracts and data flows.
- Explorer B: trace notifications, inventory, and reports services; identify external dependencies.
- Explorer C: map proto definitions, shared libraries, Makefile targets, and CI pipeline.
Have each deliver: 10 bullet findings + the 8 most important file paths. Then synthesize.
```

## Trade-offs

- **Split by service boundary, not file type.** Service boundaries map naturally to repo structure and minimize overlap between explorers. Splitting by file type (e.g., one explorer for all `.proto` files) creates cross-cutting concerns.
- **Explorers get curious.** Agents will dig deep into interesting mechanisms instead of staying at the mapping level. Include an escape hatch: "If you spend more than 3 minutes on a single mechanism, document it as a finding and move on."
- **Proto files and shared libraries need their own explorer.** They're the connective tissue every other explorer will touch but none will fully map. Without a dedicated infrastructure explorer, these gaps go unnoticed.
- **Synthesis quality depends on structured output.** If explorers return free-form prose, the lead spends most of their time reformatting. Require a consistent output format (bullet findings + key file paths) upfront.
