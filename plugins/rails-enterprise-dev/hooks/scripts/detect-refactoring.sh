#!/bin/bash
# Auto-detect refactorings from git diff after file changes
# Runs as PostToolUse hook after Edit/Write operations
#
# Detection methods:
# 1. File renames (git mv or similar)
# 2. Migration rename operations (rename_column, rename_table)
# 3. Class name changes (future enhancement)

set -e

# Only run if in git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  exit 0
fi

# Collect detections
DETECTIONS=""
DETECTION_COUNT=0

#==============================================================================
# 1. DETECT FILE RENAMES
#==============================================================================

# Check for renamed files in staging area
RENAMED_FILES=$(git diff --name-status --cached 2>/dev/null | grep '^R' || true)

if [ -n "$RENAMED_FILES" ]; then
  DETECTIONS="${DETECTIONS}\n📝 **File Rename Detected:**\n"

  echo "$RENAMED_FILES" | while IFS=$'\t' read status old new; do
    DETECTIONS="${DETECTIONS}  $old → $new\n"
    ((DETECTION_COUNT++))

    # If Ruby file, extract potential class name change
    if [[ "$old" == *.rb ]] && [[ "$new" == *.rb ]]; then
      # Convert filename to class name (snake_case to CamelCase)
      OLD_CLASS=$(basename "$old" .rb | awk '{split($0,a,"_"); for(i in a) printf "%s%s", toupper(substr(a[i],1,1)), substr(a[i],2)}')
      NEW_CLASS=$(basename "$new" .rb | awk '{split($0,a,"_"); for(i in a) printf "%s%s", toupper(substr(a[i],1,1)), substr(a[i],2)}')

      if [ -n "$OLD_CLASS" ] && [ -n "$NEW_CLASS" ] && [ "$OLD_CLASS" != "$NEW_CLASS" ]; then
        DETECTIONS="${DETECTIONS}  ⚠️  Possible class rename: $OLD_CLASS → $NEW_CLASS\n"
      fi

      # Check for namespace changes in file path
      OLD_NAMESPACE=$(dirname "$old" | sed 's/^app\///' | sed 's/\//::/')
      NEW_NAMESPACE=$(dirname "$new" | sed 's/^app\///' | sed 's/\//::/')

      if [ "$OLD_NAMESPACE" != "$NEW_NAMESPACE" ] && [ "$OLD_NAMESPACE" != "." ]; then
        DETECTIONS="${DETECTIONS}  ⚠️  Namespace change detected in path\n"
      fi
    fi

    # If JavaScript file, extract potential controller/module name change
    if [[ "$old" == *.js ]] && [[ "$new" == *.js ]]; then
      # Check for Stimulus controller rename
      if [[ "$old" == *_controller.js ]] && [[ "$new" == *_controller.js ]]; then
        OLD_CONTROLLER=$(basename "$old" _controller.js | sed -E 's/(^|_)([a-z])/\U\2/g' | sed 's/_//g')
        NEW_CONTROLLER=$(basename "$new" _controller.js | sed -E 's/(^|_)([a-z])/\U\2/g' | sed 's/_//g')

        if [ -n "$OLD_CONTROLLER" ] && [ -n "$NEW_CONTROLLER" ] && [ "$OLD_CONTROLLER" != "$NEW_CONTROLLER" ]; then
          DETECTIONS="${DETECTIONS}  ⚠️  Stimulus controller rename: ${OLD_CONTROLLER}Controller → ${NEW_CONTROLLER}Controller\n"
          DETECTIONS="${DETECTIONS}  ⚠️  Update data-controller attributes in views\n"
        fi
      else
        # Regular JavaScript file rename
        DETECTIONS="${DETECTIONS}  ⚠️  JavaScript file rename detected\n"
        DETECTIONS="${DETECTIONS}  ⚠️  Check for imports and references\n"
      fi
    fi
  done
fi

#==============================================================================
# 2. DETECT MIGRATION RENAMES
#==============================================================================

# Find recently created/modified migrations (within last hour)
RECENT_MIGRATIONS=$(find db/migrate -name "*.rb" -mmin -60 2>/dev/null || true)

if [ -n "$RECENT_MIGRATIONS" ]; then
  for migration in $RECENT_MIGRATIONS; do

    # Check for rename_column
    RENAME_COLS=$(grep -n "rename_column" "$migration" 2>/dev/null || true)
    if [ -n "$RENAME_COLS" ]; then
      if [ -z "$DETECTIONS" ]; then
        DETECTIONS="\n"
      fi
      DETECTIONS="${DETECTIONS}📝 **Migration Attribute Rename** in $(basename $migration):\n"
      DETECTIONS="${DETECTIONS}$(echo "$RENAME_COLS" | sed 's/^/  /')\n"
      ((DETECTION_COUNT++))

      # Extract old and new column names
      while IFS= read -r line; do
        OLD_COL=$(echo "$line" | grep -oE ':[a-z_]+' | head -2 | tail -1 | tr -d ':')
        NEW_COL=$(echo "$line" | grep -oE ':[a-z_]+' | tail -1 | tr -d ':')
        if [ -n "$OLD_COL" ] && [ -n "$NEW_COL" ]; then
          DETECTIONS="${DETECTIONS}  → Column: $OLD_COL → $NEW_COL\n"
        fi
      done <<< "$RENAME_COLS"
    fi

    # Check for rename_table
    RENAME_TBLS=$(grep -n "rename_table" "$migration" 2>/dev/null || true)
    if [ -n "$RENAME_TBLS" ]; then
      if [ -z "$DETECTIONS" ]; then
        DETECTIONS="\n"
      fi
      DETECTIONS="${DETECTIONS}📝 **Migration Table Rename** in $(basename $migration):\n"
      DETECTIONS="${DETECTIONS}$(echo "$RENAME_TBLS" | sed 's/^/  /')\n"
      ((DETECTION_COUNT++))

      # Extract old and new table names
      while IFS= read -r line; do
        OLD_TBL=$(echo "$line" | grep -oE ':[a-z_]+' | head -1 | tr -d ':')
        NEW_TBL=$(echo "$line" | grep -oE ':[a-z_]+' | tail -1 | tr -d ':')
        if [ -n "$OLD_TBL" ] && [ -n "$NEW_TBL" ]; then
          DETECTIONS="${DETECTIONS}  → Table: $OLD_TBL → $NEW_TBL\n"
        fi
      done <<< "$RENAME_TBLS"
    fi

    # Check for rename_index
    RENAME_IDX=$(grep -n "rename_index" "$migration" 2>/dev/null || true)
    if [ -n "$RENAME_IDX" ]; then
      if [ -z "$DETECTIONS" ]; then
        DETECTIONS="\n"
      fi
      DETECTIONS="${DETECTIONS}📝 **Migration Index Rename** in $(basename $migration):\n"
      DETECTIONS="${DETECTIONS}$(echo "$RENAME_IDX" | sed 's/^/  /')\n"
      ((DETECTION_COUNT++))
    fi
  done
fi

#==============================================================================
# 3. DETECT CLASS NAME CHANGES (in modified files)
#==============================================================================

# Check for modified Ruby files with potential class renames
MODIFIED_FILES=$(git diff --name-only --cached 2>/dev/null | grep '\.rb$' || true)

if [ -n "$MODIFIED_FILES" ]; then
  for file in $MODIFIED_FILES; do
    # Get old and new class definitions
    OLD_CLASS=$(git show HEAD:"$file" 2>/dev/null | grep -E '^\s*class [A-Z]' | head -1 | sed -E 's/.*class ([A-Z][a-zA-Z0-9_:]*).*/\1/' || true)
    NEW_CLASS=$(grep -E '^\s*class [A-Z]' "$file" 2>/dev/null | head -1 | sed -E 's/.*class ([A-Z][a-zA-Z0-9_:]*).*/\1/' || true)

    if [ -n "$OLD_CLASS" ] && [ -n "$NEW_CLASS" ] && [ "$OLD_CLASS" != "$NEW_CLASS" ]; then
      if [ -z "$DETECTIONS" ]; then
        DETECTIONS="\n"
      fi
      DETECTIONS="${DETECTIONS}📝 **Class Rename** in $file:\n"
      DETECTIONS="${DETECTIONS}  $OLD_CLASS → $NEW_CLASS\n"
      ((DETECTION_COUNT++))
    fi
  done
fi

#==============================================================================
# 4. DETECT CONFIGURATION FILE CHANGES
#==============================================================================

# Check for modified configuration files that might reference classes
CONFIG_FILES=$(git diff --name-only --cached 2>/dev/null | grep -E '^config/(initializers|environments|locales)/' || true)

if [ -n "$CONFIG_FILES" ]; then
  for file in $CONFIG_FILES; do
    # For Ruby config files, check for class constant changes
    if [[ "$file" == *.rb ]]; then
      # Get old and new class constants
      OLD_CONSTANTS=$(git show HEAD:"$file" 2>/dev/null | grep -oE '\b[A-Z][a-zA-Z0-9_:]*\b' | sort -u || true)
      NEW_CONSTANTS=$(grep -oE '\b[A-Z][a-zA-Z0-9_:]*\b' "$file" 2>/dev/null | sort -u || true)

      # Find removed constants
      REMOVED=$(comm -23 <(echo "$OLD_CONSTANTS") <(echo "$NEW_CONSTANTS") 2>/dev/null || true)

      if [ -n "$REMOVED" ]; then
        if [ -z "$DETECTIONS" ]; then
          DETECTIONS="\n"
        fi
        DETECTIONS="${DETECTIONS}📝 **Config File Change** in $file:\n"
        DETECTIONS="${DETECTIONS}  Removed constants: $(echo $REMOVED | tr '\n' ' ')\n"
        ((DETECTION_COUNT++))
      fi
    fi

    # For YAML locale files, check for model/attribute key changes
    if [[ "$file" == *.yml ]] || [[ "$file" == *.yaml ]]; then
      # Check if activerecord keys changed
      OLD_MODELS=$(git show HEAD:"$file" 2>/dev/null | grep -E '^\s+models:' -A 50 | grep -oE '^\s+[a-z_]+:' | tr -d ' :' || true)
      NEW_MODELS=$(grep -E '^\s+models:' "$file" 2>/dev/null -A 50 | grep -oE '^\s+[a-z_]+:' | tr -d ' :' || true)

      REMOVED_MODELS=$(comm -23 <(echo "$OLD_MODELS" | sort) <(echo "$NEW_MODELS" | sort) 2>/dev/null || true)

      if [ -n "$REMOVED_MODELS" ]; then
        if [ -z "$DETECTIONS" ]; then
          DETECTIONS="\n"
        fi
        DETECTIONS="${DETECTIONS}📝 **Locale File Change** in $file:\n"
        DETECTIONS="${DETECTIONS}  Removed model keys: $(echo $REMOVED_MODELS | tr '\n' ' ')\n"
        ((DETECTION_COUNT++))
      fi
    fi
  done
fi

#==============================================================================
# 5. OUTPUT WARNINGS IF DETECTIONS FOUND
#==============================================================================

if [ $DETECTION_COUNT -gt 0 ]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "⚠️  REFACTORING DETECTED ($DETECTION_COUNT potential rename(s))"
  echo "═══════════════════════════════════════════════════════════"
  echo -e "$DETECTIONS"
  echo ""
  echo "**ACTION REQUIRED:**"
  echo ""
  echo "If this is a refactoring (renaming/replacing existing code):"
  echo ""
  echo "1. Initialize refactoring log in beads:"
  echo "   record_refactoring 'OldName' 'NewName' 'refactor_type'"
  echo ""
  echo "   Types: class_rename, attribute_rename, namespace_change, etc."
  echo ""
  echo "2. Track all affected files"
  echo ""
  echo "3. Validate all references updated before closing task:"
  echo "   bash hooks/scripts/validate-refactoring.sh --old-name OldName --new-name NewName"
  echo ""
  echo "If NOT a refactoring (new feature with unrelated name):"
  echo "  - Ignore this warning"
  echo "  - Proceed with normal implementation"
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  # Exit with status 0 (don't block workflow, just warn)
  exit 0
fi

# No detections, silent exit
exit 0
