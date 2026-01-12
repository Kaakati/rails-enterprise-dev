#!/bin/bash
# Post-write validation for Swift files
# Runs SwiftLint and basic syntax checks after file writes
#
# Environment variables (set by hook):
# - FILE_PATH: Path to the file that was written
#
# Exit codes:
# - 0: Validation passed
# - 1: Fatal error (should block)
# - 2: Warning (non-blocking)

FILE_PATH="${FILE_PATH:-}"

# Quick exit if required env vars missing
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
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
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] [POST-WRITE] $FILE_PATH: $message" >> "$log_file" 2>/dev/null || true
}

#==============================================================================
# 2. SWIFT SYNTAX VALIDATION
#==============================================================================

if command -v swiftc >/dev/null 2>&1; then
  log_validation "INFO" "Running Swift syntax check"

  # Syntax check (capture both stdout and stderr)
  syntax_output=$(swiftc -typecheck "$FILE_PATH" 2>&1)
  syntax_exit_code=$?

  if [ $syntax_exit_code -ne 0 ]; then
    log_validation "ERROR" "Swift syntax validation failed: $syntax_output"

    # Extract just the first error for display
    first_error=$(echo "$syntax_output" | grep "error:" | head -1 | sed 's/.*error: //')

    cat <<EOF
{
  "systemMessage": "❌ **Swift Syntax Error**\\n\\n**File:** \`$FILE_PATH\`\\n\\n**Error:** $first_error\\n\\n**Full Output:**\\n\`\`\`\\n$syntax_output\\n\`\`\`\\n\\nPlease fix syntax errors before proceeding.",
  "suppressOutput": false
}
EOF
    exit 2
  fi

  log_validation "INFO" "Swift syntax check passed"
else
  log_validation "WARN" "swiftc not found - skipping syntax validation"
fi

#==============================================================================
# 3. SWIFTLINT VALIDATION
#==============================================================================

if command -v swiftlint >/dev/null 2>&1; then
  log_validation "INFO" "Running SwiftLint validation"

  # Run SwiftLint on the specific file
  lint_output=$(swiftlint lint --path "$FILE_PATH" 2>&1)
  lint_exit_code=$?

  # Parse SwiftLint output
  error_count=$(echo "$lint_output" | grep -c "error:" || echo "0")
  warning_count=$(echo "$lint_output" | grep -c "warning:" || echo "0")

  if [ "$error_count" -gt 0 ]; then
    log_validation "ERROR" "SwiftLint found $error_count error(s)"

    # Extract first few errors
    errors=$(echo "$lint_output" | grep "error:" | head -3)

    cat <<EOF
{
  "systemMessage": "❌ **SwiftLint Errors Detected**\\n\\n**File:** \`$FILE_PATH\`\\n\\n**Errors:** $error_count\\n**Warnings:** $warning_count\\n\\n**First Errors:**\\n\`\`\`\\n$errors\\n\`\`\`\\n\\nRun \`swiftlint autocorrect --path $FILE_PATH\` to auto-fix some issues.",
  "suppressOutput": false
}
EOF
    exit 2
  fi

  if [ "$warning_count" -gt 0 ]; then
    log_validation "WARN" "SwiftLint found $warning_count warning(s)"

    # Only show message if warnings exceed threshold
    if [ "$warning_count" -gt 5 ]; then
      warnings=$(echo "$lint_output" | grep "warning:" | head -3)

      cat <<EOF
{
  "systemMessage": "⚠️ **SwiftLint Warnings**\\n\\n**File:** \`$FILE_PATH\`\\n\\n**Warnings:** $warning_count\\n\\n**First Warnings:**\\n\`\`\`\\n$warnings\\n\`\`\`\\n\\nConsider running \`swiftlint autocorrect --path $FILE_PATH\` to auto-fix.",
  "suppressOutput": false
}
EOF
    fi
  else
    log_validation "INFO" "SwiftLint validation passed (0 errors, 0 warnings)"
  fi
else
  log_validation "WARN" "SwiftLint not found - skipping lint validation (install via: brew install swiftlint)"
fi

#==============================================================================
# 4. FILE-SPECIFIC VALIDATIONS
#==============================================================================

# Read file content for pattern checks
file_content=$(cat "$FILE_PATH")

# ViewModel validation
if [[ "$FILE_PATH" == *"ViewModel.swift" ]]; then
  log_validation "INFO" "Validating ViewModel pattern"

  # Check for @MainActor
  if echo "$file_content" | grep -q "class.*ViewModel" && ! echo "$file_content" | grep -q "@MainActor"; then
    log_validation "WARN" "ViewModel missing @MainActor annotation"
  fi

  # Check for ObservableObject
  if echo "$file_content" | grep -q "class.*ViewModel" && ! echo "$file_content" | grep -qE "(ObservableObject|BaseViewModel)"; then
    log_validation "WARN" "ViewModel should conform to ObservableObject"
  fi

  # Check for @Published properties
  if echo "$file_content" | grep -q "class.*ViewModel" && ! echo "$file_content" | grep -q "@Published"; then
    log_validation "INFO" "ViewModel has no @Published properties (may be intentional for base class)"
  fi
fi

# Service validation
if [[ "$FILE_PATH" == *"Service.swift" ]]; then
  log_validation "INFO" "Validating Service pattern"

  # Check for protocol definition
  if echo "$file_content" | grep -q "class.*Service" && ! echo "$file_content" | grep -q "protocol.*ServiceProtocol"; then
    log_validation "WARN" "Service implementation without protocol definition - consider Protocol-Oriented Programming"
  fi

  # Check for dependency injection
  if echo "$file_content" | grep -q "class.*Service" && ! echo "$file_content" | grep -qE "(init\(|private let)"; then
    log_validation "INFO" "Service may need dependency injection via initializer"
  fi
fi

# View validation
if [[ "$FILE_PATH" == *"View.swift" ]]; then
  log_validation "INFO" "Validating SwiftUI View pattern"

  # Check for body property
  if echo "$file_content" | grep -q "struct.*:.*View" && ! echo "$file_content" | grep -q "var body:"; then
    log_validation "ERROR" "SwiftUI View missing body property"
    exit 2
  fi

  # Check for proper state management
  if echo "$file_content" | grep -q "@State.*ViewModel"; then
    log_validation "ERROR" "View using @State for ViewModel - should use @StateObject or @ObservedObject"
    exit 2
  fi
fi

# Model validation
if [[ "$FILE_PATH" == *"Model.swift" ]] || [[ "$FILE_PATH" =~ Models/.*.swift$ ]]; then
  log_validation "INFO" "Validating Model pattern"

  # Check for Codable conformance (if JSON model)
  if echo "$file_content" | grep -q "struct.*Model" && ! echo "$file_content" | grep -qE "(Codable|Decodable|Encodable)"; then
    log_validation "INFO" "Model struct may need Codable conformance for JSON serialization"
  fi

  # Check for Equatable/Hashable (for SwiftUI)
  if echo "$file_content" | grep -q "struct.*Model" && ! echo "$file_content" | grep -qE "(Equatable|Hashable|Identifiable)"; then
    log_validation "INFO" "Model may need Identifiable conformance for SwiftUI List usage"
  fi
fi

#==============================================================================
# 5. COMMON ANTI-PATTERNS
#==============================================================================

# Force unwrapping count
force_unwrap_count=$(echo "$file_content" | grep -o '!' | wc -l | tr -d ' ')
if [ "$force_unwrap_count" -gt 5 ]; then
  log_validation "WARN" "Excessive force unwrapping detected ($force_unwrap_count instances) - consider optional binding"
fi

# Implicitly unwrapped optionals
implicit_count=$(echo "$file_content" | grep -cE 'var.*:.*\!' || echo "0")
if [ "$implicit_count" -gt 2 ]; then
  log_validation "WARN" "Excessive implicitly unwrapped optionals ($implicit_count instances) - may cause crashes"
fi

# Long files (>500 lines suggests need for refactoring)
line_count=$(wc -l < "$FILE_PATH" | tr -d ' ')
if [ "$line_count" -gt 500 ]; then
  log_validation "INFO" "File has $line_count lines - consider refactoring into smaller components"
fi

#==============================================================================
# 6. BUILD VALIDATION (OPTIONAL - if quick build flag set)
#==============================================================================

# Only run if QUICK_BUILD environment variable is set
if [ "$QUICK_BUILD" = "true" ]; then
  log_validation "INFO" "Skipping quick build validation (not implemented yet)"
  # Future: Run xcodebuild -scheme <scheme> -destination 'platform=iOS Simulator' build
fi

log_validation "INFO" "Post-write validation completed successfully"
exit 0
