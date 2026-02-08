# Agent Team Topologies

**A quick-reference model for structuring multi-agent teams in Claude Code.**

> 8 composable topology patterns — a nod to [Team Topologies](https://teamtopologies.com/) thinking, applied to how work flows through agent teams. Browse the patterns, find what fits, and adapt.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Topologies](https://img.shields.io/badge/Topologies-8-green.svg)](topologies/)

### [View the full documentation site ->](https://eirwin.github.io/agent-team-topologies/)

> [!WARNING]
> **Agent teams are experimental.** They're disabled by default in Claude Code. Enable them by setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` to `1` in your settings or environment. See the [official agent teams documentation](https://docs.anthropic.com/en/docs/claude-code/agent-teams) for setup and known limitations.

---

## Quick Start

```bash
# Clone and copy configs into your project
git clone https://github.com/eirwin/agent-team-topologies.git
cp -r agent-team-topologies/.claude/ your-project/.claude/
```

You get:
- **6 agent definitions** — explorer, security reviewer, performance reviewer, test reviewer, architect, implementer
- **`/topology` skill** — interactive chooser that recommends a topology based on your goal
- **Hook scripts** — quality gates and idle summary enforcement

Or run `/topology` in Claude Code for an interactive chooser.

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

Topologies are primitives, not monoliths — any teammate slot can itself become a topology. See the [Composing Topologies](https://eirwin.github.io/agent-team-topologies/docs/composing-topologies.html) guide for recipes.

---

## Documentation

All guides are on the [documentation site](https://eirwin.github.io/agent-team-topologies/):

- [Getting Started](https://eirwin.github.io/agent-team-topologies/docs/getting-started.html) — Enable agent teams, install configs, run your first topology
- [Mental Model](https://eirwin.github.io/agent-team-topologies/docs/mental-model.html) — Teams vs subagents, core concepts, selection heuristics
- [Decision Tree](https://eirwin.github.io/agent-team-topologies/docs/decision-tree.html) — Expanded flowchart for picking the right topology
- [Composing Topologies](https://eirwin.github.io/agent-team-topologies/docs/composing-topologies.html) — Recipes for chaining, nesting, and combining patterns
- [Anti-Patterns](https://eirwin.github.io/agent-team-topologies/docs/anti-patterns.html) — 8 things NOT to do with agent teams
- [Cost Guide](https://eirwin.github.io/agent-team-topologies/docs/cost-guide.html) — Token economics by topology, cost reduction strategies
- [Best Practices](https://eirwin.github.io/agent-team-topologies/docs/best-practices.html) — Operational guidance for running agent teams

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to:
- Propose new topology patterns
- Submit real-world examples
- Improve agent definitions or hooks

## License

[MIT](LICENSE) — use these patterns however you want.
