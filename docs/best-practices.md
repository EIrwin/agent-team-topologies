---
title: Best Practices
parent: Guides
nav_order: 6
has_toc: true
---

# Best Practices

Operational guidance for running agent teams effectively.

## Context up front

Teammates do not share your conversation history. They start with `CLAUDE.md`, MCP servers, skills, and their spawn prompt -- nothing else.

Treat every spawn prompt as a self-contained brief:
- State the goal and why it matters
- List relevant file paths and line numbers
- Include decisions already made and constraints
- Specify the expected output format

If context is too large for a spawn prompt, write it to a file and reference the path.

{: .tip }
> **Good spawn prompt example:**
> ```text
> Trace the authentication flow starting from src/auth/login.ts:42.
> Map every function call from the POST /auth/login handler through
> to token generation in src/auth/tokens.ts.
> Deliver: ordered list of functions called, file paths, and any
> external service calls. Flag anything that looks like a security concern.
> ```

## Small, self-contained tasks

Target 5-6 tasks per teammate. Each task should:
- Have a single clear deliverable
- Be completable without waiting on other tasks (where possible)
- Touch a well-defined set of files (no overlapping file ownership)
- Include measurable completion criteria

Tasks that are too large lead to context exhaustion. Tasks that are too small create coordination overhead.

## Hooks as guardrails

{: .note }
> Use hooks to enforce standards without manual oversight. Hooks catch problems at the point of failure, not after synthesis.

**TaskCompleted** -- blocks task completion until checks pass:
```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "command": "bash -c 'cd $PROJECT_DIR && npm test && npm run lint'",
        "on_failure": "block"
      }
    ]
  }
}
```

**TeammateIdle** -- triggers action when a teammate stops working:
- Run a final test suite
- Produce a summary of work done
- Clean up temporary files
- Signal readiness for shutdown

A blocked task costs less to fix than a merged defect.

## Output discipline

{: .tip }
> Require structured output from teammates. Unstructured "stream of consciousness" findings are hard to synthesize and waste the lead's context window.

Good output formats:
- Bullet lists with severity/priority
- Tables (finding, file, severity, fix)
- Numbered steps for procedures
- Explicit "done" signals with summary

```text
# Task output template for reviewers
## Findings
| # | Severity | File | Line | Issue | Suggested Fix |
|---|----------|------|------|-------|---------------|

## Summary
- Must-fix: N
- Should-fix: N
- Total files reviewed: N
```

## Coordination levers

### Plan mode
Require a teammate to produce a plan before executing. The lead reviews and approves the plan before implementation begins. Use this for risky changes where the cost of a bad approach is high.

### Delegate mode
Restrict the lead to coordination only -- no direct code edits. Forces clean decomposition because the lead cannot "jump in" to fix things. Best for complex multi-worker topologies where the lead should focus on orchestration.

## Task dependency management

Use task dependencies to enforce ordering where required:
- "Contract" tasks (API shape, data model) should block implementation tasks
- Implementation tasks should block integration testing tasks
- Keep the dependency graph as flat as possible -- deep chains kill parallelism

Avoid circular dependencies. If tasks seem mutually dependent, restructure them or combine them into one task.

## When to use broadcast vs direct messages

**Direct message** (default): Use for anything relevant to only one teammate. Status checks, task clarifications, feedback on specific work, follow-up questions.

**Broadcast** (rare): Use only when every teammate needs the information simultaneously. Blocking issues, scope changes, shutdown announcements, or shared decisions that affect all workstreams.

Rule of thumb: if you're unsure, use a direct message. The cost of one unnecessary direct message is far less than the cost of one unnecessary broadcast (which sends N messages).

## Shutting down cleanly

When work is complete:
1. Verify all tasks are marked completed with passing criteria
2. Collect final outputs from each teammate
3. Send shutdown requests to all teammates
4. Wait for confirmation before considering the session done

Do not leave teammates running after their work is finished. Idle teammates burn tokens. Use `TeammateIdle` hooks to detect and act on idle workers automatically.

If a teammate rejects a shutdown request, check whether it has legitimate remaining work or is stuck. Stuck teammates should be shut down and their remaining tasks reassigned.
