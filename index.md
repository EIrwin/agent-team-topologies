---
title: Home
layout: home
nav_order: 1
---

# Agent Team Topologies

**Proven patterns for orchestrating multi-agent teams in Claude Code.**
{: .fs-6 .fw-300 }

8 topology patterns, copy-paste spawn prompts, and a ready-to-use `.claude/` config directory. Stop guessing how to structure your agent teams — pick the right pattern and go.
{: .fs-5 .fw-300 }

[Get Started](#quick-start){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/eirwin/agent-team-topologies){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Pick Your Topology

```
  What are you trying to do?
  │
  ├── Discover / Research ──────────► A: Parallel Explorers
  │
  ├── Review code ──────────────────► B: Review Board
  │
  ├── Debug ambiguous issue ────────► C: Competing Hypotheses
  │
  ├── Build multi-layer feature
  │   ├── High risk? ──────────────► E: Risky Refactor
  │   └── Standard ───────────────► D: Feature Pod
  │
  ├── Process many small tasks ─────► H: Task Queue
  │
  ├── Pure coordination ────────────► F: Orchestrator-Only
  │
  └── Need quality gates? ─────────► G: Quality-Gated
      (composable: add to any above)
```

---

## Quick Start

**Copy the `.claude/` directory into your project** to get pre-built agents, a topology chooser skill, and quality gate hooks:

```bash
# Clone and copy configs into your project
git clone https://github.com/eirwin/agent-team-topologies.git
cp -r agent-team-topologies/.claude/ your-project/.claude/
```

You get:
- **6 agent definitions** — explorer, security reviewer, performance reviewer, test reviewer, architect, implementer
- **`/topology` skill** — interactive chooser that recommends a topology based on your goal
- **Hook scripts** — quality gates and idle summary enforcement

---

## The 8 Topologies

| Pattern | Best For | Cost |
|---------|----------|------|
| [Parallel Explorers](topologies/parallel-explorers/) | Discovery, research, codebase mapping | $$ |
| [Review Board](topologies/review-board/) | Code review with distinct lenses | $$ |
| [Competing Hypotheses](topologies/competing-hypotheses/) | Ambiguous bugs, architectural decisions | $$$ |
| [Feature Pod](topologies/feature-pod/) | Cross-layer feature delivery | $$$ |
| [Risky Refactor](topologies/risky-refactor/) | High-risk changes needing plan approval | $$ |
| [Orchestrator-Only](topologies/orchestrator-only/) | Pure coordination, lead never codes | $$$$ |
| [Quality-Gated](topologies/quality-gated/) | Enforcing completion standards (composable) | +$ |
| [Task Queue](topologies/task-queue/) | Many small independent tasks | $$$$ |

---

## Guides

| Document | What's Inside |
|----------|---------------|
| [Mental Model](docs/mental-model.md) | Teams vs subagents, core concepts, selection heuristics |
| [Decision Tree](docs/decision-tree.md) | Expanded flowchart for picking the right topology |
| [Anti-Patterns](docs/anti-patterns.md) | 8 things NOT to do with agent teams |
| [Cost Guide](docs/cost-guide.md) | Token economics by topology, cost reduction strategies |
| [Best Practices](docs/best-practices.md) | Operational guidance for running agent teams |

---

## What's in `.claude/`

```
.claude/
├── agents/
│   ├── explorer.md          # Read-only codebase discovery
│   ├── security-reviewer.md # OWASP-informed security review
│   ├── perf-reviewer.md     # Performance analysis
│   ├── test-reviewer.md     # Test coverage & correctness
│   ├── architect.md         # Plan-mode architecture design
│   └── implementer.md       # Focused code execution
├── skills/
│   └── topology/
│       └── SKILL.md         # /topology interactive chooser
└── hooks/
    ├── quality-gate.sh      # Block task completion if tests/lint fail
    ├── idle-summary.sh      # Require structured summary before idle
    └── README.md            # Hook installation guide
```

---

## Contributing

See [Contributing](CONTRIBUTING.md) for how to propose new topology patterns, submit real-world examples, and improve agent definitions or hooks.
