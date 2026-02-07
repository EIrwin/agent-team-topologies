# Hooks

Hooks are shell scripts that run in response to Claude Code agent lifecycle events. They act as guardrails, enforcing quality and process standards automatically.

## How Hooks Work

When certain events occur in a Claude Code session (like a task being completed or an agent going idle), the system can run a hook script. The script's exit code determines what happens next:

| Exit Code | Behavior |
|-----------|----------|
| `0` | **Allow** — the event proceeds normally |
| `2` | **Block with feedback** — the event is blocked and the script's stdout is sent back to the agent as feedback so it can correct the issue |
| Other | Treated as an error; behavior depends on configuration |

## Available Hooks

### quality-gate.sh (TaskCompleted)

Runs when an agent marks a task as completed. Verifies that tests and linting pass before allowing the completion.

**What it checks:**
- Runs the project's test suite
- Runs the project's linter

**Auto-detection:** The script automatically detects the right commands based on project files (package.json, Makefile, Cargo.toml, go.mod, pyproject.toml, etc.).

**Custom commands:** Override auto-detection with environment variables:
```bash
export QUALITY_GATE_TEST_CMD="pytest tests/ -x"
export QUALITY_GATE_LINT_CMD="ruff check src/"
```

**Skip a check:**
```bash
export QUALITY_GATE_SKIP_TESTS=true
export QUALITY_GATE_SKIP_LINT=true
```

### idle-summary.sh (TeammateIdle)

Runs when a teammate agent goes idle. Ensures the agent has provided a structured summary of its work before going idle.

**Required sections:**
- **Findings** — what the agent discovered or accomplished
- **Blockers** — issues preventing progress (or "None")
- **Next Steps** — what should happen next (or "None remaining")

## Installation

### 1. Make the scripts executable

```bash
chmod +x .claude/hooks/quality-gate.sh
chmod +x .claude/hooks/idle-summary.sh
```

### 2. Configure hooks in your Claude Code settings

Add hook entries to your `.claude/settings.local.json` or project settings:

```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "command": ".claude/hooks/quality-gate.sh",
        "description": "Run tests and linting before allowing task completion"
      }
    ],
    "TeammateIdle": [
      {
        "command": ".claude/hooks/idle-summary.sh",
        "description": "Require structured summary before allowing idle"
      }
    ]
  }
}
```

### 3. Customize for your project

Set environment variables in your shell or in the hook configuration to override the auto-detected commands:

```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "command": "QUALITY_GATE_TEST_CMD='npm test -- --coverage' QUALITY_GATE_LINT_CMD='npm run lint' .claude/hooks/quality-gate.sh",
        "description": "Quality gate with custom commands"
      }
    ]
  }
}
```

## Writing Custom Hooks

To create your own hooks:

1. Create a bash script in `.claude/hooks/`
2. Start with `#!/usr/bin/env bash` and `set -euo pipefail`
3. Exit `0` to allow the event
4. Exit `2` and print feedback to stdout to block the event
5. Make the script executable: `chmod +x .claude/hooks/your-hook.sh`
6. Register it in settings under the appropriate event

## Supported Events

| Event | When it fires |
|-------|--------------|
| `TaskCompleted` | An agent marks a task as done |
| `TeammateIdle` | A teammate agent goes idle |

Refer to the Claude Code documentation for the full list of available hook events.
