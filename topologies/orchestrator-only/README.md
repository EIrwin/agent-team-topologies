---
title: Orchestrator-Only
parent: Topologies
nav_order: 6
---

# Orchestrator-Only
> The lead coordinates and delegates exclusively -- it never touches code.

## At a Glance
| Field | Value |
|-------|-------|
| Best For | Complex multi-workstream projects, large task decomposition, sustained parallel execution |
| Team Shape | Lead (delegate mode) + 2-5 Workers |
| Cost Profile | $$$$ -- high (many parallel workers + lead overhead) |
| Complexity | High |
| Parallelism | High |

## When to Use
- The project has many parallel workstreams that benefit from dedicated coordination
- You want the lead to focus purely on task breakdown, dependency management, and synthesis
- Lead "jumping in" to code would create context pollution or bottlenecks
- The work requires ongoing coordination across multiple agents over a longer session

## When NOT to Use
- The project is small enough that a single agent can handle it
- You need the lead to do implementation work (delegate mode prevents this)
- Cost is a primary concern -- this is the most expensive topology
- Work is mostly sequential and does not benefit from parallel workers

## How It Works
The lead operates in delegate mode, which restricts it to coordination tools only (spawn, message, shutdown, tasks). Workers self-claim unblocked tasks from the shared task list. The lead focuses on task decomposition, dependency graphs, resolving blockers, and synthesizing results.

```
          ┌──────┐
          │ Lead │     Delegate mode: coordinates only
          └──┬───┘
       ┌──┬──┼──┬──┐
       ▼  ▼  ▼  ▼  ▼
      ┌──┬──┬──┬──┐
      │D1│D2│D3│D4│   Workers self-claim tasks
      └──┴──┴──┴──┘   Lead never touches code
```

1. **Lead** decomposes the project into tasks with clear deliverables and dependencies
2. **Workers** self-claim unblocked tasks from the shared task list
3. **Lead** monitors progress, resolves blockers, and adjusts the task graph
4. **Lead** synthesizes results as workers complete their tasks

## Spawn Prompt
```text
Create an agent team for <goal>. I want the lead to focus on orchestration only.
Break work into 5-6 tasks per teammate with clear deliverables and dependencies.
Have teammates self-claim unblocked tasks; lead synthesizes progress and resolves blockers.
```

## Task Breakdown Strategy
The lead's primary job is creating a well-structured task graph:
- Break work into **5-6 tasks per teammate** with clear acceptance criteria
- Define explicit **dependency edges** between tasks (task B blocked by task A)
- Keep tasks **self-contained** -- a worker should be able to complete a task without asking the lead for clarification
- Use task descriptions as the primary communication channel (not messages)

## Configuration
- **Agents:** Use `worker.md` agent definitions; enable **delegate mode** on the lead to prevent it from coding
- **Hooks:** Use `TeammateIdle` hooks to reassign workers who finish early; keep broadcast messaging rare (it multiplies cost)
- **Team size:** 2-5 workers; the lead's coordination overhead grows with team size

## Variations
- **Rotating lead variant:** Workers can escalate to become temporary coordinators for sub-problems
- **Specialist variant:** Instead of generic workers, assign specialists (similar to Feature Pod but with more workers)
- **Phased variant:** Lead coordinates in waves -- first wave does research, second wave does implementation, third wave does testing

## Trade-offs
**Pros:**
- Lead stays focused on coordination, avoiding context pollution from implementation details
- Workers operate independently with clean context windows
- Scales to complex multi-workstream projects
- Self-claim prevents bottlenecks at the lead

**Cons:**
- Highest cost topology due to many parallel workers plus lead overhead
- Delegate mode means the lead cannot help with implementation, even for quick fixes
- Coordination overhead can dominate for small projects
- Workers may need more context in task descriptions since the lead cannot pair with them

## Related Patterns
- [Task Queue](../task-queue/) -- similar self-claim pattern but optimized for many small independent items
- [Feature Pod](../feature-pod/) -- when workers should be specialists rather than generalists
- [Quality-Gated](../quality-gated/) -- layer on to enforce completion standards for each worker's output
