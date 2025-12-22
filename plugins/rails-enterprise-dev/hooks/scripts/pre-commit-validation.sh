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
# 5. VIEW HELPER VALIDATION (Prevent assumption bugs)
#==============================================================================

echo ""
echo "5. Validating view helpers..."

HELPER_ERRORS=0

# Get changed view files
VIEW_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(erb|haml|slim)$' || true)

if [ -z "$VIEW_FILES" ]; then
  echo "✓ No view files changed, skipping helper validation"
else
  echo "Checking $(echo "$VIEW_FILES" | wc -l | tr -d ' ') view file(s)..."

  # Common undefined helper patterns
  for file in $VIEW_FILES; do
    if [ -f "$file" ]; then

      # Check for current_admin (often undefined)
      if grep -n 'current_admin[^a-z_]' "$file" > /dev/null 2>&1; then
        # Verify it exists
        if ! grep -r "def current_admin" app/controllers/ app/helpers/ > /dev/null 2>&1; then
          echo "⚠️  $file uses 'current_admin' but helper is not defined"
          echo "   Search for actual helper: rg 'def current_' app/controllers/"
          echo "   Common alternatives: current_user, current_administrator"
          ((HELPER_ERRORS++))
        fi
      fi

      # Check for admin_signed_in? (often undefined)
      if grep -n 'admin_signed_in\?' "$file" > /dev/null 2>&1; then
        if ! grep -r "def admin_signed_in\?" app/controllers/ app/helpers/ > /dev/null 2>&1; then
          echo "⚠️  $file uses 'admin_signed_in?' but helper is not defined"
          echo "   Verify Devise scope: rg 'devise_for' config/routes.rb"
          ((HELPER_ERRORS++))
        fi
      fi

      # Check for current_account without account multi-tenancy
      if grep -n 'current_account' "$file" > /dev/null 2>&1; then
        if ! grep -r "def current_account\|@current_account" app/controllers/ > /dev/null 2>&1; then
          echo "⚠️  $file uses 'current_account' but helper/variable is not defined"
          echo "   Verify multi-tenancy setup or use different pattern"
          ((HELPER_ERRORS++))
        fi
      fi

      # Check for instance variables that may not be set
      # Extract @variable names from view
      INSTANCE_VARS=$(grep -oE '@[a-z_]+' "$file" | sort -u || true)

      if [ -n "$INSTANCE_VARS" ]; then
        # Get corresponding controller file
        CONTROLLER_FILE=""

        # Determine controller based on view path
        if [[ "$file" =~ app/views/([a-z_]+)/([a-z_]+)/ ]]; then
          NAMESPACE="${BASH_REMATCH[1]}"
          CONTROLLER="${BASH_REMATCH[2]}"
          CONTROLLER_FILE="app/controllers/${NAMESPACE}/${CONTROLLER}_controller.rb"

          if [ ! -f "$CONTROLLER_FILE" ]; then
            # Try without namespace
            CONTROLLER_FILE="app/controllers/${CONTROLLER}_controller.rb"
          fi
        elif [[ "$file" =~ app/views/([a-z_]+)/ ]]; then
          CONTROLLER="${BASH_REMATCH[1]}"
          CONTROLLER_FILE="app/controllers/${CONTROLLER}_controller.rb"
        fi

        # If controller found, check instance variables are set
        if [ -f "$CONTROLLER_FILE" ]; then
          for var in $INSTANCE_VARS; do
            # Skip common Rails variables
            if [[ "$var" != "@current_user" ]] && [[ "$var" != "@current_admin" ]]; then
              if ! grep -E "${var}\s*=" "$CONTROLLER_FILE" > /dev/null 2>&1; then
                echo "⚠️  $file uses '$var' but it may not be set in controller"
                echo "   Controller: $CONTROLLER_FILE"
                echo "   Verify variable is set or passed to view"
                ((HELPER_ERRORS++))
              fi
            fi
          done
        fi
      fi

      # Check for undefined route helpers (common patterns)
      # Extract *_path and *_url helpers
      ROUTE_HELPERS=$(grep -oE '[a-z_]+_(path|url)' "$file" | sort -u || true)

      if [ -n "$ROUTE_HELPERS" ]; then
        # Check for common misspellings
        if echo "$ROUTE_HELPERS" | grep -q "admin_.*_path"; then
          # Check if it should be admins_ (plural)
          if grep -r "namespace :admins" config/routes.rb > /dev/null 2>&1; then
            echo "⚠️  $file may have wrong route prefix"
            echo "   Check if 'admin_' should be 'admins_' (plural)"
            echo "   Verify with: rails routes | grep admin"
          fi
        fi
      fi

    fi
  done

  if [ $HELPER_ERRORS -gt 0 ]; then
    echo ""
    echo "⚠️  Found $HELPER_ERRORS potential helper issue(s)"
    echo "   These may cause 'undefined method' or 'undefined variable' errors"
    echo ""
    echo "   FIX STRATEGY:"
    echo "   1. Search for actual helper names: rg 'def current_' app/controllers/"
    echo "   2. Verify Devise scopes: rg 'devise_for' config/routes.rb"
    echo "   3. Check routes: rails routes | grep [namespace]"
    echo "   4. Ensure instance variables are set in controllers"
    echo ""
    echo "   Or commit anyway with: git commit --no-verify"
    echo "                          (not recommended)"
  else
    echo "✓ No undefined helper issues detected"
  fi
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
