#!/bin/bash
# Validate refactoring completeness by checking for remaining references
set -e

# Parse arguments
ISSUE_ID=""
OLD_NAME=""
NEW_NAME=""
REFACTOR_TYPE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --issue-id)
      ISSUE_ID="$2"
      shift 2
      ;;
    --old-name)
      OLD_NAME="$2"
      shift 2
      ;;
    --new-name)
      NEW_NAME="$2"
      shift 2
      ;;
    --type)
      REFACTOR_TYPE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Check if ripgrep is available
if ! command -v rg &> /dev/null; then
  echo "⚠️ ripgrep (rg) not found. Install with: brew install ripgrep"
  echo "Skipping refactoring validation."
  exit 0
fi

# Parse refactoring log from beads if issue ID provided
if [ -n "$ISSUE_ID" ] && command -v bd &> /dev/null; then
  echo "📋 Extracting refactoring details from beads issue $ISSUE_ID..."

  # Get comments from beads issue
  REFACTORING_LOG=$(bd show "$ISSUE_ID" 2>/dev/null || echo "")

  if [ -z "$REFACTORING_LOG" ]; then
    echo "⚠️ Could not retrieve beads issue $ISSUE_ID"
    exit 0
  fi

  # Extract old and new names from refactoring log
  # Look for patterns like "Payment → Transaction" or "old: Payment, new: Transaction"
  if [ -z "$OLD_NAME" ]; then
    OLD_NAME=$(echo "$REFACTORING_LOG" | grep -E "(old_name:|→|Rename)" | head -1 | sed -E 's/.*(old_name:|Rename) *:? *([A-Z][a-zA-Z0-9_]*).*/\2/' | tr -d ' ')
  fi

  if [ -z "$NEW_NAME" ]; then
    NEW_NAME=$(echo "$REFACTORING_LOG" | grep -E "(new_name:|→)" | head -1 | sed -E 's/.*→ *([A-Z][a-zA-Z0-9_]*).*/\1/' | tr -d ' ')
  fi
fi

# Validate we have required information
if [ -z "$OLD_NAME" ]; then
  echo "❌ Error: Old name not provided and could not be extracted from beads"
  echo "Usage: $0 --old-name OldClass --new-name NewClass"
  echo "   or: $0 --issue-id BEADS_ISSUE_ID"
  exit 1
fi

if [ -z "$NEW_NAME" ]; then
  echo "⚠️ Warning: New name not provided, skipping validation"
  exit 0
fi

echo "🔍 Validating refactoring: $OLD_NAME → $NEW_NAME"
echo ""

# Check for .refactorignore file
IGNORE_FILE=".refactorignore"
IGNORE_ARGS=""
if [ -f "$IGNORE_FILE" ]; then
  echo "Found .refactorignore, excluding specified files..."
  IGNORE_ARGS="--ignore-file $IGNORE_FILE"
fi

# Initialize counters
TOTAL_REFS=0
RUBY_REFS=0
VIEW_REFS=0
ROUTE_REFS=0
SPEC_REFS=0
FACTORY_REFS=0
MIGRATION_REFS=0

# Temporary files for storing results
RUBY_RESULTS=$(mktemp)
VIEW_RESULTS=$(mktemp)
ROUTE_RESULTS=$(mktemp)
SPEC_RESULTS=$(mktemp)
FACTORY_RESULTS=$(mktemp)
MIGRATION_RESULTS=$(mktemp)

# Cleanup temp files on exit
trap "rm -f $RUBY_RESULTS $VIEW_RESULTS $ROUTE_RESULTS $SPEC_RESULTS $FACTORY_RESULTS $MIGRATION_RESULTS" EXIT

# Search for remaining references to old name

echo "Searching for remaining references to '$OLD_NAME'..."
echo ""

# 1. Ruby files (excluding specs and migrations)
if rg "\b$OLD_NAME\b" --type ruby --glob '!spec/**' --glob '!db/migrate/**' --glob '!db/migrate/*_rename_*.rb' $IGNORE_ARGS > "$RUBY_RESULTS" 2>/dev/null; then
  RUBY_REFS=$(wc -l < "$RUBY_RESULTS" | tr -d ' ')
else
  RUBY_REFS=0
fi

# 2. View files (ERB, HAML, SLIM)
if rg "$OLD_NAME" --glob '*.erb' --glob '*.haml' --glob '*.slim' app/views $IGNORE_ARGS > "$VIEW_RESULTS" 2>/dev/null; then
  VIEW_REFS=$(wc -l < "$VIEW_RESULTS" | tr -d ' ')
else
  VIEW_REFS=0
fi

# 3. Routes file
if [ -f "config/routes.rb" ]; then
  if grep -n "$OLD_NAME" config/routes.rb > "$ROUTE_RESULTS" 2>/dev/null; then
    ROUTE_REFS=$(wc -l < "$ROUTE_RESULTS" | tr -d ' ')
  else
    ROUTE_REFS=0
  fi
fi

# 4. Spec files
if rg "\b$OLD_NAME\b" spec --type ruby $IGNORE_ARGS > "$SPEC_RESULTS" 2>/dev/null; then
  SPEC_REFS=$(wc -l < "$SPEC_RESULTS" | tr -d ' ')
else
  SPEC_REFS=0
fi

# 5. Factory files
if [ -d "spec/factories" ]; then
  if rg "$OLD_NAME|:${OLD_NAME,,}" spec/factories $IGNORE_ARGS > "$FACTORY_RESULTS" 2>/dev/null; then
    FACTORY_REFS=$(wc -l < "$FACTORY_RESULTS" | tr -d ' ')
  else
    FACTORY_REFS=0
  fi
fi

# 6. Migration files (warn only, as some references expected in rename migrations)
if rg "$OLD_NAME" db/migrate --glob '!*_rename_*.rb' $IGNORE_ARGS > "$MIGRATION_RESULTS" 2>/dev/null; then
  MIGRATION_REFS=$(wc -l < "$MIGRATION_RESULTS" | tr -d ' ')
else
  MIGRATION_REFS=0
fi

# Calculate total
TOTAL_REFS=$((RUBY_REFS + VIEW_REFS + ROUTE_REFS + SPEC_REFS + FACTORY_REFS + MIGRATION_REFS))

# Display results summary
echo "📊 Validation Results:"
echo "  Ruby files:     $RUBY_REFS references"
echo "  View files:     $VIEW_REFS references"
echo "  Routes:         $ROUTE_REFS references"
echo "  Spec files:     $SPEC_REFS references"
echo "  Factories:      $FACTORY_REFS references"
echo "  Migrations:     $MIGRATION_REFS references"
echo "  ────────────────────────────"
echo "  Total:          $TOTAL_REFS references"
echo ""

# If no references found, validation passed
if [ $TOTAL_REFS -eq 0 ]; then
  echo "✅ Refactoring validation PASSED"
  echo "No remaining references to '$OLD_NAME' found."
  echo ""

  # Update beads if issue ID provided
  if [ -n "$ISSUE_ID" ] && command -v bd &> /dev/null; then
    bd comment "$ISSUE_ID" "✅ Refactoring Validation: PASSED

**Refactoring**: $OLD_NAME → $NEW_NAME
**Status**: Complete - All references updated

**Validation Results**:
- Ruby files: 0 references
- View files: 0 references
- Routes: 0 references
- Spec files: 0 references
- Factories: 0 references
- Migrations: 0 references

No remaining references to '$OLD_NAME' found. Refactoring is complete." 2>/dev/null || true
  fi

  exit 0
fi

# Validation failed - show detailed results
echo "❌ Refactoring validation FAILED"
echo ""
echo "Found $TOTAL_REFS remaining references to '$OLD_NAME'."
echo "Review and update the following locations:"
echo ""

# Show detailed results for each category
if [ $RUBY_REFS -gt 0 ]; then
  echo "Ruby files ($RUBY_REFS references):"
  cat "$RUBY_RESULTS" | head -20
  if [ $RUBY_REFS -gt 20 ]; then
    echo "... and $((RUBY_REFS - 20)) more"
  fi
  echo ""
fi

if [ $VIEW_REFS -gt 0 ]; then
  echo "View files ($VIEW_REFS references):"
  cat "$VIEW_RESULTS" | head -20
  if [ $VIEW_REFS -gt 20 ]; then
    echo "... and $((VIEW_REFS - 20)) more"
  fi
  echo ""
fi

if [ $ROUTE_REFS -gt 0 ]; then
  echo "Routes ($ROUTE_REFS references):"
  cat "$ROUTE_RESULTS"
  echo ""
fi

if [ $SPEC_REFS -gt 0 ]; then
  echo "Spec files ($SPEC_REFS references):"
  cat "$SPEC_RESULTS" | head -20
  if [ $SPEC_REFS -gt 20 ]; then
    echo "... and $((SPEC_REFS - 20)) more"
  fi
  echo ""
fi

if [ $FACTORY_REFS -gt 0 ]; then
  echo "Factories ($FACTORY_REFS references):"
  cat "$FACTORY_RESULTS"
  echo ""
fi

if [ $MIGRATION_REFS -gt 0 ]; then
  echo "⚠️ Migrations ($MIGRATION_REFS references - may be intentional in rename migrations):"
  cat "$MIGRATION_RESULTS"
  echo ""
fi

echo "Next steps:"
echo "1. Update the remaining references listed above"
echo "2. Add intentional references to .refactorignore if needed"
echo "3. Re-run validation: bash $0 --old-name $OLD_NAME --new-name $NEW_NAME"
echo ""

# Update beads if issue ID provided
if [ -n "$ISSUE_ID" ] && command -v bd &> /dev/null; then
  # Truncate results for beads comment (avoid huge comments)
  RUBY_SUMMARY=$(cat "$RUBY_RESULTS" | head -10 || echo "")
  VIEW_SUMMARY=$(cat "$VIEW_RESULTS" | head -10 || echo "")
  SPEC_SUMMARY=$(cat "$SPEC_RESULTS" | head -10 || echo "")

  bd comment "$ISSUE_ID" "❌ Refactoring Validation: FAILED

**Refactoring**: $OLD_NAME → $NEW_NAME
**Status**: Incomplete - References remain

**Validation Results**:
- Ruby files: $RUBY_REFS references
- View files: $VIEW_REFS references
- Routes: $ROUTE_REFS references
- Spec files: $SPEC_REFS references
- Factories: $FACTORY_REFS references
- Migrations: $MIGRATION_REFS references

**Total**: $TOTAL_REFS remaining references

**Sample References** (first 10):
\`\`\`
$(echo "$RUBY_SUMMARY$VIEW_SUMMARY$SPEC_SUMMARY" | head -10)
\`\`\`

**Next Steps**:
1. Update remaining references
2. Add intentional references to .refactorignore if needed
3. Re-run validation

See terminal output for full list of remaining references." 2>/dev/null || true
fi

exit 1
