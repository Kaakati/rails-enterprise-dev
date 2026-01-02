#!/bin/bash
# validate-implementation.sh
# Phase 4 Quality Gate: Validates implementation with Solargraph/Sorbet/Rubocop
#
# Called by workflow-orchestrator.md after each layer implementation
# Provides blocking validation with graceful degradation for missing tools
#
# Usage: validate-implementation.sh PHASE FILES
#   PHASE: Layer name (models, services, components, etc.)
#   FILES: Space-separated list of files to validate

# NO set -e for hooks - graceful degradation

# Parse arguments
PHASE="$1"
FILES="$2"

# Configuration
CONFIG=".claude/reactree-rails-dev.local.md"
VALIDATION_LEVEL="blocking"  # Default

# Load validation level from config if available
if [ -f "$CONFIG" ]; then
  VALIDATION_LEVEL=$(grep '^validation_level:' "$CONFIG" 2>/dev/null | sed 's/.*: *//' | tr -d ' \n')
  VALIDATION_LEVEL=${VALIDATION_LEVEL:-blocking}
fi

# Tool availability checks
check_tool_available() {
  local tool=$1
  case "$tool" in
    solargraph)
      gem list solargraph -i &>/dev/null
      ;;
    sorbet)
      bundle exec srb --version &>/dev/null 2>&1
      ;;
    rubocop)
      command -v rubocop &>/dev/null
      ;;
  esac
}

# Run Solargraph diagnostics via cclsp MCP
validate_solargraph() {
  if ! check_tool_available solargraph; then
    echo "⚠️  Solargraph not available, skipping..."
    return 0
  fi

  echo "🔍 Running Solargraph diagnostics..."

  local errors=0
  for file in $FILES; do
    if [ ! -f "$file" ]; then
      continue
    fi

    # Note: mcp__cclsp__get_diagnostics would be called by agents, not bash
    # For bash script, we'll use simpler validation
    # The agents will have access to the full MCP tool

    # Basic Solargraph validation (requires solargraph binary)
    if command -v solargraph &>/dev/null; then
      diagnostics=$(solargraph check "$file" 2>&1)

      if echo "$diagnostics" | grep -qiE "error"; then
        echo "❌ Solargraph errors in $file:"
        echo "$diagnostics" | grep -iE "error" | head -5
        errors=$((errors + 1))
      fi
    fi
  done

  if [ $errors -eq 0 ]; then
    echo "✅ Solargraph validation passed"
  fi

  return $errors
}

# Run Sorbet type checking
validate_sorbet() {
  if ! check_tool_available sorbet; then
    echo "⚠️  Sorbet not available, skipping..."
    return 0
  fi

  echo "🔍 Running Sorbet type checking..."

  # Only check files with type sigils
  local typed_files=""
  for file in $FILES; do
    if [ ! -f "$file" ]; then
      continue
    fi

    if head -5 "$file" 2>/dev/null | grep -q "# typed:"; then
      typed_files="$typed_files $file"
    fi
  done

  if [ -z "$typed_files" ]; then
    echo "ℹ️  No typed files, skipping Sorbet..."
    return 0
  fi

  # Run Sorbet type check
  local sorbet_output="/tmp/sorbet_output_$$.txt"
  if ! bundle exec srb tc $typed_files 2>&1 | tee "$sorbet_output"; then
    echo "❌ Sorbet type errors found"
    cat "$sorbet_output"
    rm -f "$sorbet_output"
    return 1
  fi

  rm -f "$sorbet_output"
  echo "✅ Sorbet type checking passed"
  return 0
}

# Run Rubocop style checking
validate_rubocop() {
  if ! check_tool_available rubocop; then
    echo "⚠️  Rubocop not available, skipping..."
    return 0
  fi

  echo "🔍 Running Rubocop style checking..."

  # Verify files exist
  local existing_files=""
  for file in $FILES; do
    if [ -f "$file" ]; then
      existing_files="$existing_files $file"
    fi
  done

  if [ -z "$existing_files" ]; then
    echo "⚠️  No files to validate"
    return 0
  fi

  # Run with fail-level based on validation_level
  local fail_level="error"
  if [ "$VALIDATION_LEVEL" = "blocking" ]; then
    fail_level="warning"
  fi

  if ! rubocop --fail-level "$fail_level" --format simple $existing_files 2>&1; then
    echo "❌ Rubocop violations found"
    return 1
  fi

  echo "✅ Rubocop validation passed"
  return 0
}

# Main validation
echo ""
echo "═══════════════════════════════════════════════════════"
echo "🔍 Phase $PHASE Quality Gate"
echo "═══════════════════════════════════════════════════════"
echo "Validation Level: $VALIDATION_LEVEL"
echo "Files: $FILES"
echo ""

ERRORS=0

# Run all validators
validate_solargraph || ERRORS=$((ERRORS + 1))
validate_sorbet || ERRORS=$((ERRORS + 1))
validate_rubocop || ERRORS=$((ERRORS + 1))

# Exit based on validation level
echo ""
echo "═══════════════════════════════════════════════════════"

if [ $ERRORS -gt 0 ]; then
  echo "❌ $ERRORS validation(s) failed"
  echo ""

  case "$VALIDATION_LEVEL" in
    blocking)
      echo "🛑 BLOCKED: Fix violations before proceeding"
      echo "═══════════════════════════════════════════════════════"
      exit 1  # Block
      ;;
    warning)
      echo "⚠️  WARNING: Violations found but allowing to proceed"
      echo "═══════════════════════════════════════════════════════"
      exit 2  # Warn
      ;;
    advisory)
      echo "ℹ️  ADVISORY: Review violations when convenient"
      echo "═══════════════════════════════════════════════════════"
      exit 0  # Allow
      ;;
    *)
      echo "⚠️  Unknown validation level: $VALIDATION_LEVEL (defaulting to blocking)"
      echo "═══════════════════════════════════════════════════════"
      exit 1  # Block by default
      ;;
  esac
else
  echo "✅ All validations passed"
  echo "═══════════════════════════════════════════════════════"
  exit 0
fi
