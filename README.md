# Agent Team Topologies

**Proven patterns for orchestrating multi-agent teams in Claude Code.**

> 8 composable topology patterns, copy-paste spawn prompts, and a ready-to-use `.claude/` config directory.
> Stop guessing how to structure your agent teams -- pick the right pattern and go.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Topologies](https://img.shields.io/badge/Topologies-8-green.svg)](topologies/)

### [View the full documentation site ->](https://eirwin.github.io/agent-team-topologies/)

---

## Quick Start

```bash
# Clone and copy configs into your project
git clone https://github.com/eirwin/agent-team-topologies.git
cp -r agent-team-topologies/.claude/ your-project/.claude/
```

You get:
- **6 agent definitions** -- explorer, security reviewer, performance reviewer, test reviewer, architect, implementer
- **`/topology` skill** -- interactive chooser that recommends a topology based on your goal
- **Hook scripts** -- quality gates and idle summary enforcement

Or run `/topology` in Claude Code for an interactive chooser.

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

Topologies are composable primitives -- chain them, nest them, overlay them. See the [Composing Topologies](https://eirwin.github.io/agent-team-topologies/docs/composing-topologies.html) guide for recipes.

---

## Documentation

All guides are on the [documentation site](https://eirwin.github.io/agent-team-topologies/):

- [Mental Model](https://eirwin.github.io/agent-team-topologies/docs/mental-model.html) -- Teams vs subagents, core concepts, selection heuristics
- [Decision Tree](https://eirwin.github.io/agent-team-topologies/docs/decision-tree.html) -- Expanded flowchart for picking the right topology
- [Composing Topologies](https://eirwin.github.io/agent-team-topologies/docs/composing-topologies.html) -- Recipes for chaining, nesting, and combining patterns
- [Anti-Patterns](https://eirwin.github.io/agent-team-topologies/docs/anti-patterns.html) -- 8 things NOT to do with agent teams
- [Cost Guide](https://eirwin.github.io/agent-team-topologies/docs/cost-guide.html) -- Token economics by topology, cost reduction strategies
- [Best Practices](https://eirwin.github.io/agent-team-topologies/docs/best-practices.html) -- Operational guidance for running agent teams

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to:
- Propose new topology patterns
- Submit real-world examples
- Improve agent definitions or hooks

## License

[MIT](LICENSE) -- use these patterns however you want.
