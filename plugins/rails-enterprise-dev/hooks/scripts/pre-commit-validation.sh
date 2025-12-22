#!/bin/bash
# Pre-commit validation to catch obvious errors before commit
# Runs automatically via PreToolUse hook when git commit is executed

set -e

echo "Running pre-commit validation..."

# Get changed Ruby files (staged for commit)
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$' || true)

if [ -z "$CHANGED_FILES" ]; then
  echo "✓ No Ruby files changed, skipping validation"
  exit 0
fi

echo "Validating $(echo "$CHANGED_FILES" | wc -l | tr -d ' ') Ruby file(s)..."

#==============================================================================
# 1. SYNTAX CHECK
#==============================================================================

echo ""
echo "1. Checking syntax..."

SYNTAX_ERRORS=0

for file in $CHANGED_FILES; do
  if [ -f "$file" ]; then
    if ! ruby -c "$file" > /dev/null 2>&1; then
      echo "❌ Syntax error in $file:"
      ruby -c "$file"
      ((SYNTAX_ERRORS++))
    fi
  fi
done

if [ $SYNTAX_ERRORS -gt 0 ]; then
  echo ""
  echo "❌ Found $SYNTAX_ERRORS syntax error(s)"
  echo "   Fix syntax errors before committing"
  exit 1
fi

echo "✓ All files have valid syntax"

#==============================================================================
# 2. RUBOCOP VALIDATION
#==============================================================================

if command -v rubocop &> /dev/null; then
  echo ""
  echo "2. Running RuboCop..."

  # Run RuboCop on changed files (fail on errors, warn on conventions)
  if ! rubocop --fail-level error --format simple $CHANGED_FILES 2>&1; then
    echo ""
    echo "❌ RuboCop errors detected"
    echo ""
    echo "Fix with: rubocop -a $(echo $CHANGED_FILES | tr '\n' ' ')"
    echo "          (auto-correct safe violations)"
    echo ""
    echo "Or commit anyway with: git commit --no-verify"
    echo "                       (not recommended)"
    exit 1
  fi

  echo "✓ RuboCop validation passed"
else
  echo ""
  echo "⚠️  RuboCop not installed, skipping code style check"
  echo "   Install with: gem install rubocop rubocop-rails"
fi

#==============================================================================
# 3. COMMON MISTAKE DETECTION
#==============================================================================

echo ""
echo "3. Checking for common mistakes..."

WARNINGS=0

# Check for obvious nil errors (calling methods without safe navigation)
for file in $CHANGED_FILES; do
  if [ -f "$file" ]; then
    # Detect find_by(...).method without safe navigation
    if grep -n '\.find_by(.*)\.[a-z_]' "$file" | grep -v '&\.' > /dev/null 2>&1; then
      echo "⚠️  $file: Possible nil error - use safe navigation after find_by"
      ((WARNINGS++))
    fi

    # Detect params[:model] without strong parameters
    if grep -n 'params\[:[a-z_]*\]' "$file" | grep -v 'permit\|require' > /dev/null 2>&1; then
      if [[ "$file" == *controller* ]]; then
        echo "⚠️  $file: Possible mass assignment - use strong parameters"
        ((WARNINGS++))
      fi
    fi

    # Detect string interpolation in SQL
    if grep -n 'where(".*#{\|where('\''.*#{' "$file" > /dev/null 2>&1; then
      echo "⚠️  $file: Possible SQL injection - use placeholders instead of interpolation"
      ((WARNINGS++))
    fi
  fi
done

if [ $WARNINGS -gt 0 ]; then
  echo ""
  echo "⚠️  Found $WARNINGS potential issue(s)"
  echo "   Review warnings above (these don't block commit)"
fi

#==============================================================================
# 4. DEBUG STATEMENT DETECTION
#==============================================================================

echo ""
echo "4. Checking for debug statements..."

DEBUG_FOUND=0

for file in $CHANGED_FILES; do
  if [ -f "$file" ]; then
    if grep -n 'binding\.pry\|byebug\|debugger\|console\.log' "$file" > /dev/null 2>&1; then
      echo "⚠️  $file contains debug statements:"
      grep -n 'binding\.pry\|byebug\|debugger\|console\.log' "$file"
      ((DEBUG_FOUND++))
    fi
  fi
done

if [ $DEBUG_FOUND -gt 0 ]; then
  echo ""
  echo "⚠️  Found debug statements in $DEBUG_FOUND file(s)"
  echo "   Remove before committing to production branches"
fi

#==============================================================================
# SUCCESS
#==============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Pre-commit validation passed"
echo "═══════════════════════════════════════════════════════════"
echo ""

exit 0
