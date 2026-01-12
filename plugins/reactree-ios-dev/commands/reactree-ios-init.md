---
name: reactree-ios-init
description: |
  Initialize ReAcTree plugin in the current iOS/tvOS project. Validates Xcode setup,
  creates configuration, sets up working memory, and optionally copies bundled skills
  and rules. Run this first when using the plugin in a new Xcode project.
allowed-tools: ["Bash", "Read", "Write", "Glob", "AskUserQuestion"]
---

# ReAcTree iOS/tvOS Plugin Initialization

You are initializing the ReAcTree iOS/tvOS plugin for this Xcode project. Follow these steps systematically and provide clear feedback at each stage.

## Phase 1: Validate Plugin Installation

First, determine the plugin's actual location using `${CLAUDE_PLUGIN_ROOT}`:

```bash
# CLAUDE_PLUGIN_ROOT is set by Claude Code to the plugin's actual location
# This works regardless of how the plugin was installed (local, global, marketplace)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

# Fallback to local path if not set (for manual testing)
if [ -z "$PLUGIN_ROOT" ]; then
  if [ -d ".claude/plugins/reactree-ios-dev" ]; then
    PLUGIN_ROOT=".claude/plugins/reactree-ios-dev"
  else
    echo "ERROR: CLAUDE_PLUGIN_ROOT not set and no local plugin found"
    echo "Plugin location could not be determined"
    exit 1
  fi
fi

echo "Plugin located at: $PLUGIN_ROOT"

# Check plugin directory exists
ls -la "$PLUGIN_ROOT/" 2>/dev/null

# Check hooks.json exists (will be created in Phase 2 if using enhanced version)
if [ -f "$PLUGIN_ROOT/hooks/hooks.json" ]; then
  echo "Hooks configuration found"
  cat "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null | head -5
else
  echo "Note: hooks.json not found (hooks may be added in future plugin version)"
fi

# Check if skills directory exists in plugin
if [ -d "$PLUGIN_ROOT/skills" ]; then
  skill_count=$(find "$PLUGIN_ROOT/skills" -maxdepth 1 -type d 2>/dev/null | wc -l)
  echo "Plugin includes $((skill_count - 1)) bundled skills"
else
  echo "Warning: No bundled skills found in plugin"
fi
```

**Expected**: Plugin directory with skills and optional hooks configuration.

**If CLAUDE_PLUGIN_ROOT is empty**: The command will check for a local installation at `.claude/plugins/reactree-ios-dev/`.

**If neither exists**: Report error - plugin not installed correctly.

---

## Phase 2: Detect Xcode Project

Detect the Xcode project and platform type (iOS vs tvOS):

```bash
echo "=== Xcode Project Detection ==="
echo ""

# Find .xcodeproj or .xcworkspace
XCODE_PROJECT=$(find . -maxdepth 2 -name "*.xcodeproj" -o -name "*.xcworkspace" | head -1)

if [ -z "$XCODE_PROJECT" ]; then
  echo "ERROR: No Xcode project found"
  echo "Could not find *.xcodeproj or *.xcworkspace in current directory"
  echo ""
  echo "This command must be run from the root of an Xcode project"
  echo "Example project structure:"
  echo "  MyApp.xcodeproj/"
  echo "  MyApp/"
  echo "    ├── App/"
  echo "    ├── Core/"
  echo "    ├── Presentation/"
  echo "    └── DesignSystem/"
  exit 1
fi

echo "✅ Found Xcode project: $XCODE_PROJECT"

# Detect project name
PROJECT_NAME=$(basename "$XCODE_PROJECT" | sed 's/\.\(xcodeproj\|xcworkspace\)$//')
echo "   Project name: $PROJECT_NAME"

# Detect platform (iOS vs tvOS)
# Check Info.plist for UIDeviceFamily
# 1 = iPhone, 2 = iPad, 3 = tvOS
PLATFORM="iOS"
if find . -name "Info.plist" -type f -print0 2>/dev/null | xargs -0 grep -l "UIDeviceFamily.*3" >/dev/null 2>&1; then
  PLATFORM="tvOS"
  echo "   Platform: tvOS (Apple TV)"
elif find . -name "Info.plist" -type f -print0 2>/dev/null | xargs -0 grep -l "UIDeviceFamily.*2" >/dev/null 2>&1; then
  echo "   Platform: iOS (includes iPad)"
else
  echo "   Platform: iOS (iPhone)"
fi

# Detect Swift version
SWIFT_VERSION=$(swift --version 2>/dev/null | head -1 || echo "Swift not found")
echo "   Swift: $SWIFT_VERSION"

# Detect Xcode version
XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "xcodebuild not found")
echo "   Xcode: $XCODE_VERSION"

echo ""
```

**Expected**: Detection of `.xcodeproj` or `.xcworkspace`, project name, platform type, Swift version, and Xcode version.

**If no project found**: Report error and exit.

---

## Phase 3: Check Skills Directory

Check if the project has skills:

```bash
echo "=== Skills Directory Check ==="
echo ""

# Check skills directory
if [ -d ".claude/skills" ]; then
  # Count skill directories (subtract 1 for the directory itself)
  skill_count=$(find .claude/skills -maxdepth 1 -type d 2>/dev/null | wc -l)
  existing_skills=$((skill_count - 1))
  echo "Found $existing_skills existing skills in .claude/skills/"
  ls -1 .claude/skills/ 2>/dev/null | head -10
  if [ $existing_skills -gt 10 ]; then
    echo "   ... and $((existing_skills - 10)) more"
  fi
else
  echo "No .claude/skills/ directory found"
  existing_skills=0
fi

echo ""
```

### Case A: Skills Directory Exists WITH Skills

If `.claude/skills/` exists and has skills, use **AskUserQuestion** to ask:

```
Found {existing_skills} existing skills in .claude/skills/

The plugin includes 27 bundled skills for iOS/tvOS development.
Would you like to update/replace them?

Options:
  [1] Replace all with bundled skills (Recommended)
      - Overwrites existing skills with latest versions from plugin
      - swift-conventions, swiftui-patterns, mvvm-architecture, clean-architecture-ios
      - alamofire-patterns, api-integration, session-management
      - atomic-design-ios, navigation-patterns, theme-management
      - xctest-patterns, swiftgen-integration, code-quality-gates, localization-ios
      - Plus 13 advanced skills (error-handling, concurrency, accessibility, etc.)

  [2] Keep existing skills
      - Don't modify .claude/skills/
      - Continue with current skills

  [3] Merge (add missing only)
      - Keep existing skills
      - Add any new skills not already present
```

### Case B: Skills Directory Empty or Missing

If `.claude/skills/` is empty or missing, use **AskUserQuestion** to offer:

```
No skills found in .claude/skills/

The plugin includes 27 bundled skills for iOS/tvOS development.
Would you like to copy them to your project?

Options:
  [1] Copy all bundled skills (Recommended)
      - Core (4): swift-conventions, swiftui-patterns, mvvm-architecture, clean-architecture-ios
      - Networking (3): alamofire-patterns, api-integration, session-management
      - UI (5): atomic-design-ios, navigation-patterns, theme-management, swiftgen-integration, localization-ios
      - Testing (2): xctest-patterns, code-quality-gates
      - Advanced (13): error-handling, model-patterns, concurrency, accessibility, performance,
                       dependency-injection, coordinator-pattern, combine-reactive, core-data,
                       push-notifications, app-lifecycle, tvos-specific, security-best-practices

  [2] Copy only core skills (4 skills)
      - swift-conventions - Swift 5 naming and best practices
      - swiftui-patterns - SwiftUI state management patterns
      - mvvm-architecture - MVVM pattern with BaseViewModel
      - clean-architecture-ios - Layer separation and dependency rules

  [3] Skip - I'll add skills manually later
```

### Copy/Replace Skills Based on User Choice

**Important**: Use `$PLUGIN_ROOT` variable from Phase 1 (set via `${CLAUDE_PLUGIN_ROOT}`).

**Replace all / Copy all bundled skills**:
```bash
echo "Copying all bundled skills..."
mkdir -p .claude/skills
# Remove existing to ensure clean state
rm -rf .claude/skills/*
cp -r "$PLUGIN_ROOT/skills/"* .claude/skills/
skill_count=$(find .claude/skills -maxdepth 1 -type d 2>/dev/null | wc -l)
echo "✅ Copied $((skill_count - 1)) skills to .claude/skills/"
echo ""
```

**Copy only core skills**:
```bash
echo "Copying core skills..."
mkdir -p .claude/skills
cp -r "$PLUGIN_ROOT/skills/swift-conventions" .claude/skills/
cp -r "$PLUGIN_ROOT/skills/swiftui-patterns" .claude/skills/
cp -r "$PLUGIN_ROOT/skills/mvvm-architecture" .claude/skills/
cp -r "$PLUGIN_ROOT/skills/clean-architecture-ios" .claude/skills/
echo "✅ Copied 4 core skills to .claude/skills/"
echo "   - swift-conventions"
echo "   - swiftui-patterns"
echo "   - mvvm-architecture"
echo "   - clean-architecture-ios"
echo ""
```

**Merge (add missing only)**:
```bash
echo "Merging skills (adding missing only)..."
mkdir -p .claude/skills
ADDED_COUNT=0
for skill_dir in "$PLUGIN_ROOT/skills/"*/; do
  skill_name=$(basename "$skill_dir")
  if [ ! -d ".claude/skills/$skill_name" ]; then
    cp -r "$skill_dir" ".claude/skills/"
    echo "   Added: $skill_name"
    ADDED_COUNT=$((ADDED_COUNT + 1))
  fi
done
if [ $ADDED_COUNT -eq 0 ]; then
  echo "   No new skills to add (all skills already present)"
else
  echo "✅ Added $ADDED_COUNT new skills"
fi
echo ""
```

---

## Phase 4: Xcode Tools Setup

Validate and set up iOS development tools:

```bash
echo "=== Xcode Tools Setup ==="
echo ""

# Track what gets installed/configured
TOOLS_CONFIGURED=""

# Check SwiftLint installation
if command -v swiftlint >/dev/null 2>&1; then
  SWIFTLINT_VERSION=$(swiftlint version)
  echo "✅ SwiftLint installed: $SWIFTLINT_VERSION"
else
  echo "⚠️  SwiftLint not found"
  echo "   SwiftLint is required for code quality validation"
  echo "   Install with: brew install swiftlint"
  echo "   Or visit: https://github.com/realm/SwiftLint"
  echo ""
fi

# Create .swiftlint.yml if missing
if [ ! -f ".swiftlint.yml" ]; then
  echo "Creating .swiftlint.yml configuration..."
  cat > .swiftlint.yml <<'SWIFTLINT'
# SwiftLint Configuration for iOS/tvOS Project
# Generated by ReAcTree iOS Plugin

disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - empty_string
  - explicit_init
  - fatal_error_message
  - force_unwrapping
  - implicitly_unwrapped_optional
  - multiline_arguments
  - multiline_parameters
  - overridden_super_call
  - redundant_nil_coalescing
  - sorted_imports

included:
  - ${PROJECT_NAME}
  - Core
  - Presentation
  - DesignSystem

excluded:
  - Pods
  - Carthage
  - vendor
  - .build

line_length:
  warning: 120
  error: 150
  ignores_urls: true
  ignores_function_declarations: true
  ignores_comments: true

function_body_length:
  warning: 40
  error: 100

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000
  ignore_comment_only_lines: true

cyclomatic_complexity:
  warning: 10
  error: 20

identifier_name:
  min_length:
    warning: 1
  max_length:
    warning: 40
    error: 50
  excluded:
    - id
    - URL
    - url

reporter: "xcode"
SWIFTLINT
  echo "✅ Created .swiftlint.yml"
  TOOLS_CONFIGURED="$TOOLS_CONFIGURED swiftlint-config"
else
  echo ".swiftlint.yml already exists (preserving existing configuration)"
fi

# Check Xcodegen (optional)
if command -v xcodegen >/dev/null 2>&1; then
  echo "✅ Xcodegen installed: $(xcodegen --version)"
else
  echo "   Xcodegen not found (optional tool for project generation)"
  echo "   Install with: brew install xcodegen"
fi

# Check Swift version (minimum 5.7)
SWIFT_VERSION_NUMBER=$(swift --version 2>/dev/null | grep -oE 'Swift version [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' || echo "0.0")
SWIFT_MAJOR=$(echo "$SWIFT_VERSION_NUMBER" | cut -d'.' -f1)
SWIFT_MINOR=$(echo "$SWIFT_VERSION_NUMBER" | cut -d'.' -f2)

if [ "$SWIFT_MAJOR" -lt 5 ] || ([ "$SWIFT_MAJOR" -eq 5 ] && [ "$SWIFT_MINOR" -lt 7 ]); then
  echo "⚠️  Swift version $SWIFT_VERSION_NUMBER detected (minimum 5.7 recommended)"
  echo "   Some features may not be available"
else
  echo "✅ Swift $SWIFT_VERSION_NUMBER (meets minimum 5.7)"
fi

echo ""
```

**Expected**: SwiftLint installed, `.swiftlint.yml` created, Swift 5.7+ detected.

**If tools missing**: Provide installation instructions but continue (non-blocking).

---

## Phase 5: Rules System Setup

Set up Claude Code Rules for path-specific guidance:

```bash
echo "=== Rules System Setup ==="
echo ""

# Create .claude/rules directory if it doesn't exist
mkdir -p .claude/rules

# Check if rules already exist
if [ "$(ls -A .claude/rules 2>/dev/null | wc -l)" -gt 0 ]; then
  echo ".claude/rules/ directory already has files"
  echo "Skipping rules initialization (existing rules preserved)"
else
  echo "Creating .claude/rules/ directory structure..."
  mkdir -p .claude/rules/core
  mkdir -p .claude/rules/presentation
  mkdir -p .claude/rules/design-system
  mkdir -p .claude/rules/testing
  mkdir -p .claude/rules/quality-gates

  # Copy bundled rules from plugin
  if [ -d "$PLUGIN_ROOT/rules" ]; then
    echo "Copying bundled rules from plugin..."
    cp -r "$PLUGIN_ROOT/rules/"* .claude/rules/

    # Count copied rules
    rule_count=$(find .claude/rules -name '*.md' -type f | wc -l)
    echo "✅ Copied $rule_count rule files to .claude/rules/"
  else
    echo "Note: No bundled rules found in plugin (expected 12 rule files)"
    echo "Rules system is available but no default rules were installed"
  fi
fi

echo ""
echo "Rules System:"
echo "  - Path-specific rules automatically load based on file being edited"
echo "  - Service files → rules/core/services.md"
echo "  - ViewModel files → rules/presentation/viewmodels.md"
echo "  - View files → rules/presentation/views.md"
echo "  - Component files → rules/design-system/components.md"
echo "  - Test files → rules/testing/unit-tests.md"
echo "  - And more..."
echo ""
```

**Rules Documentation**:

The Rules system provides path-specific, context-aware guidance that automatically loads based on the file you're editing:

- **Service rules** (`{Core,Services}/**/*Service.swift`) - Protocol-oriented service patterns
- **Manager rules** (`{Core,Managers}/**/*Manager.swift`) - Singleton manager patterns
- **NetworkRouter rules** (`{Core,Networking}/**/*API.swift`) - NetworkRouter enum patterns
- **View rules** (`{Presentation,Views}/**/*.swift`) - SwiftUI view composition
- **ViewModel rules** (`{Presentation,ViewModels}/**/*ViewModel.swift`) - MVVM patterns with @Published
- **Model rules** (`{Presentation,Models}/**/*.swift`) - Codable struct patterns
- **Component rules** (`{DesignSystem,Components}/**/*.swift`) - Atomic design hierarchy
- **Resource rules** (`{DesignSystem,Resources}/**/*.swift`) - SwiftGen asset patterns
- **Unit test rules** (`Tests/**/*Tests.swift`) - XCTest structure (Given-When-Then)
- **UI test rules** (`UITests/**/*UITests.swift`) - XCUITest patterns
- **SwiftLint rules** (`**/*.swift`) - Linting enforcement
- **Build validation rules** (`**/*.swift`) - Build success criteria

Benefits:
- ✅ Only relevant rules load (60-70% reduction in context overhead)
- ✅ Hyper-targeted guidance for the specific file type
- ✅ Customizable per project (.claude/rules/ can be modified)
- ✅ Works alongside existing skills system

---

## Phase 6: Generate Configuration File

Create or update `.claude/reactree-ios-dev.local.md`:

```bash
echo "=== Configuration File Generation ==="
echo ""

# Create configuration file
cat > .claude/reactree-ios-dev.local.md <<MARKDOWN
---
smart_detection_enabled: true
detection_mode: suggest
annoyance_threshold: medium
test_coverage_threshold: 80
platform: $PLATFORM
---

# ReAcTree iOS/tvOS Configuration

This file was generated by \`/reactree-ios-init\` on $(date '+%Y-%m-%d %H:%M:%S').

## Project Information

- **Project Name**: $PROJECT_NAME
- **Platform**: $PLATFORM
- **Swift Version**: $SWIFT_VERSION_NUMBER
- **Xcode**: $XCODE_VERSION

## Settings

- **smart_detection_enabled**: Enable auto-triggering based on prompt analysis
- **detection_mode**: \`suggest\` (show suggestions) | \`inject\` (auto-activate) | \`disabled\`
- **annoyance_threshold**: \`low\` (minimal triggers) | \`medium\` | \`high\` (frequent triggers)
- **test_coverage_threshold**: Minimum test coverage percentage (default: 80%)
- **platform**: Target platform (\`iOS\`, \`tvOS\`, or \`both\`)

## Quality Gates

- ✅ SwiftLint strict mode enforcement
- ✅ Build validation (xcodebuild clean build)
- ✅ Test coverage $coverage_threshold% threshold
- ✅ SwiftGen configuration validation (if used)

## Parallel Execution Groups

The plugin uses 3-group parallel execution for faster workflows:

- **Group A**: Core Layer (Services, Managers, NetworkRouters)
- **Group B**: Presentation Layer (Views, ViewModels, Models)
- **Group C**: Design System (Components, Resources, Theme)

Sequential phases run after all groups complete:
- **Integration & Testing**: Depends on Groups A, B, C

## Beads Integration

Task tracking is enabled for multi-session work:
- Creates feature epics automatically
- Tracks implementation phases as subtasks
- Maintains dependencies between tasks
- Provides progress visibility

## Available Skills

<!-- Auto-populated by skill discovery on SessionStart -->

MARKDOWN

echo "✅ Created .claude/reactree-ios-dev.local.md"
echo ""

# Scan and categorize skills
echo "Categorizing skills..."
echo ""

# Scan skills directory
if [ -d ".claude/skills" ]; then
  # Categorize skills based on naming patterns

  # Core skills
  CORE_SKILLS=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(swift-conventions|mvvm-architecture|clean-architecture)' | tr '\n' ' ')

  # Networking skills
  NETWORK_SKILLS=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(alamofire|api|http|networking|session)' | tr '\n' ' ')

  # UI skills
  UI_SKILLS=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(swiftui|design-system|atomic-design|navigation|theme|swiftgen)' | tr '\n' ' ')

  # Data/Model skills
  DATA_SKILLS=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(model|codable|persistence|core-data)' | tr '\n' ' ')

  # Testing skills
  TEST_SKILLS=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(xctest|test|quality)' | tr '\n' ' ')

  # Platform-specific
  PLATFORM_SKILLS=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(tvos|ios-specific|accessibility|localization)' | tr '\n' ' ')

  # Advanced skills
  ADVANCED_SKILLS=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(error-handling|concurrency|performance|dependency-injection|coordinator|combine|push-notifications|app-lifecycle|security)' | tr '\n' ' ')

  # Append skill categories to config file
  cat >> .claude/reactree-ios-dev.local.md <<SKILLS

### Core Skills
$CORE_SKILLS

### Networking Skills
$NETWORK_SKILLS

### UI Skills
$UI_SKILLS

### Data/Model Skills
$DATA_SKILLS

### Testing Skills
$TEST_SKILLS

### Platform-Specific Skills
$PLATFORM_SKILLS

### Advanced Skills
$ADVANCED_SKILLS

SKILLS

  echo "Skill categories appended to configuration file"
else
  echo "No skills directory found, skipping skill categorization"
fi

echo ""
```

**Expected**: Configuration file created with project metadata, settings, and skill categorization.

---

## Phase 7: Initialize Memory Files

Create memory files if they don't exist:

```bash
echo "=== Memory System Initialization ==="
echo ""

# Working memory (24h TTL)
if [ ! -f .claude/reactree-memory.jsonl ]; then
  touch .claude/reactree-memory.jsonl
  echo '{"initialized": true, "timestamp": "'$(date -Iseconds)'", "project": "'$PROJECT_NAME'", "platform": "'$PLATFORM'"}' >> .claude/reactree-memory.jsonl
  echo "✅ Created .claude/reactree-memory.jsonl (working memory, 24h TTL)"
else
  echo ".claude/reactree-memory.jsonl already exists"
fi

# Episodic memory (permanent learning)
if [ ! -f .claude/reactree-episodes.jsonl ]; then
  touch .claude/reactree-episodes.jsonl
  echo "✅ Created .claude/reactree-episodes.jsonl (episodic learning, permanent)"
else
  echo ".claude/reactree-episodes.jsonl already exists"
fi

# Feedback state (FEEDBACK edges for self-correction)
if [ ! -f .claude/reactree-feedback.jsonl ]; then
  touch .claude/reactree-feedback.jsonl
  echo "✅ Created .claude/reactree-feedback.jsonl (FEEDBACK edge queue)"
else
  echo ".claude/reactree-feedback.jsonl already exists"
fi

# Control flow state (LOOP, CONDITIONAL nodes)
if [ ! -f .claude/reactree-state.jsonl ]; then
  touch .claude/reactree-state.jsonl
  echo "✅ Created .claude/reactree-state.jsonl (control flow state)"
else
  echo ".claude/reactree-state.jsonl already exists"
fi

echo ""
echo "Memory System:"
echo "  - Working Memory: Shared facts across agents (24h TTL)"
echo "  - Episodic Memory: Learned patterns for future use (permanent)"
echo "  - FEEDBACK State: Self-correcting test-driven cycles"
echo "  - Control Flow: LOOP and CONDITIONAL node execution tracking"
echo ""
```

**Expected**: Four JSONL memory files created for working memory, episodic learning, feedback loops, and control flow state.

---

## Phase 8: Status Report

After completing all phases, output a comprehensive status report:

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 ReAcTree iOS/tvOS Plugin Initialized!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Prerequisites:"
echo "  ✅ Plugin located at: $PLUGIN_ROOT"
if [ -f "$PLUGIN_ROOT/hooks/hooks.json" ]; then
  echo "  ✅ Hooks configured (SessionStart, UserPromptSubmit, PreToolUse, PostToolUse)"
else
  echo "  ⚠️  Hooks not found (skill discovery will be manual)"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Project Detected:"
echo "  📱 Project: $PROJECT_NAME"
echo "  🎯 Platform: $PLATFORM"
echo "  📂 Location: $XCODE_PROJECT"
echo "  🔧 Swift: $SWIFT_VERSION_NUMBER"
echo "  🛠️  Xcode: $XCODE_VERSION"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Skills Discovered:"

# Count and display skills by category
if [ -d ".claude/skills" ]; then
  total_skills=$(find .claude/skills -maxdepth 1 -type d 2>/dev/null | wc -l)
  total_skills=$((total_skills - 1))
  echo "  📦 Total: $total_skills skills"

  # Count by category
  core_count=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(swift-conventions|mvvm|clean-architecture)' | wc -l)
  network_count=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(alamofire|api|session)' | wc -l)
  ui_count=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(swiftui|design|atomic|navigation|theme)' | wc -l)
  test_count=$(ls -1 .claude/skills/ 2>/dev/null | grep -E '(xctest|quality)' | wc -l)

  echo "     📐 Core: $core_count"
  echo "     🌐 Networking: $network_count"
  echo "     🎨 UI/Design: $ui_count"
  echo "     🧪 Testing: $test_count"
else
  echo "  ⚠️  No skills directory found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Tools Status:"
if command -v swiftlint >/dev/null 2>&1; then
  echo "  ✅ SwiftLint: $(swiftlint version)"
else
  echo "  ⚠️  SwiftLint: Not installed"
  echo "     Install: brew install swiftlint"
fi

if command -v xcodegen >/dev/null 2>&1; then
  echo "  ✅ Xcodegen: $(xcodegen --version)"
else
  echo "  ℹ️  Xcodegen: Not installed (optional)"
fi

if [ -f ".swiftlint.yml" ]; then
  echo "  ✅ SwiftLint config: .swiftlint.yml created"
else
  echo "  ℹ️  SwiftLint config: Not created (using defaults)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration:"
echo "  ✅ Config file: .claude/reactree-ios-dev.local.md"
echo "  📊 Smart Detection: ENABLED (suggest mode)"
echo "  🎚️  Annoyance Threshold: medium"
echo "  🎯 Coverage Threshold: 80%"
echo "  🔧 Platform: $PLATFORM"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Rules System:"
if [ -d ".claude/rules" ]; then
  rule_count=$(find .claude/rules -name '*.md' -type f 2>/dev/null | wc -l)
  echo "  ✅ Rules directory: .claude/rules/"
  echo "  📁 Rule categories: core, presentation, design-system, testing, quality-gates"
  echo "  📄 Total rules: $rule_count"
  echo "  💡 Path-specific rules automatically load based on file type"
else
  echo "  ⚠️  Rules directory: Not found"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Memory Initialized:"
echo "  ✅ Working memory: .claude/reactree-memory.jsonl (24h TTL)"
echo "  ✅ Episodic memory: .claude/reactree-episodes.jsonl (permanent)"
echo "  ✅ Feedback state: .claude/reactree-feedback.jsonl (self-correction)"
echo "  ✅ Control flow state: .claude/reactree-state.jsonl (LOOP/CONDITIONAL)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Available Commands:"
echo "  /ios-dev         - Full development workflow with parallel execution"
echo "  /ios-feature     - Feature-driven development with user stories"
echo "  /ios-debug       - Systematic debugging workflow"
echo "  /ios-refactor    - Safe refactoring with test preservation"
echo "  /reactree-ios-init - Re-run initialization (this command)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Auto-Triggering Examples:"
echo "  \"Add user authentication\"        → suggests /ios-dev"
echo "  \"Fix the crash on app launch\"   → suggests /ios-debug"
echo "  \"Refactor UserViewModel to MVVM\" → suggests /ios-refactor"
echo "  \"Find LoginService file\"         → routes to file-finder agent"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Ready to use! Try one of the commands above or just describe what you want to build."
echo ""
```

**Expected**: Comprehensive status report showing all initialization results, tool status, skill count, configuration details, and available commands.

---

## Error Handling

If any phase fails, provide clear error messages:

### Plugin Location Not Detected

```
❌ Plugin Location Not Detected

The CLAUDE_PLUGIN_ROOT environment variable is not set and no local
plugin installation was found at .claude/plugins/reactree-ios-dev/

This usually means:
  1. The plugin is not properly installed
  2. You're not in a Claude Code session (try running from Claude Code)
  3. The plugin was manually copied but not to the expected location

To fix:
  - Ensure the plugin is installed via Claude Code plugin system
  - Or copy the plugin to .claude/plugins/reactree-ios-dev/
  - Or set CLAUDE_PLUGIN_ROOT manually for testing
```

### No Xcode Project Found

```
❌ No Xcode Project Found

Could not find *.xcodeproj or *.xcworkspace in the current directory.

This command must be run from the root of an Xcode project.

Expected structure:
  MyApp.xcodeproj/           # Xcode project file
  MyApp/
    ├── App/                 # Entry point
    ├── Core/                # Core layer (Services, Managers)
    ├── Presentation/        # Presentation layer (Views, ViewModels)
    └── DesignSystem/        # Design System (Components, Theme)

To fix:
  - cd to your Xcode project root directory
  - Ensure you have a .xcodeproj or .xcworkspace file
  - Run /reactree-ios-init again
```

### Swift Version Too Old

```
⚠️  Swift Version Check

Detected Swift version: {version}
Minimum recommended: Swift 5.7

Some features may not be available with older Swift versions:
  - async/await patterns require Swift 5.5+
  - Structured concurrency requires Swift 5.5+
  - @MainActor requires Swift 5.5+
  - Some SwiftUI features require Swift 5.7+

Recommendation:
  - Update Xcode to latest version
  - Or continue with limited feature set

Plugin will continue initialization...
```

### SwiftLint Not Installed

```
⚠️  SwiftLint Not Found

SwiftLint is recommended for code quality validation but not required.

Install SwiftLint:
  brew install swiftlint

Or visit: https://github.com/realm/SwiftLint

Plugin will continue without SwiftLint validation.
You can install it later and re-run /reactree-ios-init to configure.
```

---

## Important Notes

### Platform Detection

The init command automatically detects your platform (iOS vs tvOS) by examining Info.plist files for `UIDeviceFamily` values:
- `1` = iPhone
- `2` = iPad
- `3` = tvOS

This detection informs:
- Skill recommendations (tvOS-specific skills for tvOS projects)
- Platform-specific patterns in agents
- Build validation commands
- Test coverage strategies

### Memory System

The 4 memory files serve different purposes:

1. **reactree-memory.jsonl** (Working Memory, 24h TTL)
   - Shared facts discovered during codebase inspection
   - Architecture patterns found
   - Naming conventions detected
   - Dependencies identified
   - Expires after 24 hours to stay fresh

2. **reactree-episodes.jsonl** (Episodic Memory, Permanent)
   - Successful implementation patterns
   - Lessons learned from past features
   - Performance optimizations that worked
   - Reusable across similar future tasks
   - Never expires (learns over time)

3. **reactree-feedback.jsonl** (FEEDBACK Edge Queue)
   - Test failures that need fixing
   - Build errors to resolve
   - Quality gate violations
   - Creates self-correcting cycles
   - Cleared when issues resolved

4. **reactree-state.jsonl** (Control Flow State)
   - LOOP node iteration counts
   - CONDITIONAL branch evaluations
   - Cached condition results (5-min TTL)
   - Cycle detection for loops
   - Execution history

### Rules vs Skills

**Skills** provide comprehensive guidance on patterns and best practices:
- Loaded contextually based on task
- 200-500 lines of in-depth guidance
- Cover architecture, patterns, examples
- Project-agnostic (general iOS/tvOS knowledge)

**Rules** provide file-specific, path-based enforcement:
- Automatically load based on file path
- 20-50 lines of focused guidance
- Quick reference while editing
- Can be project-specific

Use both together for optimal results:
- Skills for understanding patterns
- Rules for enforcement while coding

### Hooks System

If the plugin includes hooks (v2.0.0+), the following automation is enabled:

**SessionStart Hook:**
- Automatically discovers skills on every session
- Updates .claude/reactree-ios-dev.local.md
- Creates working memory entry
- No manual skill discovery needed

**UserPromptSubmit Hook:**
- Analyzes prompts for workflow routing
- Suggests /ios-dev for feature requests
- Suggests /ios-debug for debugging
- Suggests /ios-refactor for refactoring

**PreToolUse Hook (*.swift files):**
- Validates Swift syntax before edits
- Checks MVVM patterns (View → ViewModel separation)
- Warns about common pitfalls (force unwrapping)

**PostToolUse Hook (*.swift files):**
- Runs SwiftLint on written files
- Validates against rules
- Reports violations as warnings

### Re-running Initialization

You can safely re-run `/reactree-ios-init` anytime:
- Idempotent (won't break existing setup)
- Preserves existing skills/rules (unless you choose to replace)
- Updates configuration file with latest metadata
- Refreshes memory initialization
- Validates tool installations

Use cases for re-running:
- After updating the plugin to a new version
- After adding new bundled skills to the plugin
- To refresh configuration after project changes
- To validate tool setup after Xcode updates

---

## Next Steps

After initialization:

1. **Explore available commands:**
   - Try `/ios-dev add user authentication` for a full workflow
   - Or just describe what you want: "Create a login screen with email and password"

2. **Customize configuration:**
   - Edit `.claude/reactree-ios-dev.local.md` to adjust settings
   - Modify `.swiftlint.yml` to match your team's style guide
   - Add project-specific rules to `.claude/rules/`

3. **Add domain-specific skills:**
   - Create `.claude/skills/my-app-patterns/` for your app's patterns
   - Document your architecture decisions
   - Share patterns across your team

4. **Review quality gates:**
   - Ensure SwiftLint runs in CI/CD
   - Configure test coverage reporting
   - Set up automated builds

5. **Learn the workflow:**
   - Read examples in `$PLUGIN_ROOT/examples/`
   - Review agent descriptions in `$PLUGIN_ROOT/agents/`
   - Understand skill content in `.claude/skills/`

---

## Troubleshooting

### "Skills not loading automatically"

If skills aren't being discovered on session start:
1. Check if hooks are configured: `cat $PLUGIN_ROOT/hooks/hooks.json`
2. Verify .claude/skills/ directory exists: `ls -la .claude/skills/`
3. Check permissions: `ls -la .claude/`
4. Re-run `/reactree-ios-init` to regenerate configuration

### "SwiftLint validation not working"

If SwiftLint isn't running during workflow:
1. Verify installation: `which swiftlint`
2. Check .swiftlint.yml exists: `ls -la .swiftlint.yml`
3. Test manually: `swiftlint lint --strict`
4. Check PostToolUse hook is configured (v2.0.0+)

### "Memory files growing too large"

Working memory (.claude/reactree-memory.jsonl) should auto-expire after 24h:
1. Check file size: `ls -lh .claude/reactree-memory.jsonl`
2. Manually clear if needed: `rm .claude/reactree-memory.jsonl && touch .claude/reactree-memory.jsonl`
3. Re-run `/reactree-ios-init` to reset

### "Platform detection wrong"

If the init command detects the wrong platform:
1. Check Info.plist manually: `find . -name Info.plist -exec grep UIDeviceFamily {} \;`
2. Manually edit `.claude/reactree-ios-dev.local.md` and set `platform: iOS` or `platform: tvOS`
3. Re-run workflow commands which will pick up the corrected platform

---

## Advanced Configuration

### Custom Skill Categories

Edit `.claude/reactree-ios-dev.local.md` to add custom skill categories:

```markdown
### Domain-Specific Skills
my-app-authentication my-app-payment my-app-analytics

### Third-Party Integration Skills
firebase-integration stripe-integration mixpanel-integration
```

### Coverage Threshold Adjustment

Modify the coverage threshold if 80% is too high/low for your project:

```markdown
---
test_coverage_threshold: 70
---
```

### Detection Mode Configuration

Change how aggressively the plugin suggests workflows:

```markdown
---
detection_mode: inject      # Auto-activates workflows (most aggressive)
detection_mode: suggest     # Shows suggestions (default)
detection_mode: disabled    # Manual activation only (least aggressive)
---
```

### Platform Override

If you're building a universal app (iOS + tvOS):

```markdown
---
platform: both
---
```

The plugin will then include patterns for both platforms in agent instructions.

---

## Summary

The `/reactree-ios-init` command initializes your Xcode project with:

✅ Plugin validation and location detection
✅ Xcode project and platform detection (iOS/tvOS)
✅ 27 bundled iOS/tvOS skills (optional copy)
✅ SwiftLint configuration and tool validation
✅ 12 path-specific rules for context-aware guidance
✅ Configuration file with project metadata
✅ 4 memory files for working memory, episodic learning, feedback loops, and control flow
✅ Comprehensive status report

After initialization, you're ready to use the full ReAcTree workflow with:
- Parallel execution (3-group strategy)
- Quality gates (SwiftLint, build, 80% coverage)
- Beads task tracking
- MVVM + Clean Architecture patterns
- iOS and tvOS platform support

Try `/ios-dev [feature description]` to get started!
