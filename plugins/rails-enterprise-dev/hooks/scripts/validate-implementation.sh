#!/bin/bash
# Validate implementation quality at checkpoints
set -e

# Parse arguments
PHASE=""
FILES=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --phase)
      PHASE="$2"
      shift 2
      ;;
    --files)
      FILES="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Check if quality gates enabled
STATE_FILE=".claude/rails-enterprise-dev.local.md"
if [ ! -f "$STATE_FILE" ]; then
  exit 0  # Not configured
fi

GATES_ENABLED=$(sed -n '/^---$/,/^---$/{ /^quality_gates_enabled:/p }' "$STATE_FILE" 2>/dev/null | sed 's/quality_gates_enabled: *//' | tr -d ' ')

if [ "$GATES_ENABLED" != "true" ]; then
  exit 0  # Gates disabled
fi

# Validation based on phase
case "$PHASE" in
  database|Database)
    # Validate database migrations
    if ! bundle exec rails db:migrate:status >/dev/null 2>&1; then
      echo "⚠️ Quality Gate Failed: Migration errors"
      exit 2
    fi
    ;;

  models|Models)
    # Validate models load
    if ! bundle exec rails runner "Rails.application.eager_load!" >/dev/null 2>&1; then
      echo "⚠️ Quality Gate Failed: Models don't load"
      exit 2
    fi

    # Run model specs if they exist
    if [ -d "spec/models" ] && command -v rspec >/dev/null 2>&1; then
      if ! bundle exec rspec spec/models --format progress 2>&1 | grep -q '0 failures'; then
        echo "⚠️ Quality Gate Failed: Model specs failing"
        exit 2
      fi
    fi
    ;;

  services|Services)
    # Check for common patterns
    if [ -n "$FILES" ]; then
      for file in $FILES; do
        if [ -f "$file" ] && [[ "$file" == *.rb ]]; then
          # Basic syntax check
          if ! ruby -c "$file" >/dev/null 2>&1; then
            echo "⚠️ Quality Gate Failed: Syntax error in $file"
            exit 2
          fi
        fi
      done
    fi

    # Run service specs if they exist
    if [ -d "spec/services" ] && command -v rspec >/dev/null 2>&1; then
      if ! bundle exec rspec spec/services --format progress 2>&1 | grep -q '0 failures'; then
        echo "⚠️ Quality Gate Failed: Service specs failing"
        exit 2
      fi
    fi
    ;;

  components|Components|views|Views)
    # Check for debug statements
    if grep -r 'binding.pry\|debugger\|byebug' app/ 2>/dev/null | grep -v spec; then
      echo "⚠️ Quality Gate Failed: Debug statements found"
      exit 2
    fi
    ;;

  tests|Tests)
    # Run full test suite
    if command -v rspec >/dev/null 2>&1; then
      if ! bundle exec rspec --format progress 2>&1 | grep -q '0 failures'; then
        echo "⚠️ Quality Gate Failed: Test failures"
        exit 2
      fi
    fi
    ;;

  refactoring|Refactoring)
    # Validate refactoring completeness
    # Check if refactoring validator exists
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REFACTOR_VALIDATOR="${SCRIPT_DIR}/validate-refactoring.sh"

    if [ -f "$REFACTOR_VALIDATOR" ]; then
      echo "Running refactoring validation..."

      # Look for refactoring logs in beads (if beads available)
      if command -v bd >/dev/null 2>&1 && [ -n "$BEADS_ISSUE_ID" ]; then
        bash "$REFACTOR_VALIDATOR" --issue-id "$BEADS_ISSUE_ID"
        REFACTOR_RESULT=$?

        if [ $REFACTOR_RESULT -ne 0 ]; then
          echo "⚠️ Quality Gate Failed: Incomplete refactoring"
          exit 2
        fi
      else
        echo "ℹ️ No beads issue ID provided, skipping refactoring validation"
      fi
    else
      echo "ℹ️ Refactoring validator not found, skipping refactoring validation"
    fi
    ;;

  *)
    # Generic validation
    if [ -n "$FILES" ]; then
      for file in $FILES; do
        if [ -f "$file" ] && [[ "$file" == *.rb ]]; then
          if ! ruby -c "$file" >/dev/null 2>&1; then
            echo "⚠️ Quality Gate Failed: Syntax error in $file"
            exit 2
          fi
        fi
      done
    fi
    ;;
esac

#==============================================================================
# STATIC ANALYSIS & SECURITY (ALL PHASES)
#==============================================================================

# RuboCop validation (if available)
if command -v rubocop &> /dev/null; then
  echo ""
  echo "Running RuboCop validation..."

  # Get Ruby files to check
  if [ -n "$FILES" ]; then
    RUBY_FILES=$(echo "$FILES" | tr ' ' '\n' | grep '\.rb$' || true)
  else
    # Check all app/ files for the phase
    case "$PHASE" in
      models|Models)
        RUBY_FILES="app/models"
        ;;
      services|Services)
        RUBY_FILES="app/services"
        ;;
      controllers|Controllers)
        RUBY_FILES="app/controllers"
        ;;
      components|Components)
        RUBY_FILES="app/components"
        ;;
      *)
        RUBY_FILES=""
        ;;
    esac
  fi

  if [ -n "$RUBY_FILES" ]; then
    # Run RuboCop with error-level failures only
    if ! rubocop --fail-level error --format simple $RUBY_FILES 2>&1; then
      echo ""
      echo "⚠️ Quality Gate Failed: RuboCop errors detected"
      echo ""
      echo "Fix with: rubocop -a $RUBY_FILES  (auto-correct)"
      echo ""
      exit 2
    fi
    echo "✅ RuboCop validation passed"
  fi
fi

# Brakeman security scan (for controllers and API phases)
if [ "$PHASE" = "controllers" ] || [ "$PHASE" = "Controllers" ] || [ "$PHASE" = "api" ] || [ "$PHASE" = "API" ]; then
  if command -v brakeman &> /dev/null; then
    echo ""
    echo "Running security scan..."

    # Run Brakeman with medium confidence warnings
    if ! brakeman --quiet --exit-on-warn --confidence-level 2 --no-pager 2>&1; then
      echo ""
      echo "⚠️ Quality Gate Failed: Security vulnerabilities detected"
      echo ""
      echo "Review the security warnings above and fix before proceeding."
      echo ""
      exit 2
    fi
    echo "✅ Security scan passed"
  fi
fi

# All validations passed
echo ""
echo "✓ Quality gates passed"
exit 0
