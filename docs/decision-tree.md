# Decision Tree: Choosing a Topology

Use this tree to pick the right agent team topology for your task.

## The tree

```
What are you trying to do?
│
├─ UNDERSTAND something (explore, investigate, map)
│  │
│  ├─ One focused question?
│  │  └─ Subagent (burst lookup + summarize back)
│  │
│  ├─ Multiple independent questions or modules?
│  │  └─ Pattern A: Parallel Explorers
│  │     2-4 explorers, each with a module/question boundary
│  │
│  └─ Ambiguous bug or unclear root cause?
│     └─ Pattern C: Competing Hypotheses
│        2+ solvers propose theories, critic/lead reconciles
│
├─ BUILD something (implement, deliver)
│  │
│  ├─ Can work be split by layer/component?
│  │  │
│  │  │  Independence test: Will workers edit different files?
│  │  │  ├─ YES --> Pattern D: Feature Pod
│  │  │  │         FE + BE + QA workers, contract task first
│  │  │  └─ NO  --> Rethink decomposition or use single agent
│  │  │
│  │  └─ Is there a large backlog of small independent items?
│  │     └─ Pattern H: Task Queue
│  │        3-8 workers self-claiming from shared task list
│  │
│  └─ Should lead only coordinate (not implement)?
│     └─ Pattern F: Orchestrator-Only (delegate mode)
│        Lead restricted to coordination; workers execute
│
├─ REVIEW something (audit, critique, validate)
│  │
│  ├─ Need multiple review perspectives?
│  │  └─ Pattern B: Review Board
│  │     Security + perf + correctness reviewers in parallel
│  │
│  └─ Single-lens review?
│     └─ Subagent with a focused checklist
│
└─ CHANGE something risky (refactor, migrate, security)
   │
   ├─ Context budget test: Will analysis exceed one context?
   │  ├─ YES --> Agent team (separate context per worker)
   │  └─ NO  --> Single agent may suffice
   │
   └─ Risk test: Is this expensive to get wrong?
      ├─ YES --> Pattern E: Risky Refactor
      │         Plan mode + approval gate before execution
      └─ NO  --> Standard topology for the work shape
```

## Pattern G: Quality-Gated Delivery (composable overlay)

Pattern G is not a standalone topology -- it layers on top of any other pattern. Apply it when you need enforced "Definition of Done" criteria.

```
Any topology (A through F, or H)
  + Quality gates needed?
    │
    ├─ TaskCompleted hook
    │  Blocks task completion until criteria pass
    │  (tests green, lint clean, docs updated)
    │
    └─ TeammateIdle hook
       Triggers action when a teammate stops working
       (run tests, summarize findings, open PR)
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
