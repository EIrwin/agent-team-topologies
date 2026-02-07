---
title: Feature Pod
parent: Topologies
has_children: true
nav_order: 4
---

# Feature Pod
> Cross-layer feature delivery with dedicated owners per stack layer, coordinated by contract.

## At a Glance
| Field | Value |
|-------|-------|
| Best For | End-to-end feature implementation spanning frontend, backend, and tests |
| Team Shape | Lead (orchestrator) + Frontend + Backend + QA |
| Cost Profile | $$$ -- higher (multiple writers, longer sessions) |
| Complexity | Medium |
| Parallelism | High |

## When to Use
- A feature spans multiple layers (UI, API, database, tests)
- Each layer can be owned independently with a clear interface contract
- You want parallel implementation across the stack
- The feature is well-defined enough to specify acceptance criteria up front

## When NOT to Use
- The feature is confined to a single layer -- just use a single agent
- Multiple layers must edit the same files -- this creates merge conflicts
- Requirements are too vague to define a contract up front -- use Parallel Explorers first

## How It Works
The team starts by defining a contract: API shape, data payloads, and acceptance criteria. Once the contract is agreed, each layer owner implements their portion in parallel, working against the shared contract. The lead coordinates integration and final verification.

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

1. **Lead** creates a "contract" task defining the API shape, payloads, and acceptance criteria
2. All teammates agree on the contract before proceeding
3. **Frontend**, **Backend**, and **QA** implement in parallel against the shared contract
4. **Lead** coordinates integration and runs final verification

## Spawn Prompt
```text
Create an agent team to implement <feature>.
Spawn:
- Frontend teammate: UI + state + integration points
- Backend teammate: API + data model + validations
- QA teammate: tests, edge cases, verification script
First task: define the contract (API, payloads, acceptance criteria).
Then parallelize implementation by layer and reconverge for final verification.
```

## Task Breakdown Strategy
Use a **contract-first, then parallelize** approach:
1. **Contract task** (blocking): Define API endpoints, request/response shapes, error codes, acceptance criteria
2. **Layer tasks** (parallel): Each owner implements their layer against the contract
3. **Integration task** (blocking): Wire layers together and verify end-to-end
4. **Verification task**: Run full test suite and validate acceptance criteria

Keep 5-6 tasks per teammate to stay productive and reassignable. Avoid same-file edits across teammates.

## Configuration
- **Agents:** Use layer-specific agent definitions (`frontend.md`, `backend.md`, `qa.md`) with ownership boundaries
- **Hooks:** Use `TaskCompleted` hooks to enforce that tests pass and lint is clean before marking layer work done
- **Team size:** 3-4 is ideal (FE + BE + QA + optional infra); more layers increase coordination overhead

## Variations
- **Full-stack variant:** Two full-stack developers split by feature area instead of layer
- **Contract-only variant:** Lead defines the contract, then a single agent implements all layers sequentially
- **Review-integrated variant:** Combine with Review Board -- the pod builds, then reviewers inspect each layer

## Trade-offs
**Pros:**
- High parallelism across stack layers
- Clear ownership boundaries reduce file conflicts
- Contract-first approach catches integration issues early
- Each teammate gets a focused context window for their layer

**Cons:**
- Requires well-defined contracts before parallelization begins
- Integration step can surface mismatches that require rework
- Higher cost than single-agent implementation
- Not suitable when layers are tightly coupled or share files

## Related Patterns
- [Review Board](../review-board/) -- add post-implementation review from specialist lenses
- [Quality-Gated](../quality-gated/) -- layer on to enforce per-layer completion standards
- [Task Queue](../task-queue/) -- when the work is many independent items rather than layered
