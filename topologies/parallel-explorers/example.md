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

## How It Played Out

The lead created three tasks scoped by service boundary and spawned the explorers. All three began reading files independently within seconds.

Explorer A quickly identified the core domain: `gateway` was a thin reverse proxy using `grpc-gateway` annotations to expose REST endpoints, while `users` and `billing` held the real business logic. The critical finding was that `billing` depended on `users` via a synchronous gRPC call for every charge -- a tight coupling that explained the latency complaints in the team's Slack channel.

Explorer B mapped the supporting services and found that `reports` was essentially abandoned -- its last meaningful commit was eight months old, and `inventory` had quietly taken over its aggregation duties through a duplicated SQL query. Explorer B also flagged that `notifications` used a vendored copy of an SMTP library with a known CVE.

Explorer C hit the infrastructure layer and found the Makefile was doing double duty as both build system and deployment orchestrator. The proto files in `proto/` were the actual source of truth for service contracts, but three of the six services had local `.proto` copies that had drifted from the canonical versions. This explained intermittent deserialization errors the team had been seeing in staging.

The lead synthesized all findings into a four-section architecture document: service dependency graph, data flow map, key file index (24 paths), and a "known risks" section listing the proto drift, the abandoned `reports` service, the tight billing-users coupling, and the vendored CVE.

## What Went Wrong

Explorer A spent about six minutes trying to fully trace the billing retry logic through three layers of middleware before the lead redirected them. The retry behavior was interesting but not essential for the architecture overview -- documenting "billing has custom retry middleware in `pkg/retry/`" was sufficient. This is the classic exploration trap: agents get curious about a specific mechanism instead of staying at the mapping level.

## Results

| Metric | Value |
|--------|-------|
| Duration | 38 minutes |
| Token Cost | ~$2.10 |
| Deliverables | Architecture doc with 6-service dependency graph, 24 key file paths, 5 known risks |

## Takeaway

- Split exploration zones by **service boundary**, not by file type -- it maps naturally to the repo structure and minimizes overlap.
- Include an escape-hatch instruction in explorer prompts: "If you spend more than 3 minutes on a single mechanism, document it as a finding and move on."
- Proto files and shared libraries deserve their own explorer -- they're the connective tissue that every other explorer will touch but none will fully map.
