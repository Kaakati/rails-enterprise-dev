#!/bin/bash
# Verify context before code generation to prevent assumption bugs
# Runs as PreToolUse hook before Edit/Write operations on app/ files
#
# Enforcement strategy:
# 1. Check if tool is Edit or Write on app/ directory
# 2. Scan for common assumption patterns (current_admin, etc.)
# 3. Check if context verification exists in beads feature
# 4. Block if assumptions detected and context not verified
# 5. Log violations for quality review

set -e

# Get tool name and file path from hook environment
TOOL_NAME="${TOOL_NAME:-}"
FILE_PATH="${FILE_PATH:-}"

# Only run for Edit/Write tools
if [[ "$TOOL_NAME" != "Edit" ]] && [[ "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

# Only run for app/ directory files
if [[ ! "$FILE_PATH" =~ ^app/ ]]; then
  exit 0
fi

# Only run for Ruby/ERB files (skip assets, configs, etc.)
if [[ ! "$FILE_PATH" =~ \.(rb|erb)$ ]]; then
  exit 0
fi

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

# Check if beads is available
check_beads_available() {
  command -v bd &>/dev/null
}

# Get current feature ID from settings
get_feature_id() {
  local settings_file=".claude/rails-enterprise-dev.local.md"

  if [ ! -f "$settings_file" ]; then
    echo ""
    return
  fi

  # Extract feature_id from YAML frontmatter
  sed -n '/^---$/,/^---$/p' "$settings_file" | grep '^feature_id:' | sed 's/feature_id: *//' | tr -d ' '
}

# Check if feature has verified context in beads
has_verified_context() {
  local feature_id="$1"

  if [ -z "$feature_id" ] || [ "$feature_id" = "none" ]; then
    return 1
  fi

  if ! check_beads_available; then
    return 1
  fi

  # Check if feature comment contains "Context Verification Complete" or "verified_context:"
  bd show "$feature_id" 2>/dev/null | grep -q "Context Verification Complete\|verified_context:" && return 0 || return 1
}

# Extract verified helpers from beads feature comment
get_verified_helpers() {
  local feature_id="$1"
  local helper_type="$2"  # auth_helper, signed_in_helper, route_prefix

  if [ -z "$feature_id" ]; then
    echo ""
    return
  fi

  # Extract the helper value from YAML in beads comment
  bd show "$feature_id" 2>/dev/null | sed -n '/verified_context:/,/verified_at:/p' | grep "^$helper_type:" | sed "s/$helper_type: *//" | tr -d ' '
}

#==============================================================================
# ASSUMPTION PATTERN DETECTION
#==============================================================================

# Common assumption patterns to detect
ASSUMPTION_PATTERNS=(
  "current_admin[^i]"           # current_admin (not current_administrator)
  "current_user[^s]"            # current_user (generic assumption)
  "admin_signed_in\?"           # admin_signed_in? (wrong devise helper)
  "user_signed_in\?"            # user_signed_in? (generic assumption)
  "destroy_admin_session_path"  # destroy_admin_session_path (wrong route)
  "admin_dashboard_path"        # admin_dashboard_path (singular vs plural)
  "authenticate_admin!"         # authenticate_admin! (wrong devise method)
  "require_admin"               # require_admin (generic authorization)
  "@current_account"            # @current_account (may not exist in namespace)
)

# Scan file content for assumption patterns
scan_for_assumptions() {
  local file_path="$1"
  local content="$2"
  local violations=""

  for pattern in "${ASSUMPTION_PATTERNS[@]}"; do
    if echo "$content" | grep -qE "$pattern"; then
      violations="${violations}\n  ❌ Found pattern: $(echo "$pattern" | tr -d '\\')"
    fi
  done

  echo -e "$violations"
}

#==============================================================================
# CONTEXT VALIDATION
#==============================================================================

# Validate that code uses verified helpers
validate_against_verified_context() {
  local feature_id="$1"
  local file_path="$2"
  local content="$3"
  local violations=""

  # Get verified helpers from beads
  local verified_auth=$(get_verified_helpers "$feature_id" "auth_helper")
  local verified_signed_in=$(get_verified_helpers "$feature_id" "signed_in_helper")
  local verified_route_prefix=$(get_verified_helpers "$feature_id" "route_prefix")

  # Check if code uses different auth helper
  if [ -n "$verified_auth" ]; then
    # Extract current_* helper from content
    local used_auth=$(echo "$content" | grep -oE 'current_[a-z_]+' | head -1)

    if [ -n "$used_auth" ] && [ "$used_auth" != "$verified_auth" ]; then
      violations="${violations}\n  ❌ Using '$used_auth' but verified helper is '$verified_auth'"
    fi
  fi

  # Check if code uses different signed_in? helper
  if [ -n "$verified_signed_in" ]; then
    local used_signed_in=$(echo "$content" | grep -oE '[a-z_]+_signed_in\?' | head -1)

    if [ -n "$used_signed_in" ] && [ "$used_signed_in" != "$verified_signed_in" ]; then
      violations="${violations}\n  ❌ Using '$used_signed_in?' but verified helper is '$verified_signed_in'"
    fi
  fi

  # Check if code uses different route prefix
  if [ -n "$verified_route_prefix" ]; then
    # Extract route helpers from content (e.g., admin_dashboard_path)
    local route_patterns=$(echo "$content" | grep -oE '[a-z_]+_path|[a-z_]+_url')

    if [ -n "$route_patterns" ]; then
      # Check if any route doesn't start with verified prefix
      while IFS= read -r route; do
        if [[ "$route" =~ ^(admin|client|user)s?_ ]] && [[ ! "$route" =~ ^${verified_route_prefix} ]]; then
          violations="${violations}\n  ❌ Using route '$route' but verified prefix is '${verified_route_prefix}'"
        fi
      done <<< "$route_patterns"
    fi
  fi

  echo -e "$violations"
}

#==============================================================================
# MAIN ENFORCEMENT LOGIC
#==============================================================================

# Get feature ID from settings
FEATURE_ID=$(get_feature_id)

# Read file content (if Edit) or get from stdin (if Write)
FILE_CONTENT=""
if [ "$TOOL_NAME" = "Edit" ] && [ -f "$FILE_PATH" ]; then
  FILE_CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")
elif [ "$TOOL_NAME" = "Write" ]; then
  # For Write, content is in new_string parameter (passed via env)
  FILE_CONTENT="${NEW_STRING:-}"
fi

# If we can't read content, allow (don't block on technical issues)
if [ -z "$FILE_CONTENT" ]; then
  exit 0
fi

# Scan for assumption patterns
ASSUMPTION_VIOLATIONS=$(scan_for_assumptions "$FILE_PATH" "$FILE_CONTENT")

# If no assumption patterns found, allow
if [ -z "$ASSUMPTION_VIOLATIONS" ] || [ "$ASSUMPTION_VIOLATIONS" = "\n" ]; then
  exit 0
fi

# Assumption patterns found - check if context is verified
if has_verified_context "$FEATURE_ID"; then
  # Context is verified - validate against it
  CONTEXT_VIOLATIONS=$(validate_against_verified_context "$FEATURE_ID" "$FILE_PATH" "$FILE_CONTENT")

  if [ -n "$CONTEXT_VIOLATIONS" ] && [ "$CONTEXT_VIOLATIONS" != "\n" ]; then
    # Violations found - log and block
    echo "⛔ BLOCKED: Assumption violations detected"
    echo ""
    echo "File: $FILE_PATH"
    echo ""
    echo "Violations:"
    echo -e "$CONTEXT_VIOLATIONS"
    echo ""
    echo "Verified context in feature $FEATURE_ID:"
    bd show "$FEATURE_ID" 2>/dev/null | sed -n '/verified_context:/,/verified_at:/p'
    echo ""
    echo "Fix: Use the verified helpers listed above"

    # Log violation
    mkdir -p .claude
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] BLOCKED: $FILE_PATH - Context violation" >> .claude/assumption-violations.log

    exit 1
  else
    # No violations against verified context - allow
    exit 0
  fi
else
  # Context not verified - check if beads is available
  if check_beads_available && [ -n "$FEATURE_ID" ] && [ "$FEATURE_ID" != "none" ]; then
    # Beads available but context not verified - block
    echo "⛔ BLOCKED: Context verification required"
    echo ""
    echo "File: $FILE_PATH"
    echo ""
    echo "Detected assumption patterns:"
    echo -e "$ASSUMPTION_VIOLATIONS"
    echo ""
    echo "Action required:"
    echo "1. Complete implementation-executor.md Step 2.6 (Context Verification)"
    echo "2. Verify authentication helpers, routes, and authorization methods"
    echo "3. Record verified context in beads feature comment"
    echo ""
    echo "Feature: $FEATURE_ID"
    echo ""
    echo "Verification commands:"
    echo "  rg \"def current_\" app/controllers/"
    echo "  rg \"signed_in?\" app/views/"
    echo "  rails routes | grep [namespace]"

    # Log violation
    mkdir -p .claude
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] BLOCKED: $FILE_PATH - Context not verified" >> .claude/assumption-violations.log

    exit 1
  else
    # Beads not available or no feature ID - warn but allow
    echo "⚠️  WARNING: Assumption patterns detected but context verification unavailable"
    echo ""
    echo "File: $FILE_PATH"
    echo ""
    echo "Detected patterns:"
    echo -e "$ASSUMPTION_VIOLATIONS"
    echo ""
    echo "Recommendation: Install beads and run context verification to prevent bugs"
    echo ""

    # Log warning
    mkdir -p .claude
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING: $FILE_PATH - Assumption pattern (beads unavailable)" >> .claude/assumption-violations.log

    exit 0  # Don't block if beads unavailable
  fi
fi
