#!/bin/bash
# Shared iOS/tvOS pattern detection utilities
# Sourced by other hook scripts for consistent pattern matching
#
# This file provides reusable functions for detecting iOS/tvOS
# development patterns, frameworks, and common code structures.

#==============================================================================
# FRAMEWORK DETECTION
#==============================================================================

# Detect if project uses SwiftUI
is_swiftui_project() {
  if find . -name "*.swift" -type f -exec grep -l "@State\|@Binding\|@ObservedObject\|@StateObject\|@EnvironmentObject" {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi
  return 1
}

# Detect if project uses UIKit
is_uikit_project() {
  if find . -name "*.swift" -type f -exec grep -l "UIViewController\|UIView\|UITableView" {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi
  return 1
}

# Detect if project uses Combine
is_combine_project() {
  if find . -name "*.swift" -type f -exec grep -l "import Combine\|@Published\|AnyCancellable" {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi
  return 1
}

# Detect if project uses async/await
is_async_await_project() {
  if find . -name "*.swift" -type f -exec grep -l "async \|await \|Task\|AsyncStream" {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi
  return 1
}

# Detect if project uses Core Data
is_core_data_project() {
  if find . -name "*.swift" -type f -exec grep -l "import CoreData\|NSManagedObject\|NSPersistentContainer" {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi
  return 1
}

# Detect if project uses Alamofire
is_alamofire_project() {
  if find . -name "*.swift" -type f -exec grep -l "import Alamofire\|AF\." {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  if [ -f "Podfile" ] && grep -q "Alamofire" "Podfile" 2>/dev/null; then
    return 0
  fi

  return 1
}

#==============================================================================
# ARCHITECTURE PATTERN DETECTION
#==============================================================================

# Detect MVVM architecture
is_mvvm_architecture() {
  # Check for ViewModel files
  if find . -name "*ViewModel.swift" -type f 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  # Check for ViewModel classes in code
  if find . -name "*.swift" -type f -exec grep -l "class.*ViewModel\|protocol.*ViewModelProtocol" {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  return 1
}

# Detect Clean Architecture layers
is_clean_architecture() {
  local has_core=false
  local has_presentation=false

  # Check for Core layer
  if [ -d "Core" ] || [ -d "Sources/Core" ] || [ -d "App/Core" ]; then
    has_core=true
  fi

  # Check for Presentation layer
  if [ -d "Presentation" ] || [ -d "Sources/Presentation" ] || [ -d "App/Presentation" ]; then
    has_presentation=true
  fi

  if $has_core && $has_presentation; then
    return 0
  fi

  return 1
}

# Detect Coordinator pattern
is_coordinator_pattern() {
  if find . -name "*Coordinator.swift" -type f 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  if find . -name "*.swift" -type f -exec grep -l "protocol.*Coordinator\|class.*Coordinator" {} \; 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  return 1
}

#==============================================================================
# PLATFORM DETECTION
#==============================================================================

# Detect iOS vs tvOS platform
detect_platform() {
  # Check Info.plist for UIDeviceFamily
  if find . -name "Info.plist" -type f -print0 2>/dev/null | xargs -0 grep -l "UIDeviceFamily.*3" >/dev/null 2>&1; then
    echo "tvOS"
    return
  fi

  # Check for tvOS-specific code
  if find . -name "*.swift" -type f -exec grep -l "@FocusState\|focusable()\|\.onPlayPauseCommand" {} \; 2>/dev/null | head -1 | grep -q .; then
    echo "tvOS"
    return
  fi

  echo "iOS"
}

# Detect if project supports multiple platforms
is_universal_platform() {
  local has_ios=false
  local has_tvos=false

  # Check for platform-specific code
  if find . -name "*.swift" -type f -exec grep -l "#if os(iOS)" {} \; 2>/dev/null | head -1 | grep -q .; then
    has_ios=true
  fi

  if find . -name "*.swift" -type f -exec grep -l "#if os(tvOS)" {} \; 2>/dev/null | head -1 | grep -q .; then
    has_tvos=true
  fi

  if $has_ios && $has_tvos; then
    return 0
  fi

  return 1
}

#==============================================================================
# CODE QUALITY DETECTION
#==============================================================================

# Detect if SwiftLint is configured
has_swiftlint_config() {
  if [ -f ".swiftlint.yml" ] || [ -f ".swiftlint.yaml" ]; then
    return 0
  fi
  return 1
}

# Detect if SwiftGen is configured
has_swiftgen_config() {
  if [ -f "swiftgen.yml" ] || [ -f "swiftgen.yaml" ]; then
    return 0
  fi
  return 1
}

# Detect test coverage setup
has_test_coverage() {
  # Check for XCTest files
  if find . -name "*Tests.swift" -o -name "*Test.swift" -type f 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  # Check for Tests directory
  if [ -d "Tests" ] || [ -d "AppTests" ] || find . -type d -name "*Tests" 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  return 1
}

#==============================================================================
# DEPENDENCY MANAGEMENT DETECTION
#==============================================================================

# Detect CocoaPods
uses_cocoapods() {
  if [ -f "Podfile" ] || [ -f "Podfile.lock" ]; then
    return 0
  fi
  return 1
}

# Detect Swift Package Manager
uses_spm() {
  if [ -f "Package.swift" ]; then
    return 0
  fi

  # Check for .xcodeproj with Package.resolved
  if find . -name "Package.resolved" -type f 2>/dev/null | head -1 | grep -q .; then
    return 0
  fi

  return 1
}

# Detect Carthage
uses_carthage() {
  if [ -f "Cartfile" ] || [ -f "Cartfile.resolved" ]; then
    return 0
  fi
  return 1
}

#==============================================================================
# SWIFT VERSION DETECTION
#==============================================================================

# Get Swift version from compiler
get_swift_version() {
  if command -v swift >/dev/null 2>&1; then
    swift --version 2>/dev/null | head -1 | sed 's/.*Swift version \([0-9.]*\).*/\1/'
  else
    echo "Unknown"
  fi
}

# Get minimum Swift version from project
get_minimum_swift_version() {
  # Check Package.swift
  if [ -f "Package.swift" ]; then
    sed -n 's/.*swift-tools-version:\([0-9.]*\).*/\1/p' Package.swift | head -1
    return
  fi

  # Check .swift-version file
  if [ -f ".swift-version" ]; then
    cat ".swift-version"
    return
  fi

  echo "Unknown"
}

#==============================================================================
# PROJECT STRUCTURE DETECTION
#==============================================================================

# Detect Xcode project structure
get_project_structure() {
  local project_file=""

  # Find .xcworkspace first (preferred)
  project_file=$(find . -maxdepth 2 -name "*.xcworkspace" 2>/dev/null | head -1)

  # Fallback to .xcodeproj
  if [ -z "$project_file" ]; then
    project_file=$(find . -maxdepth 2 -name "*.xcodeproj" 2>/dev/null | head -1)
  fi

  if [ -n "$project_file" ]; then
    echo "workspace" # or "project"
  else
    echo "unknown"
  fi
}

# Get project name
get_project_name() {
  local project_file=""

  project_file=$(find . -maxdepth 2 \( -name "*.xcworkspace" -o -name "*.xcodeproj" \) 2>/dev/null | head -1)

  if [ -n "$project_file" ]; then
    basename "$project_file" | sed 's/\.\(xcworkspace\|xcodeproj\)$//'
  else
    basename "$(pwd)"
  fi
}

#==============================================================================
# PATTERN VALIDATION
#==============================================================================

# Validate ViewModel pattern in file
validate_viewmodel_pattern() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  local content
  content=$(cat "$file_path")

  # Check for @MainActor
  if ! echo "$content" | grep -q "@MainActor"; then
    echo "WARN: ViewModel missing @MainActor"
    return 2
  fi

  # Check for ObservableObject
  if ! echo "$content" | grep -qE "(ObservableObject|BaseViewModel)"; then
    echo "WARN: ViewModel not conforming to ObservableObject"
    return 2
  fi

  return 0
}

# Validate Service pattern in file
validate_service_pattern() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  local content
  content=$(cat "$file_path")

  # Check for protocol definition
  if ! echo "$content" | grep -q "protocol.*ServiceProtocol"; then
    echo "WARN: Service without protocol definition"
    return 2
  fi

  return 0
}

# Validate SwiftUI View pattern
validate_view_pattern() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  local content
  content=$(cat "$file_path")

  # Check for body property
  if ! echo "$content" | grep -q "var body:"; then
    echo "ERROR: View missing body property"
    return 1
  fi

  # Check for improper @State usage with ViewModels
  if echo "$content" | grep -q "@State.*ViewModel"; then
    echo "ERROR: Using @State for ViewModel (should use @StateObject)"
    return 1
  fi

  return 0
}

#==============================================================================
# EXPORT FUNCTIONS (make them available to sourcing scripts)
#==============================================================================

# This allows other scripts to source this file and use these functions
export -f is_swiftui_project 2>/dev/null || true
export -f is_uikit_project 2>/dev/null || true
export -f is_combine_project 2>/dev/null || true
export -f is_async_await_project 2>/dev/null || true
export -f is_core_data_project 2>/dev/null || true
export -f is_alamofire_project 2>/dev/null || true
export -f is_mvvm_architecture 2>/dev/null || true
export -f is_clean_architecture 2>/dev/null || true
export -f is_coordinator_pattern 2>/dev/null || true
export -f detect_platform 2>/dev/null || true
export -f is_universal_platform 2>/dev/null || true
export -f has_swiftlint_config 2>/dev/null || true
export -f has_swiftgen_config 2>/dev/null || true
export -f has_test_coverage 2>/dev/null || true
export -f uses_cocoapods 2>/dev/null || true
export -f uses_spm 2>/dev/null || true
export -f uses_carthage 2>/dev/null || true
export -f get_swift_version 2>/dev/null || true
export -f get_minimum_swift_version 2>/dev/null || true
export -f get_project_structure 2>/dev/null || true
export -f get_project_name 2>/dev/null || true
export -f validate_viewmodel_pattern 2>/dev/null || true
export -f validate_service_pattern 2>/dev/null || true
export -f validate_view_pattern 2>/dev/null || true
