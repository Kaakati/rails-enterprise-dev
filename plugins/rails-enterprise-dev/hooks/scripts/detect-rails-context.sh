#!/bin/bash
# Detect Rails development context and suggest workflow
set -euo pipefail

# Read hook input
input=$(cat)

# Extract user prompt
user_prompt=$(echo "$input" | jq -r '.user_prompt // ""')

# Quick exit if plugin not enabled
STATE_FILE=".claude/rails-enterprise-dev.local.md"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check if enabled
ENABLED=$(sed -n '/^---$/,/^---$/{ /^enabled:/p }' "$STATE_FILE" 2>/dev/null | sed 's/enabled: *//' | tr -d ' ')

if [ "$ENABLED" != "true" ]; then
  exit 0
fi

# Detect Rails-related keywords in prompt
if echo "$user_prompt" | grep -qiE 'model|controller|service|migration|rails|activerecord|component|view|route|api|sidekiq|turbo|stimulus'; then
  # Rails context detected - suggest workflow
  cat <<EOF
{
  "systemMessage": "💡 Rails development detected. Consider using /rails-dev workflow for:\n- Multi-agent orchestration\n- Automatic skill discovery\n- Beads task tracking\n- Quality gates\n- Incremental implementation\n\nUsage: /rails-dev [your request]",
  "suppressOutput": false
}
EOF
fi

exit 0
