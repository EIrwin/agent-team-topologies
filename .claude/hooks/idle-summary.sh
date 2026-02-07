#!/usr/bin/env bash
set -euo pipefail

# idle-summary.sh — Hook for TeammateIdle event
#
# This hook runs when a teammate agent goes idle.
# It checks that the agent has provided a structured summary before allowing idle.
#
# Exit codes:
#   0 — Summary is present and well-formed, idle is allowed
#   2 — Summary is missing or incomplete, idle is blocked (feedback message sent to agent)
#
# The hook reads the agent's last message from stdin (piped by the hook system).
# It checks for the presence of required sections in the summary.

# --- Required summary sections ---
REQUIRED_SECTIONS=("Findings" "Blockers" "Next Steps")

# --- Read the agent's last message from stdin or first argument ---
if [[ -n "${1:-}" ]]; then
  message="$1"
else
  message=$(cat /dev/stdin 2>/dev/null || echo "")
fi

# If no message content is available, block with guidance
if [[ -z "$message" ]]; then
  echo "IDLE BLOCKED: No summary provided."
  echo ""
  echo "Before going idle, provide a structured summary with these sections:"
  echo "  - Findings: What you discovered or accomplished"
  echo "  - Blockers: Any issues preventing progress (or 'None')"
  echo "  - Next Steps: What should happen next (or 'None remaining')"
  echo ""
  echo "Example:"
  echo "  ## Findings"
  echo "  - Explored the auth module and mapped 3 key flows"
  echo "  - Identified 2 potential security concerns"
  echo ""
  echo "  ## Blockers"
  echo "  - None"
  echo ""
  echo "  ## Next Steps"
  echo "  - Review the session management code in auth/session.ts"
  exit 2
fi

# --- Check for required sections ---
missing=()
for section in "${REQUIRED_SECTIONS[@]}"; do
  # Case-insensitive check for section headers (## Section, **Section**, Section:)
  if ! echo "$message" | grep -iqE "(^##\s*${section}|^\*\*${section}\*\*|^${section}\s*:)"; then
    missing+=("$section")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "IDLE BLOCKED: Summary is incomplete."
  echo ""
  echo "Missing sections: ${missing[*]}"
  echo ""
  echo "Your summary must include these sections:"
  for section in "${REQUIRED_SECTIONS[@]}"; do
    echo "  - $section"
  done
  echo ""
  echo "Use markdown headers (## Section) or bold labels (**Section:**) for each."
  exit 2
fi

echo "Summary verified. Idle allowed."
exit 0
