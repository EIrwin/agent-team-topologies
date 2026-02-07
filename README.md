# Agent Team Topologies

**Proven patterns for orchestrating multi-agent teams in Claude Code.**

> 8 topology patterns, copy-paste spawn prompts, and a ready-to-use `.claude/` config directory.
> Stop guessing how to structure your agent teams — pick the right pattern and go.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Topologies](https://img.shields.io/badge/Topologies-8-green.svg)](topologies/)

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

Or run `/topology` in Claude Code for an interactive chooser.

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

### A: Parallel Explorers

```
         ┌──────┐
         │ Lead │
         └──┬───┘
        ┌───┼───┐
        ▼   ▼   ▼
      ┌───┬───┬───┐
      │E1 │E2 │E3 │   Explorers fan out independently
      └─┬─┴─┬─┴─┬─┘   Each reports findings back to Lead
        └───┴───┘
```

**Fan-out discovery and synthesis.** 2-4 explorers investigate different areas of a codebase in parallel. Lead synthesizes findings. Best for architecture mapping, "where is X?", module-by-module investigation.

[Pattern card →](topologies/parallel-explorers/) · [Example →](topologies/parallel-explorers/example.md)

---

### B: Review Board

```
         ┌──────┐
         │ Lead │      Editor-in-chief
         └──┬───┘
        ┌───┼───┐
        ▼   ▼   ▼
      ┌───┬───┬───┐
      │Sec│Prf│Tst│   Security / Performance / Tests
      └───┴───┴───┘   Each reviews with distinct lens
```

**Multi-lens parallel code review.** Each reviewer focuses on a specific domain (security, performance, tests) and produces structured findings. Lead synthesizes into a unified review.

[Pattern card →](topologies/review-board/) · [Example →](topologies/review-board/example.md)

---

### C: Competing Hypotheses

```
         ┌───────┐
         │ Judge │     Final arbiter
         └───┬───┘
        ┌────┼────┐
        ▼    ▼    ▼
      ┌──┐ ┌──┐ ┌──┐
      │H1│◄►│H2│◄►│H3│  Investigators debate
      └──┘ └──┘ └──┘     and disprove each other
```

**Adversarial debugging and decision-making.** Multiple investigators propose competing theories and actively try to disprove each other. Lead arbitrates. Best for ambiguous bugs, architectural decisions, "approach A vs B".

[Pattern card →](topologies/competing-hypotheses/) · [Example →](topologies/competing-hypotheses/example.md)

---

### D: Feature Pod

```
         ┌──────┐
         │ Lead │      Orchestrator
         └──┬───┘
        ┌───┼───┐
        ▼   ▼   ▼
      ┌──┐┌──┐┌──┐
      │FE││BE││QA│     Each owns a stack layer
      └──┘└──┘└──┘     Contract-first, then parallelize
```

**Cross-layer feature delivery.** Frontend, backend, and QA agents each own a stack layer. Define the contract first (API shape, acceptance criteria), then parallelize implementation.

[Pattern card →](topologies/feature-pod/) · [Example →](topologies/feature-pod/example.md)

---

### E: Risky Refactor

```
      ┌──────┐
      │ Lead │         Approves plan, oversees
      └──┬───┘
         │
      ┌──────┐  approve  ┌──────┐  review  ┌─────┐
      │ Arch │──────────►│ Impl │────────►│ Rev │
      └──────┘  (plan)   └──────┘ (build)  └─────┘
      Sequential gates reduce blast radius
```

**Gated refactoring for high-risk changes.** Architect plans in read-only mode, lead approves, implementer executes, reviewer validates. Sequential gates prevent costly mistakes on security-sensitive or blast-radius-heavy changes.

[Pattern card →](topologies/risky-refactor/) · [Example →](topologies/risky-refactor/example.md)

---

### F: Orchestrator-Only

```
          ┌──────┐
          │ Lead │     Delegate mode: coordinates only
          └──┬───┘
       ┌──┬──┼──┬──┐
       ▼  ▼  ▼  ▼  ▼
      ┌──┬──┬──┬──┬──┐
      │D1│D2│D3│D4│D5│   Workers self-claim tasks
      └──┴──┴──┴──┴──┘   Lead never touches code
```

**Pure coordination lead.** Lead operates in delegate mode — spawns teammates, manages tasks, synthesizes results, but never writes code. Workers self-claim from the task list.

[Pattern card →](topologies/orchestrator-only/) · [Example →](topologies/orchestrator-only/example.md)

---

### G: Quality-Gated Delivery

```
      ┌────────┐     ┌──────┐     ┌───┐
      │ Worker │────►│ Gate │────►│ ✓ │
      └────────┘     └──┬───┘     └───┘
                        │ fail
                        ▼
                   ┌──────────┐
                   │ feedback │   Composable: layer on
                   └──────────┘   any other topology
```

**Composable quality enforcement.** Not a standalone topology — layer this on top of any other pattern. Uses `TaskCompleted` and `TeammateIdle` hooks to enforce quality gates (tests pass, lint clean, structured summaries) before work is accepted.

[Pattern card →](topologies/quality-gated/) · [Example →](topologies/quality-gated/example.md)

---

### H: Task Queue

```
          ┌──────┐
          │ Lead │         Aggregator
          └──┬───┘
    ┌──┬──┬──┼──┬──┬──┐
    ▼  ▼  ▼  ▼  ▼  ▼  ▼
   ┌──┬──┬──┬──┬──┬──┬──┐
   │W1│W2│W3│W4│W5│W6│W7│  Workers self-claim from
   └──┴──┴──┴──┴──┴──┴──┘  shared task queue
```

**High-throughput parallel processing.** Many workers self-claim from a shared task list. Best for lots of independent, small work items: ticket triage, doc extraction, bulk fixes, migration tasks.

[Pattern card →](topologies/task-queue/) · [Example →](topologies/task-queue/example.md)

---

## Docs

| Document | What's Inside |
|----------|---------------|
| [Mental Model](docs/mental-model.md) | Teams vs subagents, core concepts, selection heuristics |
| [Decision Tree](docs/decision-tree.md) | Expanded flowchart for picking the right topology |
| [Anti-Patterns](docs/anti-patterns.md) | 8 things NOT to do with agent teams |
| [Cost Guide](docs/cost-guide.md) | Token economics by topology, cost reduction strategies |
| [Best Practices](docs/best-practices.md) | Operational guidance for running agent teams |

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to:
- Propose new topology patterns
- Submit real-world examples
- Improve agent definitions or hooks

## License

[MIT](LICENSE) — use these patterns however you want.
