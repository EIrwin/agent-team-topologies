# Agent Team Topologies

Reusable team topology patterns for Claude Code agent teams. This repo provides battle-tested configurations for structuring multi-agent collaboration -- each pattern describes a proven way to decompose work across parallel Claude Code instances.

## Quick start

Use the `/topology` skill to interactively select the right pattern for your task:

```
/topology
```

It will walk you through the decision tree and output a ready-to-use spawn prompt.

## Repo structure

```
docs/                  Conceptual guides (mental model, decision tree, etc.)
topologies/            8 topology pattern cards with spawn prompts and examples
.claude/
  agents/              Agent definitions for working in this repo
  skills/topology/     Interactive topology selector skill
  hooks/               Hook definitions for quality-gated workflows
  settings.local.json  Project-level Claude Code permissions
```

## Topologies

| Pattern | Best for |
|---------|----------|
| [Parallel Explorers](topologies/parallel-explorers/) | Discovery, research, codebase mapping |
| [Review Board](topologies/review-board/) | Code review with distinct lenses |
| [Competing Hypotheses](topologies/competing-hypotheses/) | Ambiguous bugs, architectural decisions |
| [Feature Pod](topologies/feature-pod/) | Cross-layer feature delivery |
| [Risky Refactor](topologies/risky-refactor/) | High-risk changes needing plan approval |
| [Orchestrator-Only](topologies/orchestrator-only/) | Pure coordination, lead never codes |
| [Quality-Gated](topologies/quality-gated/) | Enforcing completion standards (composable overlay) |
| [Task Queue](topologies/task-queue/) | Many small independent tasks |

## Agent definitions

- **`explorer`** -- Read-only codebase discovery specialist. Maps architecture, traces flows, identifies key files.
- **`security-reviewer`** -- OWASP-informed security review. Categorizes findings as must-fix / should-fix / nice-to-have.
- **`perf-reviewer`** -- Performance analysis. Algorithmic complexity, N+1 queries, memory, bundle size.
- **`test-reviewer`** -- Test coverage and correctness. Coverage gaps, missing edge cases, test quality.
- **`architect`** -- Plan-mode architecture design. Produces plans with rollback strategies. Does not implement.
- **`implementer`** -- Focused code execution. Follows plans, tests before marking done.

## For agents working in this repo

- Pattern cards live in `topologies/<pattern-name>/index.md`. Each card follows a consistent structure: when to use, team shape, spawn prompt, and example walkthrough.
- The `/topology` skill in `.claude/skills/topology/` is the interactive entry point. It reads the decision tree and guides users to the right pattern.
- Docs in `docs/` are conceptual guides, not pattern cards. Keep them topology-agnostic.
- Examples must be **real walkthroughs**, not hypothetical templates. Every example should include what actually happened, what went wrong, and concrete metrics (duration, tokens, cost).
- When adding a new topology, create a directory under `topologies/` and add an entry to `topologies/index.md`.
