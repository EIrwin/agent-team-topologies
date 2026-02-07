---
title: "Example: Rubocop Violations"
parent: Task Queue
grand_parent: Topologies
nav_order: 1
---

# Task Queue: Clearing 47 Rubocop Violations After Upgrade

## Scenario
A Rails 7 application called ShipTrack just upgraded Rubocop from 1.50 to 1.68. The upgrade introduced 47 new violations across the codebase. Each violation is isolated to a single file, has a clear auto-correctable or manually-fixable pattern, and does not depend on any other fix. The violations break down as:
- 18x `Style/StringLiterals` (double quotes to single quotes)
- 12x `Layout/LineLength` (lines exceeding 120 characters)
- 9x `Naming/MethodParameterName` (single-letter parameter names)
- 5x `Style/FrozenStringLiteralComment` (missing magic comment)
- 3x `Lint/UnusedMethodArgument` (unused arguments in method signatures)

The CI pipeline is red because the team enforces zero Rubocop violations. Every violation is in a different file. The team wants these fixed fast without tying up a developer for an hour of mechanical edits.

## Why This Topology
This is the ideal Task Queue scenario: many independent, self-contained work items of similar size and complexity. No task depends on any other. Workers are interchangeable -- any worker can fix any violation type. A Feature Pod would be overkill (there are no layers). Parallel Explorers is wrong (there is nothing to discover). The Task Queue maximizes throughput by letting workers self-claim and churn through the backlog.

## Setup

### Team Creation
```text
Create an agent team to fix 47 Rubocop violations from our upgrade to 1.68.
Spawn 5 worker agents. For each violation, I've listed the file path, line
number, cop name, and the current offending code.

Workers should:
1. Self-claim the next available task
2. Fix the violation in the specified file
3. Run `rubocop <file_path>` on that specific file to verify the fix
4. Mark the task complete and claim the next one

Here are the violations:
[... 47 tasks listed with file path, line number, cop name, and offending code ...]
```

### Task Breakdown (sample of 47)

| # | File | Cop | Description |
|---|------|-----|-------------|
| 1 | `app/models/user.rb:14` | `Style/StringLiterals` | Double quotes to single quotes |
| 2 | `app/models/user.rb:28` | `Layout/LineLength` | Line exceeds 120 chars |
| 3 | `app/controllers/shipments_controller.rb:45` | `Naming/MethodParameterName` | Parameter `e` should be descriptive |
| 4 | `app/services/tracking/parser.rb:1` | `Style/FrozenStringLiteralComment` | Missing frozen string literal comment |
| 5 | `app/models/shipment.rb:67` | `Lint/UnusedMethodArgument` | Unused argument `options` |
| ... | ... | ... | ... |
| 47 | `lib/tasks/cleanup.rake:12` | `Style/StringLiterals` | Double quotes to single quotes |

## What Happened

### [0:00] Lead creates the task backlog
The lead parsed the Rubocop output and created 47 tasks in the shared task list, each with:
- File path and line number
- Cop name and violation message
- The current offending line of code
- Acceptance criteria: "Rubocop passes on this file after the fix"

All 47 tasks were created as independent (no dependencies). Five workers were spawned and immediately began self-claiming tasks.

### [0:01] Workers start churning
Workers self-claimed tasks from the queue within seconds. The `Style/StringLiterals` fixes were the fastest -- most were single-character changes:

> **Worker 1:** "Task #1 complete. `app/models/user.rb:14`: changed `"active"` to `'active'`. Rubocop passes on `user.rb`."

> **Worker 3:** "Task #4 complete. `app/services/tracking/parser.rb`: added `# frozen_string_literal: true` at line 1. Rubocop passes."

Workers averaged one fix every 12-15 seconds for the simple string literal and frozen comment violations.

### [0:05] Harder violations take longer
The `Layout/LineLength` violations required more judgment -- splitting long lines while maintaining readability. The `Naming/MethodParameterName` violations required understanding the method's purpose to choose a good name:

> **Worker 2:** "Task #3 complete. `app/controllers/shipments_controller.rb:45`: renamed parameter `e` to `error` in the `rescue` block. Verified the parameter is used on lines 46 and 48. Rubocop passes."

> **Worker 4:** "Task #12 complete. `app/services/billing/invoice_generator.rb:89`: split the long method chain across 3 lines using backslash continuation. Rubocop passes."

These took 30-45 seconds each instead of 12-15.

### [0:09] The duplicate claim incident
Workers 2 and 5 both claimed Task #23 at nearly the same time. Worker 2 got there first, fixed the violation in `app/helpers/date_helper.rb`, and marked it complete. Worker 5, which had also started reading the file, made the same fix and attempted to mark it complete -- but found it was already done.

Worker 5's changes overwrote Worker 2's identical fix (same change, so no harm in this case), but the lead noticed the task list showed Task #23 completed twice:

> **Lead:** "Task #23 was claimed by both Worker 2 and Worker 5. The fix was identical so no damage, but this is a race condition in task claiming. Worker 5, please check the task status before starting work. Reassigning Worker 5 to Task #31 which is still unclaimed."

The lead added a note to the remaining workers:

> **Lead (to all workers):** "Before starting a fix, verify your claimed task is still in `in_progress` status and assigned to you. If another worker already completed it, skip and claim the next one."

### [0:15] Workers hit a steady rhythm
After the duplicate claim was resolved, workers settled into a consistent pattern. At any given moment, 5 violations were being fixed in parallel. The task list showed a steady stream of completions:

```
[0:15] Worker 1: Task #28 complete (StringLiterals)
[0:15] Worker 3: Task #29 complete (FrozenStringLiteralComment)
[0:15] Worker 4: Task #30 complete (LineLength)
[0:16] Worker 2: Task #32 complete (StringLiterals)
[0:16] Worker 5: Task #31 complete (MethodParameterName)
```

### [0:22] Final stretch
The last few tasks were the `Lint/UnusedMethodArgument` violations, which were the most nuanced. Workers needed to determine whether to prefix with underscore or remove the argument entirely:

> **Worker 3:** "Task #45 complete. `app/services/export/csv_builder.rb:34`: the `format` argument is passed by the caller but never used in the method body. Prefixed with underscore: `_format`. Did not remove it because removing it would break the 3 callers. Rubocop passes."

### [0:25] Lead runs final verification
With all 47 tasks complete, the lead ran a full Rubocop sweep across the entire codebase:

> **Lead:** "Running `rubocop` across the full project... 0 offenses detected. All 47 violations resolved. Running the test suite to verify no regressions... 1,847 tests, 0 failures, 0 errors. CI should be green."

## What Went Wrong
**The duplicate claim on Task #23** was the only real problem. Two workers started the same task within a one-second window. In this case, the fix was identical so no code was lost, but if the violation had required a judgment call (like naming a parameter), two workers could have made different choices and one's work would have been silently overwritten.

The root cause is that the self-claim mechanism uses file locking, which prevents simultaneous writes to the task list, but there is a small window between reading the task status and claiming it. With 5 workers on 47 tasks, this race condition surfaced once. The lead mitigated it by instructing workers to double-check task ownership after claiming.

**Minor inefficiency:** The workers did not prioritize by violation type. If all `Style/StringLiterals` tasks had been claimed first (fastest fixes), the queue would have cleared faster overall. Instead, workers claimed tasks in ID order, mixing fast and slow fixes. This is a minor optimization -- the time difference is maybe 2 minutes.

## Results

| Metric | Value |
|--------|-------|
| Duration | 25 minutes |
| Token Cost | ~$4.50 |
| Key Deliverables | 47 Rubocop violations fixed, 0 regressions, CI green |
| Throughput | ~1.9 fixes per minute across the team |

## Retrospective
- **What worked:** The Task Queue pattern was a perfect fit. 47 independent, similar-sized tasks spread across 5 workers with minimal coordination. The total time was about 5x faster than a single agent doing them sequentially, and the work required no human judgment except for the unused argument violations.
- **What didn't:** The duplicate claim race condition is a known limitation of the self-claim pattern. With more workers or fewer tasks, the probability increases. The lead's intervention (instructing workers to verify ownership) was a reasonable mitigation but not a guarantee.
- **Would use again?** Yes, for any bulk-fix scenario: linting violations, dependency version bumps across many files, standardizing import patterns, migrating deprecated API calls. The pattern shines when tasks are independent and verifiable.
- **Tip:** For Rubocop-style fixes, consider pre-sorting tasks by estimated complexity. Put the mechanical fixes (string literals, frozen comments) first and the judgment-requiring fixes (naming, line length) last. This front-loads throughput and leaves the harder tasks for when workers have warmed up. Also, consider using `rubocop --auto-correct-all` for the trivially auto-fixable cops first, then use the Task Queue only for violations that require human-like judgment.
