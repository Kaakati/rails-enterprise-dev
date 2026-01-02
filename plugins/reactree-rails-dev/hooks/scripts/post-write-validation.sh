#!/bin/bash
# post-write-validation.sh
# PostToolUse hook: Validate after writing Ruby files
#
# Provides immediate feedback after file writes
# This hook runs AFTER the Write tool creates/modifies files
#
# Environment Variables:
#   FILE_PATH: Path to file that was written

# NO set -e for hooks - graceful degradation

FILE_PATH="${FILE_PATH:-}"

# Quick exit if no file path or file doesn't exist
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Only validate Ruby files
if [[ ! "$FILE_PATH" =~ \.rb$ ]]; then
  exit 0
fi

echo "🔍 Post-write validation: $FILE_PATH"

# Syntax check (always run - fast and critical)
if ! ruby -c "$FILE_PATH" &>/dev/null; then
  echo "❌ Syntax error in $FILE_PATH"
  ruby -c "$FILE_PATH" 2>&1
  exit 2  # Warning - file already written, can't block
fi

echo "✅ Syntax check passed"

# Rubocop quick check (only critical errors)
if command -v rubocop &>/dev/null; then
  echo "Running Rubocop..."
  if ! rubocop --fail-level error --format simple "$FILE_PATH" 2>&1; then
    echo "⚠️  Rubocop errors found (non-blocking)"
    # Exit 0 - don't block on rubocop issues, just inform
  else
    echo "✅ Rubocop passed"
  fi
fi

# Sorbet check if file has type annotations
if grep -q "# typed:" "$FILE_PATH" 2>/dev/null; then
  echo "File has type annotations, checking with Sorbet..."

  if command -v srb &>/dev/null || bundle exec srb --version &>/dev/null 2>&1; then
    # Run Sorbet on just this file
    if bundle exec srb tc "$FILE_PATH" 2>&1 | head -10; then
      echo "✅ Sorbet validation passed"
    else
      echo "⚠️  Sorbet type errors found (see above)"
      # Exit 0 - informational only, don't block
    fi
  else
    echo "ℹ️  Sorbet not available, skipping type check"
  fi
fi

echo "✅ $FILE_PATH validated"
exit 0
