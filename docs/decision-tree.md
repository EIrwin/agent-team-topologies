---
title: Decision Tree
parent: Guides
nav_order: 2
---

# Decision Tree: Choosing a Topology

Use this tree to pick the right agent team topology for your task.

## The tree

```mermaid
flowchart TD
    Start{What are you<br/>trying to do?}

    Understand[UNDERSTAND<br/>explore, investigate, map]
    Build[BUILD<br/>implement, deliver]
    Review[REVIEW<br/>audit, critique, validate]
    Change[CHANGE something risky<br/>refactor, migrate, security]

    Start --> Understand
    Start --> Build
    Start --> Review
    Start --> Change

    Q1{One focused<br/>question?}
    Q2{Multiple independent<br/>questions?}
    Q3{Ambiguous bug?}

    Understand --> Q1
    Understand --> Q2
    Understand --> Q3

    Q1 -->|yes| Sub1[Subagent<br/>burst lookup]
    Q2 -->|yes| A[A: Parallel Explorers]
    Q3 -->|yes| C[C: Competing Hypotheses]

    Q4{Split by<br/>layer/component?}
    Q5{Large backlog of<br/>small items?}
    Q6{Lead should only<br/>coordinate?}

    Build --> Q4
    Build --> Q5
    Build --> Q6

    Q4 -->|yes, different files| D[D: Feature Pod]
    Q5 -->|yes| H[H: Task Queue]
    Q6 -->|yes| F[F: Orchestrator-Only]

    Q7{Multiple review<br/>perspectives?}

    Review --> Q7
    Q7 -->|yes| B[B: Review Board]
    Q7 -->|no| Sub2[Subagent with<br/>focused checklist]

    Q8{Expensive to<br/>get wrong?}

    Change --> Q8
    Q8 -->|yes| E[E: Risky Refactor]
    Q8 -->|no| Std[Standard topology<br/>for work shape]
```

## Pattern G: Quality-Gated Delivery (composable overlay)

Pattern G is not a standalone topology -- it layers on top of any other pattern. Apply it when you need enforced "Definition of Done" criteria.

```mermaid
graph LR
    Any[Any Topology<br/>A through F, or H]
    QG{Quality gates<br/>needed?}
    TC[TaskCompleted hook<br/>blocks until criteria pass]
    TI[TeammateIdle hook<br/>triggers action on idle]
    Any --> QG
    QG --> TC
    QG --> TI
```

**When to overlay Pattern G:**
- Teammates tend to mark tasks "done" prematurely
- You need automated checks before accepting work
- The cost of rework exceeds the cost of the gate

**Hook example:**

```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "command": "bash -c 'cd $PROJECT_DIR && npm test'",
        "on_failure": "block"
      }
    ]
  }
}
```

## Decision factors at each node

### Independence test
The most important filter. If tasks require constant back-and-forth or touch the same files, agent teams create more problems than they solve. Restructure the decomposition until workers can operate independently.

### Context budget test
Large codebases, verbose logs, and multi-module exploration can exhaust a single context window. Agent teams give each worker its own full context. Subagents are cheaper but return only summaries.

### Risk level
High-risk changes (security, data migrations, core architecture) benefit from independent review and plan-before-execute workflows. Pattern E (Risky Refactor) enforces plan approval before any code changes happen.

## Common combinations

| Scenario | Primary | Overlay |
|---|---|---|
| Ship a full-stack feature with quality checks | D (Feature Pod) | + G (Quality-Gated) |
| Investigate a production bug then fix it | C (Hypotheses) then D (Pod) | + G |
| Review a large PR from multiple angles | B (Review Board) | -- |
| Process 50 small migration tasks | H (Task Queue) | + G |
| Explore unfamiliar codebase before planning | A (Explorers) | -- |
