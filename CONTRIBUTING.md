# Contributing to Agent Team Topologies

Thank you for helping improve agent team patterns. This guide covers how to propose new topologies, submit examples, improve agent definitions, and get your changes merged.

## Proposing a new topology

Use the [New Topology Proposal](../../issues/new?template=new-topology.md) issue template. Your proposal **must** include:

- **Name and one-line description** -- what the pattern is called and what it does
- **When to use** -- specific scenarios where this topology fits
- **Why existing patterns don't fit** -- what gap this fills that the current 8 patterns miss
- **Proposed team shape** -- roles, count, and how they coordinate
- **A real example** -- an actual task you ran (or would run) with this pattern, including what happened and what you learned

Proposals without a real example or clear differentiation from existing patterns will be asked to revise before moving forward.

## Submitting examples

Examples are the most valuable contribution. Use the [Example Submission](../../issues/new?template=example-submission.md) issue template.

**Strict requirement: examples must be real walkthroughs, not templates or hypotheticals.**

Every example submission must include:

- **Which topology** the example demonstrates
- **Scenario** -- the real context (repo, task, constraints)
- **Setup** -- how the team was created, spawn prompts used
- **What happened** -- timestamped narrative of how work progressed
- **What went wrong** -- honest account of failures, retries, coordination issues
- **Results** -- concrete metrics: wall-clock duration, token usage, estimated cost
- **Retrospective** -- what you would do differently next time

Why so strict? Hypothetical examples teach the wrong lessons. Real walkthroughs -- including the messy parts -- are what help people decide whether a topology fits their situation.

## Improving agent definitions or hooks

Agent definitions live in `.claude/agents/` and hooks in `.claude/hooks/`. To contribute changes:

1. **Test locally first.** Run Claude Code with your modified agent or hook and verify the behavior end to end.
2. **Include before/after comparison.** Your PR should describe how the agent or hook behaved before your change and how it behaves after.
3. **Keep scope narrow.** One behavioral change per PR. Don't bundle unrelated improvements.

## Code of conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Be respectful, constructive, and assume good intent.

## PR process

1. **Fork** the repository
2. **Create a branch** from `main` (e.g., `add-topology-pair-programming` or `fix-explorer-agent-prompt`)
3. **Make your changes** following the guidelines above
4. **Open a PR** using the [pull request template](.github/PULL_REQUEST_TEMPLATE.md)
5. A maintainer will review your PR. Expect feedback -- most PRs go through at least one round of revision.

### What makes a good PR

- Follows the relevant template (topology card structure, example format)
- Links work (relative paths, issue references)
- Contains real content, not placeholder text
- Keeps changes focused -- one topology, one example, or one fix per PR
