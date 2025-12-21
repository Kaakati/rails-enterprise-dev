#!/bin/bash
# Track progress in beads when files are modified
set -e

# Read hook input
input=$(cat)

# Check if workflow active
STATE_FILE=".claude/rails-enterprise-dev.local.md"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Extract feature ID and current phase
FEATURE_ID=$(sed -n '/^---$/,/^---$/{ /^feature_id:/p }' "$STATE_FILE" 2>/dev/null | sed 's/feature_id: *//' | tr -d ' ')
PHASE=$(sed -n '/^---$/,/^---$/{ /^workflow_phase:/p }' "$STATE_FILE" 2>/dev/null | sed 's/workflow_phase: *//' | tr -d ' ')

# Exit if no active feature
if [ -z "$FEATURE_ID" ] || [ "$FEATURE_ID" = "null" ] || [ "$FEATURE_ID" = "none" ]; then
  exit 0
fi

# Check if beads available
if ! command -v bd &> /dev/null; then
  exit 0
fi

# Get tool info from input
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
tool_input=$(echo "$input" | jq -r '.tool_input // {}')

# Track file creation/modification
if [ "$tool_name" = "Write" ] || [ "$tool_name" = "Edit" ]; then
  file_path=$(echo "$tool_input" | jq -r '.file_path // ""')

  if [ -n "$file_path" ]; then
    # Add comment to beads issue about file change
    bd comment "$FEATURE_ID" "[$PHASE] Modified: $file_path" 2>/dev/null || true
  fi
fi

exit 0
