#!/bin/bash
# Pre-edit validation for Swift files
# Validates Swift syntax and common patterns before edits
#
# Environment variables (set by hook):
# - FILE_PATH: Path to the file being edited
# - NEW_CONTENT: The new string being inserted
#
# Exit codes:
# - 0: Validation passed
# - 1: Fatal error (should block edit)
# - 2: Warning (non-blocking)

FILE_PATH="${FILE_PATH:-}"
NEW_CONTENT="${NEW_CONTENT:-}"

# Quick exit if required env vars missing
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

#==============================================================================
# 1. HELPER FUNCTIONS
#==============================================================================

log_validation() {
  local level="$1"
  local message="$2"
  local log_file=".claude/reactree-validation.log"

  mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] [PRE-EDIT] $FILE_PATH: $message" >> "$log_file" 2>/dev/null || true
}

#==============================================================================
# 2. SWIFT SYNTAX VALIDATION (if swiftc available)
#==============================================================================

if command -v swiftc >/dev/null 2>&1 && [ -n "$NEW_CONTENT" ]; then
  # Create temp file with new content for syntax check
  temp_file=$(mktemp /tmp/swift-validation.XXXXXX.swift)
  echo "$NEW_CONTENT" > "$temp_file"

  # Basic syntax check (will fail on incomplete snippets, so non-blocking)
  if ! swiftc -typecheck "$temp_file" >/dev/null 2>&1; then
    log_validation "WARN" "Swift syntax check failed for new content (may be incomplete snippet)"
  fi

  rm -f "$temp_file"
fi

#==============================================================================
# 3. MVVM PATTERN VALIDATION
#==============================================================================

# Check if editing a ViewModel file
if [[ "$FILE_PATH" == *"ViewModel.swift" ]] && [ -n "$NEW_CONTENT" ]; then
  # Warn if missing @MainActor for ViewModel
  if echo "$NEW_CONTENT" | grep -q "class.*ViewModel" && ! echo "$NEW_CONTENT" | grep -q "@MainActor"; then
    log_validation "WARN" "ViewModel class should use @MainActor annotation"
    cat <<EOF
{
  "systemMessage": "⚠️ **MVVM Pattern Warning**\\n\\n**File:** \`$FILE_PATH\`\\n\\n**Issue:** ViewModel class missing \`@MainActor\` annotation.\\n\\n**Recommended:**\\n\`\`\`swift\\n@MainActor\\nfinal class MyViewModel: BaseViewModel {\\n  // ...\\n}\\n\`\`\`\\n\\nThis ensures UI updates happen on the main thread.",
  "suppressOutput": false
}
EOF
  fi

  # Check for ObservableObject conformance
  if echo "$NEW_CONTENT" | grep -q "class.*ViewModel" && ! echo "$NEW_CONTENT" | grep -qE "(ObservableObject|BaseViewModel)"; then
    log_validation "WARN" "ViewModel should conform to ObservableObject or inherit from BaseViewModel"
  fi
fi

#==============================================================================
# 4. PROTOCOL-ORIENTED PROGRAMMING VALIDATION
#==============================================================================

# Check if editing a Service file
if [[ "$FILE_PATH" == *"Service.swift" ]] && [ -n "$NEW_CONTENT" ]; then
  # Services should have protocol definitions
  if echo "$NEW_CONTENT" | grep -q "class.*Service" && ! echo "$NEW_CONTENT" | grep -q "protocol.*ServiceProtocol"; then
    log_validation "WARN" "Service classes should have corresponding protocol definitions"
  fi
fi

#==============================================================================
# 5. FORCE UNWRAPPING DETECTION
#==============================================================================

if [ -n "$NEW_CONTENT" ]; then
  # Detect force unwrapping (! operator)
  force_unwrap_count=$(echo "$NEW_CONTENT" | grep -o '!' | wc -l | tr -d ' ')
  if [ "$force_unwrap_count" -gt 0 ]; then
    log_validation "WARN" "Detected $force_unwrap_count force unwrapping operator(s) - consider using optional binding instead"
  fi
fi

#==============================================================================
# 6. @PUBLISHED PROPERTY VALIDATION
#==============================================================================

if [ -n "$NEW_CONTENT" ]; then
  # Check for @Published properties outside of classes
  if echo "$NEW_CONTENT" | grep -q "@Published" && ! echo "$NEW_CONTENT" | grep -q "class"; then
    log_validation "WARN" "@Published properties should be inside a class (not struct)"
  fi

  # Check for @Published var (should not be let)
  if echo "$NEW_CONTENT" | grep -q "@Published.*let"; then
    log_validation "ERROR" "@Published properties must use 'var', not 'let'"
    cat <<EOF
{
  "systemMessage": "❌ **SwiftUI State Error**\\n\\n**File:** \`$FILE_PATH\`\\n\\n**Issue:** \`@Published\` properties must use \`var\`, not \`let\`.\\n\\n**Fix:**\\n\`\`\`swift\\n// ❌ Wrong\\n@Published let items: [Item] = []\\n\\n// ✅ Correct\\n@Published var items: [Item] = []\\n\`\`\`",
  "suppressOutput": false
}
EOF
    exit 2
  fi
fi

#==============================================================================
# 7. SWIFTUI VIEW VALIDATION
#==============================================================================

if [[ "$FILE_PATH" == *"View.swift" ]] && [ -n "$NEW_CONTENT" ]; then
  # Views should have a body property
  if echo "$NEW_CONTENT" | grep -q "struct.*:.*View" && ! echo "$NEW_CONTENT" | grep -q "var body:"; then
    log_validation "WARN" "SwiftUI View should have a 'body' property"
  fi

  # Check for @State vs @StateObject misuse
  if echo "$NEW_CONTENT" | grep -q "@State.*ViewModel"; then
    log_validation "ERROR" "ViewModels should use @StateObject or @ObservedObject, not @State"
    cat <<EOF
{
  "systemMessage": "❌ **SwiftUI State Management Error**\\n\\n**File:** \`$FILE_PATH\`\\n\\n**Issue:** ViewModel should use \`@StateObject\` or \`@ObservedObject\`, not \`@State\`.\\n\\n**Fix:**\\n\`\`\`swift\\n// ❌ Wrong\\n@State private var viewModel = MyViewModel()\\n\\n// ✅ Correct (for ownership)\\n@StateObject private var viewModel = MyViewModel()\\n\\n// ✅ Correct (for dependency injection)\\n@ObservedObject var viewModel: MyViewModel\\n\`\`\`",
  "suppressOutput": false
}
EOF
    exit 2
  fi
fi

#==============================================================================
# 8. ACCESSIBILITY VALIDATION
#==============================================================================

if [[ "$FILE_PATH" == *"View.swift" ]] && [ -n "$NEW_CONTENT" ]; then
  # Check for interactive elements without accessibility labels
  if echo "$NEW_CONTENT" | grep -qE "(Button|Toggle|Picker)" && ! echo "$NEW_CONTENT" | grep -q "accessibilityLabel"; then
    log_validation "INFO" "Consider adding accessibility labels to interactive elements"
  fi
fi

log_validation "INFO" "Pre-edit validation completed"
exit 0
