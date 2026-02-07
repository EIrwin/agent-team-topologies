# Anti-Patterns

Eight failure modes that waste tokens, create conflicts, or produce garbage output.

---

## 1. Same-file edits

**What it looks like:** Two or more teammates are assigned tasks that require editing the same file. Both make changes. One overwrites the other, or merge conflicts arise.

**Why it fails:** Claude Code teammates operate in isolated contexts. They have no awareness of each other's in-progress edits. There is no automatic merge -- the last write wins or conflicts block progress.

**What to do instead:** Decompose tasks by file ownership. Each file should have exactly one owner. If two features touch the same file, either serialize them (task dependencies) or have one teammate own the file and accept changes via the task list.

---

## 2. Sequential dependencies

**What it looks like:** Teammate B cannot start until Teammate A finishes. Teammate C depends on B. You've created a serial pipeline with the overhead of parallel infrastructure.

**Why it fails:** Agent teams exist for parallelism. Sequential chains eliminate that benefit while adding coordination cost, token burn from idle teammates, and messaging overhead.

**What to do instead:** Restructure the decomposition to maximize parallelism. Use task dependencies only where truly required. If most tasks are sequential, use a single agent instead.

---

## 3. Vague spawn prompts

**What it looks like:**
```text
# Bad
Spawn a teammate to help with the auth system.

# Good
Spawn a teammate to:
1. Trace the login flow from POST /auth/login through to token generation
2. List all files involved and their roles
3. Identify where rate limiting is applied (or missing)
4. Deliver: 10-bullet summary + key file paths
```

**Why it fails:** Teammates start with zero conversation history. A vague prompt forces them to spend tokens exploring scope, guessing intent, and potentially doing irrelevant work. Anthropic explicitly recommends focused spawn prompts.

**What to do instead:** Include in every spawn prompt: (1) specific deliverable, (2) scope boundaries, (3) relevant file paths or modules, (4) output format.

---

## 4. Ignoring idle teammates

**What it looks like:** A teammate finishes its task but stays alive. Nobody shuts it down. It sits idle, occasionally responding to pings, burning tokens on context maintenance.

**Why it fails:** Each idle teammate is a running Claude Code instance consuming resources. Over a session, idle teammates can account for significant token waste.

**What to do instead:** Shut down teammates as soon as their work is done. Use `TeammateIdle` hooks to detect when a teammate stops producing useful output. Design tasks with clear completion criteria so "done" is unambiguous.

---

## 5. Broadcasting everything

**What it looks like:** The lead sends every status update, question, or finding as a broadcast to all teammates instead of direct messages to the relevant one.

**Why it fails:** Each broadcast sends a separate message to every teammate. With N teammates, that's N message deliveries -- each one consuming tokens in the recipient's context window. Most broadcasts are irrelevant to most recipients.

**What to do instead:** Default to direct messages (`type: "message"` with a specific `recipient`). Reserve broadcasts for genuinely team-wide information: blocking issues, major scope changes, or shutdown announcements.

---

## 6. Overlapping scopes

**What it looks like:** Two teammates are assigned "investigate the database layer" and "look into query performance." Both end up reading the same files, running the same queries, and producing overlapping findings.

**Why it fails:** Duplicated work means duplicated cost. Worse, the lead must reconcile two partial views of the same problem, which adds synthesis overhead.

**What to do instead:** Define non-overlapping scope boundaries before spawning. Use module boundaries, file boundaries, or question boundaries. If scopes must partially overlap, make one teammate the "owner" and the other a "consumer" of its findings.

---

## 7. No success criteria

**What it looks like:** A teammate is told to "improve test coverage" or "clean up the API module." It works for a while, produces some output, and marks the task done. The lead can't tell whether the work meets expectations.

**Why it fails:** Without explicit success criteria, teammates make their own judgment about "done." This often means stopping at a convenient point rather than at a meaningful one. Quality varies wildly.

**What to do instead:** Every task should include measurable completion criteria:
```text
# Bad
Improve test coverage for the auth module.

# Good
Add unit tests for auth module to cover:
- Login with valid credentials (happy path)
- Login with invalid password (returns 401)
- Token expiry handling (returns 403 + refresh hint)
- Rate limiting after 5 failed attempts (returns 429)
All tests must pass. Coverage for src/auth/ must reach 80%.
```

---

## 8. Assuming shared context

**What it looks like:** The lead has a long conversation establishing requirements, debugging an issue, or refining an approach. Then spawns a teammate with "fix the bug we discussed" or "implement the feature."

**Why it fails:** Teammates start with a blank context window. They get `CLAUDE.md`, MCP servers, and their spawn prompt -- nothing else. "The bug we discussed" is meaningless to them.

**What to do instead:** Treat spawn prompts as self-contained briefs. Include:
- What the problem/goal is
- Relevant file paths and line numbers
- Constraints and decisions already made
- Expected output format

If the context is too large for a spawn prompt, write it to a file and reference the file path in the prompt.
