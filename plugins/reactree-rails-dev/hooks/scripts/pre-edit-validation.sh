#!/bin/bash
# pre-edit-validation.sh
# PreToolUse hook: Validate before editing Ruby files
#
# Prevents breaking changes by validating syntax before edits are applied
# This hook runs BEFORE the Edit tool modifies files
#
# Environment Variables:
#   FILE_PATH: Path to file being edited
#   NEW_CONTENT: Proposed new content (may not be available in all contexts)

# NO set -e for hooks - graceful degradation

FILE_PATH="${FILE_PATH:-}"
NEW_CONTENT="${NEW_CONTENT:-}"

# Quick exit if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only validate Ruby files
if [[ ! "$FILE_PATH" =~ \.rb$ ]]; then
  exit 0
fi

echo "🔍 Pre-edit validation: $FILE_PATH"

# Quick syntax check on new content if available
if [ -n "$NEW_CONTENT" ]; then
  echo "Validating syntax of proposed changes..."

  # Create temp file for syntax check
  TEMP_FILE="/tmp/pre_edit_check_$$.rb"
  echo "$NEW_CONTENT" > "$TEMP_FILE"

  if ! ruby -c "$TEMP_FILE" 2>&1; then
    echo "❌ Syntax error in proposed changes"
    rm -f "$TEMP_FILE"
    exit 1  # Block edit
  fi

  rm -f "$TEMP_FILE"
  echo "✅ Syntax check passed"
fi

# Check if file has type annotations (for informational purposes)
if [ -f "$FILE_PATH" ] && grep -q "# typed:" "$FILE_PATH" 2>/dev/null; then
  echo "ℹ️  File has type annotations - Sorbet validation will run post-edit"
fi

# Allow edit to proceed
exit 0
