---
title: Home
layout: home
nav_order: 1
---

# Agent Team Topologies

**A quick-reference model for structuring multi-agent teams in Claude Code.**
{: .fs-6 .fw-300 }

8 composable topology patterns — a nod to [Team Topologies](https://teamtopologies.com/) thinking, applied to how work flows through agent teams. Browse the patterns, find what fits, and adapt.
{: .fs-5 .fw-300 }

[Find Your Topology](docs/decision-tree.md){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Getting Started](docs/getting-started.md){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Official Docs](https://docs.anthropic.com/en/docs/claude-code/agent-teams){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/eirwin/agent-team-topologies){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Pick Your Topology

| Goal | Question | Topology |
|------|----------|----------|
| **Understand** | Multiple independent questions? | [Parallel Explorers](topologies/parallel-explorers/) |
| | Ambiguous bug? | [Competing Hypotheses](topologies/competing-hypotheses/) |
| **Build** | Multi-layer feature? | [Feature Pod](topologies/feature-pod/) |
| | Many small tasks? | [Task Queue](topologies/task-queue/) |
| | Pure coordination? | [Orchestrator-Only](topologies/orchestrator-only/) |
| **Review** | Multiple lenses? | [Review Board](topologies/review-board/) |
| **Risky change** | Expensive to get wrong? | [Risky Refactor](topologies/risky-refactor/) |
| **Any of the above** | Need quality enforcement? | + [Quality-Gated](topologies/quality-gated/) overlay |

[Full decision tree →](docs/decision-tree.md){: .btn .btn-outline .fs-4 }

---

## The 8 Topologies

| Pattern | Best For | Cost |
|---------|----------|------|
| [Parallel Explorers](topologies/parallel-explorers/) | Discovery, research, codebase mapping | Low |
| [Review Board](topologies/review-board/) | Code review with distinct lenses | Low |
| [Competing Hypotheses](topologies/competing-hypotheses/) | Ambiguous bugs, architectural decisions | Medium |
| [Feature Pod](topologies/feature-pod/) | Cross-layer feature delivery | Medium |
| [Risky Refactor](topologies/risky-refactor/) | High-risk changes needing plan approval | Low |
| [Orchestrator-Only](topologies/orchestrator-only/) | Pure coordination, lead never codes | High |
| [Quality-Gated](topologies/quality-gated/) | Enforcing completion standards (composable) | Overlay |
| [Task Queue](topologies/task-queue/) | Many small independent tasks | High |

{: .important }
> **Topologies are primitives, not monoliths.** Any teammate slot can itself become a topology -- a reviewer in Feature Pod can spawn a Review Board, an explorer can fan out sub-explorers. See [Composing Topologies](docs/composing-topologies.md) for recipes.

---

## Guides

| Document | What's Inside |
|----------|---------------|
| [Getting Started](docs/getting-started.md) | Enable agent teams, install configs, run your first topology |
| [Mental Model](docs/mental-model.md) | Teams vs subagents, core concepts, selection heuristics |
| [Decision Tree](docs/decision-tree.md) | Expanded flowchart for picking the right topology |
| [Composing Topologies](docs/composing-topologies.md) | Recipes for chaining, nesting, and combining patterns |
| [Anti-Patterns](docs/anti-patterns.md) | 8 things NOT to do with agent teams |
| [Cost Guide](docs/cost-guide.md) | Token economics by topology, cost reduction strategies |
| [Best Practices](docs/best-practices.md) | Operational guidance for running agent teams |

---

## Contributing

See [Contributing](CONTRIBUTING.md) for how to propose new topology patterns, submit real-world examples, and improve agent definitions or hooks.
