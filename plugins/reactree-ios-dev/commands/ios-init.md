# iOS Init Command

Initialize the ReAcTree iOS/tvOS development plugin in your project by copying agents, rules, and skills to your working directory.

## Command: `/ios-init`

### Description

Sets up the ReAcTree iOS/tvOS development environment in your current iOS/tvOS project by:
- Copying all 14 specialized agents to `.claude/agents/`
- Copying all 12 rules to `.claude/rules/`
- Copying all 27 skills to `.claude/skills/`
- Creating necessary directory structure
- Initializing memory systems (4 JSONL files)
- Generating project configuration file

### Usage

Simply type:
```
/ios-init
```

The command will automatically detect your Xcode project and set up the complete development environment.

---

## Initialization Workflow

### Phase 1: Validate Environment

**Check for Xcode Project:**
```bash
# Search for .xcodeproj or .xcworkspace
if ls *.xcodeproj 1> /dev/null 2>&1; then
  PROJECT_TYPE="xcodeproj"
  PROJECT_NAME=$(ls *.xcodeproj | head -1 | sed 's/.xcodeproj//')
elif ls *.xcworkspace 1> /dev/null 2>&1; then
  PROJECT_TYPE="xcworkspace"
  PROJECT_NAME=$(ls *.xcworkspace | head -1 | sed 's/.xcworkspace//')
else
  echo "❌ Error: No Xcode project (.xcodeproj or .xcworkspace) found"
  exit 1
fi

echo "✅ Found Xcode project: $PROJECT_NAME.$PROJECT_TYPE"
```

**Detect Platform:**
```bash
# Check Info.plist for supported platforms
PLIST_PATH="$PROJECT_NAME/Info.plist"

if [ -f "$PLIST_PATH" ]; then
  # Check for iOS
  if /usr/libexec/PlistBuddy -c "Print :UIDeviceFamily" "$PLIST_PATH" 2>/dev/null | grep -q "1\|2"; then
    PLATFORM="iOS"
  fi

  # Check for tvOS
  if /usr/libexec/PlistBuddy -c "Print :UIDeviceFamily" "$PLIST_PATH" 2>/dev/null | grep -q "3"; then
    PLATFORM="tvOS"
  fi

  echo "✅ Platform detected: $PLATFORM"
else
  echo "⚠️  Warning: Info.plist not found, assuming iOS/tvOS universal"
  PLATFORM="iOS/tvOS"
fi
```

**Check Swift Version:**
```bash
SWIFT_VERSION=$(swift --version | grep -o 'Swift version [0-9.]*' | grep -o '[0-9.]*')
echo "✅ Swift version: $SWIFT_VERSION"

# Validate minimum Swift version (5.7+)
REQUIRED_VERSION="5.7"
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$SWIFT_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
  echo "❌ Error: Swift $REQUIRED_VERSION or higher required (found $SWIFT_VERSION)"
  exit 1
fi
```

---

### Phase 2: Create Directory Structure

**Create .claude directories:**
```bash
echo "📁 Creating directory structure..."

# Create main directories
mkdir -p .claude/agents
mkdir -p .claude/skills
mkdir -p .claude/rules/core
mkdir -p .claude/rules/presentation
mkdir -p .claude/rules/design-system
mkdir -p .claude/rules/testing
mkdir -p .claude/rules/quality-gates

echo "✅ Directory structure created"
```

---

### Phase 3: Copy Agents (14 total)

**Identify plugin location:**
```bash
# Plugin should be in .claude/plugins/reactree-ios-dev
PLUGIN_DIR=".claude/plugins/reactree-ios-dev"

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "❌ Error: Plugin not found at $PLUGIN_DIR"
  echo "Please copy the reactree-ios-dev plugin to .claude/plugins/ first"
  exit 1
fi

echo "✅ Plugin found at $PLUGIN_DIR"
```

**Copy all agents:**
```bash
echo "🤖 Copying agents..."

# Copy all agent files
cp "$PLUGIN_DIR/agents/workflow-orchestrator.md" .claude/agents/
cp "$PLUGIN_DIR/agents/codebase-inspector.md" .claude/agents/
cp "$PLUGIN_DIR/agents/ios-planner.md" .claude/agents/
cp "$PLUGIN_DIR/agents/implementation-executor.md" .claude/agents/
cp "$PLUGIN_DIR/agents/test-oracle.md" .claude/agents/
cp "$PLUGIN_DIR/agents/core-lead.md" .claude/agents/
cp "$PLUGIN_DIR/agents/presentation-lead.md" .claude/agents/
cp "$PLUGIN_DIR/agents/design-system-lead.md" .claude/agents/
cp "$PLUGIN_DIR/agents/quality-guardian.md" .claude/agents/
cp "$PLUGIN_DIR/agents/file-finder.md" .claude/agents/
cp "$PLUGIN_DIR/agents/log-analyzer.md" .claude/agents/
cp "$PLUGIN_DIR/agents/swiftgen-coordinator.md" .claude/agents/
cp "$PLUGIN_DIR/agents/accessibility-specialist.md" .claude/agents/
cp "$PLUGIN_DIR/agents/performance-profiler.md" .claude/agents/

AGENT_COUNT=$(ls -1 .claude/agents/*.md 2>/dev/null | wc -l)
echo "✅ Copied $AGENT_COUNT agents to .claude/agents/"
```

**Agents copied:**
1. `workflow-orchestrator.md` - Master coordinator for 6-phase workflows
2. `codebase-inspector.md` - Analyzes Swift/SwiftUI patterns
3. `ios-planner.md` - Plans MVVM implementation
4. `implementation-executor.md` - Coordinates specialist agents
5. `test-oracle.md` - Validates tests and coverage
6. `core-lead.md` - Implements Core layer
7. `presentation-lead.md` - Implements Presentation layer
8. `design-system-lead.md` - Implements Design System
9. `quality-guardian.md` - Enforces quality gates
10. `file-finder.md` - Fast file discovery
11. `log-analyzer.md` - Analyzes Xcode logs
12. `swiftgen-coordinator.md` - SwiftGen integration
13. `accessibility-specialist.md` - Accessibility testing
14. `performance-profiler.md` - Performance profiling

---

### Phase 4: Copy Skills (27 total)

**Copy all skills:**
```bash
echo "📚 Copying skills..."

# Core Skills
cp -r "$PLUGIN_DIR/skills/swift-conventions" .claude/skills/
cp -r "$PLUGIN_DIR/skills/swiftui-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/mvvm-architecture" .claude/skills/
cp -r "$PLUGIN_DIR/skills/clean-architecture-ios" .claude/skills/

# Networking Skills
cp -r "$PLUGIN_DIR/skills/alamofire-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/api-integration" .claude/skills/

# UI Skills
cp -r "$PLUGIN_DIR/skills/navigation-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/atomic-design-ios" .claude/skills/
cp -r "$PLUGIN_DIR/skills/theme-management" .claude/skills/

# Data Skills
cp -r "$PLUGIN_DIR/skills/model-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/core-data-patterns" .claude/skills/

# Testing Skills
cp -r "$PLUGIN_DIR/skills/xctest-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/code-quality-gates" .claude/skills/

# Advanced Skills
cp -r "$PLUGIN_DIR/skills/error-handling-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/concurrency-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/accessibility-patterns" .claude/skills/
cp -r "$PLUGIN_DIR/skills/performance-optimization" .claude/skills/
cp -r "$PLUGIN_DIR/skills/dependency-injection" .claude/skills/
cp -r "$PLUGIN_DIR/skills/coordinator-pattern" .claude/skills/
cp -r "$PLUGIN_DIR/skills/combine-reactive" .claude/skills/
cp -r "$PLUGIN_DIR/skills/push-notifications" .claude/skills/
cp -r "$PLUGIN_DIR/skills/app-lifecycle" .claude/skills/
cp -r "$PLUGIN_DIR/skills/security-best-practices" .claude/skills/

# Platform Skills
cp -r "$PLUGIN_DIR/skills/tvos-specific-patterns" .claude/skills/

# Tools
cp -r "$PLUGIN_DIR/skills/swiftgen-integration" .claude/skills/
cp -r "$PLUGIN_DIR/skills/localization-ios" .claude/skills/
cp -r "$PLUGIN_DIR/skills/session-management" .claude/skills/

SKILL_COUNT=$(ls -1d .claude/skills/*/ 2>/dev/null | wc -l)
echo "✅ Copied $SKILL_COUNT skills to .claude/skills/"
```

**Skills categorization:**
- **Core (4):** swift-conventions, swiftui-patterns, mvvm-architecture, clean-architecture-ios
- **Networking (2):** alamofire-patterns, api-integration
- **UI (3):** navigation-patterns, atomic-design-ios, theme-management
- **Data (2):** model-patterns, core-data-patterns
- **Testing (2):** xctest-patterns, code-quality-gates
- **Advanced (13):** error-handling, concurrency, accessibility, performance, dependency-injection, coordinator, combine-reactive, push-notifications, app-lifecycle, security
- **Platform (1):** tvos-specific-patterns
- **Tools (3):** swiftgen-integration, localization-ios, session-management

---

### Phase 5: Copy Rules (12 total)

**Copy all rules:**
```bash
echo "📋 Copying rules..."

# Core layer rules
cp "$PLUGIN_DIR/rules/core/services.md" .claude/rules/core/
cp "$PLUGIN_DIR/rules/core/managers.md" .claude/rules/core/
cp "$PLUGIN_DIR/rules/core/networking.md" .claude/rules/core/

# Presentation layer rules
cp "$PLUGIN_DIR/rules/presentation/views.md" .claude/rules/presentation/
cp "$PLUGIN_DIR/rules/presentation/viewmodels.md" .claude/rules/presentation/
cp "$PLUGIN_DIR/rules/presentation/models.md" .claude/rules/presentation/

# Design System rules
cp "$PLUGIN_DIR/rules/design-system/components.md" .claude/rules/design-system/
cp "$PLUGIN_DIR/rules/design-system/resources.md" .claude/rules/design-system/

# Testing rules
cp "$PLUGIN_DIR/rules/testing/unit-tests.md" .claude/rules/testing/
cp "$PLUGIN_DIR/rules/testing/ui-tests.md" .claude/rules/testing/

# Quality gates rules
cp "$PLUGIN_DIR/rules/quality-gates/swiftlint.md" .claude/rules/quality-gates/
cp "$PLUGIN_DIR/rules/quality-gates/build-validation.md" .claude/rules/quality-gates/

RULE_COUNT=$(find .claude/rules -name "*.md" 2>/dev/null | wc -l)
echo "✅ Copied $RULE_COUNT rules to .claude/rules/"
```

**Rules copied:**
- **Core (3):** services.md, managers.md, networking.md
- **Presentation (3):** views.md, viewmodels.md, models.md
- **Design System (2):** components.md, resources.md
- **Testing (2):** unit-tests.md, ui-tests.md
- **Quality Gates (2):** swiftlint.md, build-validation.md

---

### Phase 6: Initialize Memory Systems

**Create memory JSONL files:**
```bash
echo "💾 Initializing memory systems..."

# Create working memory (24h TTL)
touch .claude/reactree-memory.jsonl

# Create episodic memory (permanent)
touch .claude/reactree-episodes.jsonl

# Create feedback queue (FEEDBACK edges)
touch .claude/reactree-feedback.jsonl

# Create control flow state (LOOP/CONDITIONAL)
touch .claude/reactree-state.jsonl

echo "✅ Created 4 memory system files"
```

**Memory system files:**
1. `.claude/reactree-memory.jsonl` - Working memory (24h TTL)
2. `.claude/reactree-episodes.jsonl` - Episodic learning (permanent)
3. `.claude/reactree-feedback.jsonl` - FEEDBACK edge queue
4. `.claude/reactree-state.jsonl` - Control flow state

---

### Phase 7: Generate Project Configuration

**Create local configuration file:**
```bash
echo "⚙️  Generating project configuration..."

cat > .claude/reactree-ios-dev.local.md <<EOF
# ReAcTree iOS/tvOS Development - Local Configuration

## Project Information

**Project Name:** $PROJECT_NAME
**Project Type:** $PROJECT_TYPE
**Platform:** $PLATFORM
**Swift Version:** $SWIFT_VERSION
**Initialized:** $(date +"%Y-%m-%d %H:%M:%S")

---

## Installed Components

### Agents (14 total)

**Workflow Orchestration:**
- workflow-orchestrator - Master coordinator for 6-phase ReAcTree workflows
- codebase-inspector - Analyzes Swift/SwiftUI patterns and architecture
- ios-planner - Plans MVVM implementation with parallel execution

**Implementation:**
- implementation-executor - Coordinates specialist agents
- core-lead - Implements Core layer (Services, Managers, Networking)
- presentation-lead - Implements Presentation layer (Views, ViewModels)
- design-system-lead - Implements Design System (Atomic Design components)

**Quality & Testing:**
- test-oracle - Validates tests and coverage (80% threshold)
- quality-guardian - Enforces quality gates (SwiftLint, build, tests)

**Utilities:**
- file-finder - Fast file discovery by pattern
- log-analyzer - Analyzes Xcode build logs and crash reports
- swiftgen-coordinator - SwiftGen configuration and validation
- accessibility-specialist - Accessibility testing and WCAG compliance
- performance-profiler - Performance profiling and optimization

---

### Skills (27 total)

**Core Skills (4):**
- swift-conventions - Swift 5 naming conventions and best practices
- swiftui-patterns - SwiftUI state management and platform-specific patterns
- mvvm-architecture - BaseViewModel and View-ViewModel binding
- clean-architecture-ios - Layer separation and dependency rules

**Networking Skills (2):**
- alamofire-patterns - NetworkRouter protocol and request handling
- api-integration - Service layer and API endpoint definitions

**UI Skills (3):**
- navigation-patterns - NavigationStack and NavigationPath
- atomic-design-ios - Atoms, Molecules, Organisms components
- theme-management - ThemeManager and SwiftGen integration

**Data Skills (2):**
- model-patterns - Codable protocol and model mapping
- core-data-patterns - NSPersistentContainer and repository pattern

**Testing Skills (2):**
- xctest-patterns - Unit, integration, and UI testing
- code-quality-gates - SwiftLint and build validation

**Advanced Skills (13):**
- error-handling-patterns - Swift Result type and error propagation
- concurrency-patterns - async/await and structured concurrency
- accessibility-patterns - VoiceOver support and WCAG compliance
- performance-optimization - SwiftUI performance and profiling
- dependency-injection - Constructor injection and DI patterns
- coordinator-pattern - Navigation coordination
- combine-reactive - Combine framework and reactive programming
- push-notifications - UNUserNotificationCenter and APNs
- app-lifecycle - App launch and background tasks
- security-best-practices - Keychain and secure coding

**Platform Skills (1):**
- tvos-specific-patterns - Focus engine and tvOS design

**Tool Skills (3):**
- swiftgen-integration - Type-safe asset generation
- localization-ios - LanguageManager and RTL support
- session-management - SessionManager and Keychain integration

---

### Rules (12 total)

**Core Layer (3):**
- core/services.md - Service layer Protocol-Oriented Programming
- core/managers.md - Manager Singleton patterns
- core/networking.md - NetworkRouter and Alamofire patterns

**Presentation Layer (3):**
- presentation/views.md - SwiftUI view structure and state management
- presentation/viewmodels.md - BaseViewModel and @Published properties
- presentation/models.md - Codable struct patterns

**Design System (2):**
- design-system/components.md - Atomic design hierarchy
- design-system/resources.md - SwiftGen resource access

**Testing (2):**
- testing/unit-tests.md - XCTest structure and naming
- testing/ui-tests.md - UI test patterns with accessibility IDs

**Quality Gates (2):**
- quality-gates/swiftlint.md - Linting rules and enforcement
- quality-gates/build-validation.md - Build success criteria

---

## Quality Gate Settings

**Test Coverage:** 80% minimum threshold
**Build Validation:** Xcodebuild clean build required
**SwiftLint:** Strict mode enabled
**Test Pyramid:** 70% unit, 20% integration, 10% UI

---

## Memory Systems

**Working Memory:** .claude/reactree-memory.jsonl (24h TTL)
**Episodic Memory:** .claude/reactree-episodes.jsonl (permanent)
**Feedback Queue:** .claude/reactree-feedback.jsonl
**Control Flow State:** .claude/reactree-state.jsonl

---

## Available Commands

- \`/ios-dev\` - Main development workflow with full orchestration
- \`/ios-feature\` - Feature-driven development workflow
- \`/ios-debug\` - Debugging and log analysis workflow
- \`/ios-refactor\` - Refactoring and code quality workflow

---

## Next Steps

1. Install SwiftLint: \`brew install swiftlint\`
2. Create .swiftlint.yml configuration if needed
3. Run your first workflow: \`/ios-dev add user authentication\`
4. Explore examples in plugin: .claude/plugins/reactree-ios-dev/examples/

---

**Plugin Version:** 2.0.0
**Documentation:** .claude/plugins/reactree-ios-dev/README.md
EOF

echo "✅ Created .claude/reactree-ios-dev.local.md"
```

---

### Phase 8: Install Dependencies (Optional)

**Check for SwiftLint:**
```bash
echo "🔍 Checking for SwiftLint..."

if command -v swiftlint &> /dev/null; then
  SWIFTLINT_VERSION=$(swiftlint version)
  echo "✅ SwiftLint installed: $SWIFTLINT_VERSION"
else
  echo "⚠️  SwiftLint not found"
  echo "Install with: brew install swiftlint"
  echo "SwiftLint is required for quality gates"
fi
```

**Check for SwiftGen:**
```bash
echo "🔍 Checking for SwiftGen..."

if command -v swiftgen &> /dev/null; then
  SWIFTGEN_VERSION=$(swiftgen --version)
  echo "✅ SwiftGen installed: $SWIFTGEN_VERSION"
else
  echo "ℹ️  SwiftGen not found (optional)"
  echo "Install with: brew install swiftgen"
  echo "SwiftGen provides type-safe asset access"
fi
```

---

### Phase 9: Final Summary

**Display installation summary:**
```bash
cat <<EOF

═══════════════════════════════════════════════════════════
  🎉 ReAcTree iOS/tvOS Development Plugin Initialized!
═══════════════════════════════════════════════════════════

Project: $PROJECT_NAME ($PLATFORM)
Swift Version: $SWIFT_VERSION

📦 Components Installed:
   ✅ 14 Specialized Agents
   ✅ 27 Comprehensive Skills
   ✅ 12 Rules (Core, Presentation, Design System, Testing)
   ✅ 4 Memory System Files
   ✅ Local Configuration File

📁 Directory Structure:
   .claude/
   ├── agents/          (14 files)
   ├── skills/          (27 directories)
   ├── rules/           (12 files across 5 categories)
   ├── reactree-memory.jsonl
   ├── reactree-episodes.jsonl
   ├── reactree-feedback.jsonl
   ├── reactree-state.jsonl
   └── reactree-ios-dev.local.md

🚀 Available Commands:
   /ios-dev         - Main development workflow
   /ios-feature     - Feature-driven development
   /ios-debug       - Debugging workflow
   /ios-refactor    - Refactoring workflow

📚 Documentation:
   README: .claude/plugins/reactree-ios-dev/README.md
   Examples: .claude/plugins/reactree-ios-dev/examples/
   Config: .claude/reactree-ios-dev.local.md

⚙️  Next Steps:
   1. Install SwiftLint: brew install swiftlint
   2. (Optional) Install SwiftGen: brew install swiftgen
   3. Run your first workflow: /ios-dev add user authentication

═══════════════════════════════════════════════════════════

For customization options, see:
.claude/plugins/reactree-ios-dev/CUSTOMIZATION.md

EOF
```

---

## Troubleshooting

### Issue: Plugin Not Found

**Error:**
```
❌ Error: Plugin not found at .claude/plugins/reactree-ios-dev
```

**Solution:**
```bash
# Copy plugin to your project first
mkdir -p .claude/plugins
cp -r /path/to/reactree-ios-dev .claude/plugins/
```

### Issue: No Xcode Project Found

**Error:**
```
❌ Error: No Xcode project (.xcodeproj or .xcworkspace) found
```

**Solution:**
```bash
# Run /ios-init from your Xcode project root directory
cd /path/to/your/xcode/project
/ios-init
```

### Issue: Swift Version Too Old

**Error:**
```
❌ Error: Swift 5.7 or higher required (found 5.5)
```

**Solution:**
```bash
# Update Xcode to latest version
# Check Swift version
swift --version

# Or set minimum deployment target in Xcode project settings
```

### Issue: Permission Denied

**Error:**
```
cp: .claude/agents/workflow-orchestrator.md: Permission denied
```

**Solution:**
```bash
# Ensure you have write permissions
chmod -R u+w .claude/

# Or run with appropriate permissions
sudo /ios-init  # Not recommended
```

---

## Manual Installation (Alternative)

If `/ios-init` fails, you can manually copy files:

```bash
# 1. Create directories
mkdir -p .claude/agents .claude/skills .claude/rules

# 2. Copy agents
cp .claude/plugins/reactree-ios-dev/agents/*.md .claude/agents/

# 3. Copy skills
cp -r .claude/plugins/reactree-ios-dev/skills/* .claude/skills/

# 4. Copy rules
cp -r .claude/plugins/reactree-ios-dev/rules/* .claude/rules/

# 5. Initialize memory files
touch .claude/reactree-memory.jsonl
touch .claude/reactree-episodes.jsonl
touch .claude/reactree-feedback.jsonl
touch .claude/reactree-state.jsonl
```

---

## What Gets Installed

### Agents (14 files, ~10,000 lines)
Specialized AI assistants for workflow orchestration, code generation, testing, and quality gates.

### Skills (27 directories, ~10,000 lines)
Comprehensive knowledge modules covering Swift conventions, SwiftUI patterns, MVVM architecture, networking, testing, accessibility, performance, and more.

### Rules (12 files, ~2,500 lines)
Architectural constraints and conventions for Core layer, Presentation layer, Design System, Testing, and Quality Gates.

### Memory Systems (4 JSONL files)
Working memory (24h TTL), episodic learning (permanent), feedback queue, and control flow state.

### Configuration (1 file)
Local project configuration with discovered skills inventory, quality gate settings, and available commands.

---

## Post-Installation

After running `/ios-init`, you can immediately start building features:

```
/ios-dev add user authentication with JWT tokens
```

The plugin will:
1. ✅ Detect project structure
2. ✅ Parse requirements
3. ✅ Analyze existing patterns
4. ✅ Plan MVVM implementation
5. ✅ Generate Core layer (Services, Managers)
6. ✅ Generate Presentation layer (Views, ViewModels)
7. ✅ Generate Design System components
8. ✅ Generate comprehensive tests
9. ✅ Run quality gates (SwiftLint, build, coverage)

---

**Version:** 2.0.0
**Plugin:** ReAcTree iOS/tvOS Development
**Author:** Mohamad Kaakati
**License:** MIT
