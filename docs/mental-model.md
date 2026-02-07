---
title: Mental Model
parent: Guides
nav_order: 1
---

# Mental Model: Agent Teams in Claude Code

## What agent teams are

An **agent team** is multiple Claude Code instances working on a **shared task list**, where each teammate has its own isolated context window. Teammates do not inherit your main conversation history -- they start with the same project context (`CLAUDE.md`, MCP servers, skills), but anything you want them to know must be in the spawn prompt or assigned task.

Permission requests from teammates route back to the lead (you). Token cost scales fast because each teammate is its own instance.

## Context isolation

Every teammate operates in a **separate context window**. This means:

- Teammates cannot see what you discussed before spawning them
- Teammates cannot see each other's conversations unless they explicitly message
- The shared task list is the primary coordination mechanism
- Spawn prompts are the only way to pass initial context

This isolation is a feature, not a bug. It prevents context pollution and lets each worker focus deeply on its own scope.

## Agent teams vs subagents

| | Subagents | Agent teams |
|---|---|---|
| **Model** | Burst parallelism + summarize back | Longer-running parallel workers with separate contexts |
| **Context** | Share the parent's context window (output summarized back) | Each gets its own full context window |
| **Lifetime** | Short-lived, single task | Sustained, can work across multiple tasks |
| **Cost** | Lower (results compressed into parent context) | Higher (each teammate is a full instance) |
| **Coordination** | None needed (fire and forget) | Shared task list, messaging, dependencies |
| **Best for** | Verbose output isolation, self-contained lookups | Parallel workstreams, multi-step tasks, cross-cutting work |

**Use agent teams when:**
- You need sustained parallel workstreams
- Work would exceed a single context window
- You can decompose into tasks with clear boundaries

**Use subagents when:**
- You want isolation for verbose output + a summary back
- The work is self-contained and doesn't need shared state
- You want burst parallelism without coordination overhead

## Four selection heuristics

Before picking a topology, run through these tests:

### 1. Independence test (the biggest selector)

Agent teams shine when tasks can be made **independent** -- minimal back-and-forth dependencies. Parallel work can create file conflicts, so design tasks to avoid stepping on the same files.

If tasks are inherently sequential, agent teams add overhead without benefit.

### 2. Context budget test

If you expect huge logs, lots of repo scanning, or multi-module exploration:
- **Subagents** help keep verbose output out of the main context
- **Agent teams** give each worker its own window (but cost more)

If the work fits comfortably in one context window, you probably don't need either.

### 3. Risk / correctness test

If the task is one-shot and expensive to get wrong (security changes, migrations, core architecture), prefer a topology that includes **independent review/critique** and/or **quality gates** via hooks. Hooks can block a teammate from going idle or block a task from completing until criteria are met.

### 4. Cost test

Agent teams can use ~7x more tokens than standard sessions. Mitigate with:
- Small teams (2-4 teammates)
- Sonnet for teammates (not Opus)
- Focused spawn prompts
- Shut down idle teammates promptly

## Quick chooser

```
Can the work be parallelized into independent chunks?
  NO  --> Single agent or subagent
  YES --> How long will each chunk take?
            Short (< 1 turn) --> Subagents (burst parallelism)
            Long (multi-turn) --> Agent teams
              --> Does it need review/safety gates?
                    YES --> Add quality-gated hooks
                    NO  --> Pick topology by work shape
```
