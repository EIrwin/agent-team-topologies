---
title: Cost Guide
parent: Guides
nav_order: 4
---

# Cost Guide

Agent teams can use ~7x more tokens than standard single-agent sessions. This guide helps you estimate, control, and justify that cost.

## Cost profile by topology

| Topology | Cost | Why |
|---|---|---|
| A. Parallel Explorers | $$ | 2-4 short-lived workers, read-only, no coordination overhead |
| B. Review Board | $$ | Small team, focused review scope, structured output |
| C. Competing Hypotheses | $$$ | Multiple solvers doing deep investigation + reconciliation |
| D. Feature Pod | $$$ | 3-4 workers with sustained execution + coordination |
| E. Risky Refactor | $$ | Small team, plan approval gate prevents wasted execution |
| F. Orchestrator-Only | $$$$ | Lead + multiple workers; lead overhead is pure coordination cost |
| G. Quality-Gated | + (additive) | Hooks add cost per gate check; overlays on base topology cost |
| H. Task Queue | $$$$ | Many workers over extended period; highest total token burn |

**Legend:** $ = ~1x single agent, $$ = ~2-3x, $$$ = ~4-5x, $$$$ = ~6-7x+

## 8 cost reduction strategies

### 1. Keep teams small
Every teammate is a full Claude Code instance. 2-3 focused workers almost always outperform 5-6 generalists. Start with the minimum viable team and add only if bottlenecked.

### 2. Use Sonnet for teammates
Reserve Opus for the lead (coordination, synthesis, judgment). Use Sonnet for workers doing execution tasks (implementation, testing, file scanning). The cost difference is significant at team scale.

### 3. Write focused spawn prompts
Vague prompts waste tokens on exploration. Include: specific deliverable, scope boundaries, relevant file paths, output format. A 200-token prompt that eliminates 2000 tokens of wandering is a good trade.

### 4. Shut down idle teammates
Use `TeammateIdle` hooks or manual shutdown. An idle teammate sitting in context burns tokens on every interaction cycle. Shut them down the moment their work is complete.

### 5. Avoid broadcasts
Each broadcast sends a separate message to every teammate. With 4 teammates, one broadcast = 4 message deliveries. Default to direct messages; broadcast only for blocking issues.

### 6. Scope tasks tightly
5-6 small, well-defined tasks per teammate. Each task should have clear inputs, outputs, and completion criteria. This prevents scope creep and makes it obvious when a teammate is done.

### 7. Use subagents for burst work
Not everything needs a full teammate. For one-shot lookups, verbose log analysis, or "find and summarize" tasks, a subagent is cheaper -- it runs, returns a summary, and costs a fraction of a sustained teammate.

### 8. Quality gates prevent rework
A `TaskCompleted` hook that runs tests adds a small per-task cost but prevents the much larger cost of discovering broken work later and re-running the entire task.

## When to stop using agent teams

Agent teams are not always the right tool. Stop using them when:

**Tasks are fundamentally sequential.** If each step depends on the previous step's output, you're paying for parallel infrastructure but executing serially. Use a single agent with subagent calls for isolation where needed.

**Cost exceeds value.** If a task takes a single agent 5 minutes and an agent team 2 minutes but costs 5x more, the math doesn't work unless you're time-constrained or the task is on a critical path.

**Single agent is sufficient.** If the work fits in one context window, doesn't benefit from multiple perspectives, and doesn't need parallel execution, a single agent is simpler, cheaper, and easier to debug.

**You're fighting coordination overhead.** If you spend more time managing task dependencies, resolving file conflicts, and synthesizing teammate output than the teammates save you, the topology is wrong for the task.

## Quick cost estimation

Before spawning a team, estimate:

```
Total cost ~ (number of teammates + 1) x (average task tokens) x (tasks per teammate)
```

Compare against the single-agent alternative:

```
Single agent cost ~ (total tasks) x (average task tokens)
```

If the team cost is more than 3x the single-agent cost, make sure the parallelism or quality benefits justify the premium.
