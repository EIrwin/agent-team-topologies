#!/usr/bin/env bash
set -euo pipefail

# quality-gate.sh — Hook for TaskCompleted event
#
# This hook runs when an agent marks a task as completed.
# It verifies that tests and linting pass before allowing the completion.
#
# Exit codes:
#   0 — All checks pass, task completion is allowed
#   2 — A check failed, task completion is blocked (feedback message sent to agent)
#
# Configuration:
#   Set these environment variables to customize the commands:
#     QUALITY_GATE_TEST_CMD  — command to run tests  (default: auto-detected)
#     QUALITY_GATE_LINT_CMD  — command to run linting (default: auto-detected)
#     QUALITY_GATE_SKIP_TESTS — set to "true" to skip test check
#     QUALITY_GATE_SKIP_LINT  — set to "true" to skip lint check

# --- Auto-detect test command ---
detect_test_cmd() {
  if [[ -n "${QUALITY_GATE_TEST_CMD:-}" ]]; then
    echo "$QUALITY_GATE_TEST_CMD"
    return
  fi

  if [[ -f "package.json" ]]; then
    echo "npm test"
  elif [[ -f "Makefile" ]] && grep -q "^test:" Makefile; then
    echo "make test"
  elif [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.cfg" ]]; then
    echo "python -m pytest"
  elif [[ -f "Cargo.toml" ]]; then
    echo "cargo test"
  elif [[ -f "go.mod" ]]; then
    echo "go test ./..."
  else
    echo ""
  fi
}

# --- Auto-detect lint command ---
detect_lint_cmd() {
  if [[ -n "${QUALITY_GATE_LINT_CMD:-}" ]]; then
    echo "$QUALITY_GATE_LINT_CMD"
    return
  fi

  if [[ -f "package.json" ]]; then
    # Check if lint script exists in package.json
    if grep -q '"lint"' package.json 2>/dev/null; then
      echo "npm run lint"
    elif command -v npx &>/dev/null && [[ -f ".eslintrc" || -f ".eslintrc.js" || -f ".eslintrc.json" || -f ".eslintrc.yml" ]]; then
      echo "npx eslint ."
    else
      echo ""
    fi
  elif [[ -f "pyproject.toml" ]] && grep -q "ruff" pyproject.toml 2>/dev/null; then
    echo "ruff check ."
  elif command -v flake8 &>/dev/null && [[ -f "setup.cfg" || -f ".flake8" ]]; then
    echo "flake8"
  elif [[ -f "Cargo.toml" ]]; then
    echo "cargo clippy"
  elif [[ -f "go.mod" ]]; then
    echo "golangci-lint run"
  else
    echo ""
  fi
}

# --- Run checks ---
failed=0
feedback=""

# Test check
if [[ "${QUALITY_GATE_SKIP_TESTS:-false}" != "true" ]]; then
  test_cmd=$(detect_test_cmd)
  if [[ -n "$test_cmd" ]]; then
    echo "Running tests: $test_cmd"
    if ! eval "$test_cmd" 2>&1; then
      failed=1
      feedback+="Tests failed. Run '$test_cmd' and fix failures before completing the task.\n"
    else
      echo "Tests passed."
    fi
  else
    echo "No test command detected. Skipping test check."
  fi
fi

# Lint check
if [[ "${QUALITY_GATE_SKIP_LINT:-false}" != "true" ]]; then
  lint_cmd=$(detect_lint_cmd)
  if [[ -n "$lint_cmd" ]]; then
    echo "Running linting: $lint_cmd"
    if ! eval "$lint_cmd" 2>&1; then
      failed=1
      feedback+="Linting failed. Run '$lint_cmd' and fix issues before completing the task.\n"
    else
      echo "Linting passed."
    fi
  else
    echo "No lint command detected. Skipping lint check."
  fi
fi

# --- Report result ---
if [[ $failed -ne 0 ]]; then
  echo ""
  echo "QUALITY GATE FAILED:"
  echo -e "$feedback"
  exit 2
fi

echo "All quality checks passed."
exit 0
