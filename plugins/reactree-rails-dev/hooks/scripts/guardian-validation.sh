#!/bin/bash
# guardian-validation.sh
# Guardian Validation Cycle: Comprehensive type safety check
#
# Runs after Phase 4 implementation to ensure type safety with Sorbet
# Performs iterative fix-validate cycles with a maximum iteration limit
#
# Usage: guardian-validation.sh FEATURE_ID [MAX_ITERATIONS]
#   FEATURE_ID: Beads feature/epic ID to validate
#   MAX_ITERATIONS: Maximum fix attempts (default: 3)

# NO set -e for hooks - graceful degradation

FEATURE_ID="$1"
MAX_ITERATIONS=${2:-3}

echo ""
echo "═══════════════════════════════════════════════════════"
echo "🛡️  Guardian Validation Cycle"
echo "═══════════════════════════════════════════════════════"
echo "Feature: $FEATURE_ID"
echo "Max Iterations: $MAX_ITERATIONS"
echo ""

# Get all files modified in this feature
FILES=""

if command -v bd &>/dev/null && [ -n "$FEATURE_ID" ]; then
  echo "📋 Extracting files from beads feature $FEATURE_ID..."

  # Extract files from beads comments/descriptions
  FILES=$(bd show "$FEATURE_ID" 2>/dev/null | grep -oE "app/[a-z_/]+\.rb" | sort -u | tr '\n' ' ')

  # Also check subtasks
  SUBTASKS=$(bd list --status all 2>/dev/null | grep "$FEATURE_ID" | awk '{print $1}')
  for task_id in $SUBTASKS; do
    task_files=$(bd show "$task_id" 2>/dev/null | grep -oE "app/[a-z_/]+\.rb" | sort -u | tr '\n' ' ')
    FILES="$FILES $task_files"
  done

  # Remove duplicates
  FILES=$(echo "$FILES" | tr ' ' '\n' | sort -u | tr '\n' ' ')
else
  echo "⚠️  Beads not available or no feature ID, using git diff..."

  # Fallback: git diff
  FILES=$(git diff --name-only --cached 2>/dev/null | grep '\.rb$' | tr '\n' ' ')

  if [ -z "$FILES" ]; then
    # Try unstaged changes
    FILES=$(git diff --name-only 2>/dev/null | grep '\.rb$' | tr '\n' ' ')
  fi
fi

# Filter to only existing files
EXISTING_FILES=""
for file in $FILES; do
  if [ -f "$file" ]; then
    EXISTING_FILES="$EXISTING_FILES $file"
  fi
done
FILES="$EXISTING_FILES"

if [ -z "$FILES" ]; then
  echo "⚠️  No Ruby files to validate"
  echo "═══════════════════════════════════════════════════════"
  exit 0
fi

echo "Files to validate:"
for file in $FILES; do
  echo "  - $file"
done
echo ""

# Check if Sorbet is available
if ! bundle exec srb --version &>/dev/null 2>&1; then
  echo "⚠️  Sorbet not available (bundle exec srb not found)"
  echo "ℹ️  Guardian validation requires Sorbet for type checking"
  echo "ℹ️  Install with: gem 'sorbet' and gem 'sorbet-runtime'"
  echo "═══════════════════════════════════════════════════════"
  exit 0  # Non-blocking if Sorbet not available
fi

# Initialize guardian fixes log
GUARDIAN_LOG=".claude/guardian-fixes.log"
mkdir -p .claude
echo "Guardian Validation Cycle - $(date)" >> "$GUARDIAN_LOG"
echo "Feature: $FEATURE_ID" >> "$GUARDIAN_LOG"
echo "Files: $FILES" >> "$GUARDIAN_LOG"
echo "" >> "$GUARDIAN_LOG"

# Run validation cycle
for iteration in $(seq 1 $MAX_ITERATIONS); do
  echo "═══════════════════════════════════════════════════════"
  echo "🔄 Guardian Iteration $iteration/$MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  # Run Sorbet type check
  SORBET_OUTPUT="/tmp/guardian_sorbet_$$.txt"
  if bundle exec srb tc $FILES 2>&1 | tee "$SORBET_OUTPUT"; then
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✅ Guardian validation passed on iteration $iteration"
    echo "═══════════════════════════════════════════════════════"

    # Log success
    echo "[SUCCESS] Iteration $iteration - All type checks passed" >> "$GUARDIAN_LOG"
    rm -f "$SORBET_OUTPUT"
    exit 0
  fi

  # Type errors found
  echo ""
  echo "❌ Type errors found:"
  echo "─────────────────────────────────────────────────────"
  cat "$SORBET_OUTPUT"
  echo "─────────────────────────────────────────────────────"
  echo ""

  # Log errors
  echo "[ITERATION $iteration] Type errors:" >> "$GUARDIAN_LOG"
  cat "$SORBET_OUTPUT" >> "$GUARDIAN_LOG"
  echo "" >> "$GUARDIAN_LOG"

  if [ $iteration -lt $MAX_ITERATIONS ]; then
    echo "🔧 Attempting auto-fix..."
    echo ""

    # Analyze errors and suggest fixes
    for file in $FILES; do
      if grep -q "$file" "$SORBET_OUTPUT"; then
        echo "Analyzing $file for missing signatures..."

        # Extract error types from Sorbet output
        error_types=$(grep "$file" "$SORBET_OUTPUT" | grep -oE "Method [a-z_]+ does not exist" | head -3)

        if [ -n "$error_types" ]; then
          echo "  Found method errors in $file"
          echo "  - $error_types"
        fi

        # Log analysis
        echo "  [ANALYSIS] $file:" >> "$GUARDIAN_LOG"
        echo "    Errors: $error_types" >> "$GUARDIAN_LOG"
        echo "    Action: Manual review required - complex type errors need context-compiler agent" >> "$GUARDIAN_LOG"
        echo "" >> "$GUARDIAN_LOG"
      fi
    done

    echo ""
    echo "ℹ️  Guardian cannot auto-fix complex type errors"
    echo "ℹ️  These errors require context-compiler or implementation-executor agents"
    echo "ℹ️  Log written to: $GUARDIAN_LOG"
    echo ""
    echo "⏳ Waiting 2 seconds before next iteration..."
    sleep 2
  fi

  rm -f "$SORBET_OUTPUT"
done

# Max iterations reached
echo ""
echo "═══════════════════════════════════════════════════════"
echo "❌ Guardian validation failed after $MAX_ITERATIONS iterations"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Manual intervention required:"
echo "  1. Review type errors in $GUARDIAN_LOG"
echo "  2. Add missing type signatures (sig { ... })"
echo "  3. Run: bundle exec srb tc $FILES"
echo "  4. Fix errors and re-run guardian validation"
echo ""
echo "Common fixes:"
echo "  - Add 'sig { returns(T.untyped) }' for untyped methods"
echo "  - Add 'sig { params(x: String).returns(Integer) }' for typed methods"
echo "  - Add '# typed: false' to skip file temporarily"
echo ""
echo "═══════════════════════════════════════════════════════"

# Log failure
echo "[FAILURE] Max iterations ($MAX_ITERATIONS) reached - manual fixes required" >> "$GUARDIAN_LOG"
echo "" >> "$GUARDIAN_LOG"

exit 1
