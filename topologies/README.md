# Agent Team Topologies

This directory contains **8 topology pattern cards** -- reusable team configurations for Claude Code agent teams. Each pattern describes a proven way to structure multi-agent collaboration for a specific class of problem.

Pick the topology that matches your work shape, then use the spawn prompt inside to get started immediately.

> **Note:** Quality-Gated is a **composable topology** -- it layers on top of any other pattern to enforce completion standards via hooks. You can combine it with any topology below.

## Topology Comparison

| Topology | Best For | Team Size | Cost | Parallelism |
|----------|----------|-----------|------|-------------|
| [Parallel Explorers](parallel-explorers/) | Discovery, research, codebase mapping | 3-5 | $$ | High |
| [Review Board](review-board/) | Code review with distinct lenses | 4 | $$ | High |
| [Competing Hypotheses](competing-hypotheses/) | Ambiguous bugs, architectural decisions | 4-7 | $$$ | Medium |
| [Feature Pod](feature-pod/) | Cross-layer feature delivery | 4 | $$$ | High |
| [Risky Refactor](risky-refactor/) | High-risk changes needing plan approval | 4 | $$ | Low (sequential) |
| [Orchestrator-Only](orchestrator-only/) | Pure coordination, lead never codes | 3-6 | $$$$ | High |
| [Quality-Gated](quality-gated/) | Enforcing completion standards | Any | +$ | Varies |
| [Task Queue](task-queue/) | Many small independent tasks | 4-9 | $$$$ | Very High |
