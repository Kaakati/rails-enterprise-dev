# ReAcTree iOS/tvOS Development Plugin

Multi-agent orchestration for iOS and tvOS development with SwiftUI, MVVM, Clean Architecture, comprehensive quality gates, and automated workflows.

## 🚀 Features

- **iOS & tvOS Support**: Universal plugin for iPhone, iPad, and Apple TV development
- **Clean Architecture + MVVM**: Enforces proper layer separation and testability
- **SwiftUI-Only**: Modern SwiftUI patterns with state management best practices
- **27 Comprehensive Skills**: Covers everything from Swift conventions to accessibility patterns
- **14 Specialized Agents**: Workflow orchestration, quality gates, performance profiling, and more
- **Automated Init Command**: `/ios-init` for one-command project setup
- **Hooks System**: Auto-discovery, validation, and workflow routing
- **Quality Gates**: SwiftLint, build validation, 80% test coverage enforcement
- **Multi-Agent Workflow**: Specialized agents for Core, Presentation, and Design System layers
- **Beads Integration**: Track multi-session work with automatic task creation
- **Parallel Execution**: 30-50% faster workflows through intelligent parallelization
- **Working Memory**: Eliminates redundant codebase analysis across agents
- **Episodic Learning**: Reuses proven approaches for similar features

## 📦 Installation

### Automated Install (Easiest)

**Option 1: Using install script**

```bash
# Clone the repository
git clone https://github.com/kaakati/ios-enterprise-dev.git
cd ios-enterprise-dev/plugins/reactree-ios-dev

# Run the install script
./install.sh
```

The install script will:
- ✅ Detect your Xcode project location
- ✅ Copy all plugin files to `.claude/plugins/`
- ✅ Verify installation (14 agents, 27 skills, 12 rules)
- ✅ Check dependencies (Xcode, Swift, SwiftLint)
- ✅ Display next steps

**Option 2: Manual plugin copy + init command**

1. **Copy Plugin to Project:**

```bash
cd /path/to/your/ios/project
mkdir -p .claude/plugins
cp -r path/to/reactree-ios-dev .claude/plugins/
```

2. **Run Init Command:**

```
/ios-init
```

The init command will:
- ✅ Detect Xcode project and Swift version
- ✅ Validate platform support (iOS/tvOS)
- ✅ Copy agents to `.claude/agents/` (14 agents)
- ✅ Copy skills to `.claude/skills/` (27 skills)
- ✅ Copy rules to `.claude/rules/` (12 rules)
- ✅ Initialize memory systems (4 JSONL files)
- ✅ Generate project configuration file

**Skills Installed:**
- **Core**: swift-conventions, mvvm-architecture, clean-architecture-ios
- **Networking**: alamofire-patterns, api-integration
- **UI**: swiftui-patterns, navigation-patterns, atomic-design-ios, theme-management
- **Data**: model-patterns, core-data-patterns, codable-patterns
- **Testing**: xctest-patterns, test-oracle
- **Advanced**: concurrency-patterns, error-handling-patterns, accessibility-patterns, performance-optimization, security-best-practices
- **Tools**: swiftgen-integration, localization-ios
- **tvOS**: tvos-specific-patterns

### Manual Installation (Advanced)

If you prefer complete manual setup:

```bash
cd /path/to/your/ios/project

# Create directory structure
mkdir -p .claude/plugins
mkdir -p .claude/agents
mkdir -p .claude/skills
mkdir -p .claude/rules

# Copy plugin
cp -r path/to/reactree-ios-dev .claude/plugins/

# Copy components
cp .claude/plugins/reactree-ios-dev/agents/*.md .claude/agents/
cp -r .claude/plugins/reactree-ios-dev/skills/* .claude/skills/
cp -r .claude/plugins/reactree-ios-dev/rules/* .claude/rules/

# Initialize memory files
touch .claude/reactree-memory.jsonl
touch .claude/reactree-episodes.jsonl
touch .claude/reactree-feedback.jsonl
touch .claude/reactree-state.jsonl
```

### Requirements

- Xcode 14.0+
- iOS 15.0+ / tvOS 15.0+
- Swift 5.7+
- SwiftLint (install with `brew install swiftlint`)
- CocoaPods or Swift Package Manager (optional)

## 🎯 Quick Start

### Initialize Your Project

After copying the plugin, initialize it for your specific project:

```
/ios-init
```

Then start building features:

```
/ios-dev add user authentication with JWT tokens
```

The plugin will:
1. ✅ Detect Xcode project root
2. ✅ Parse requirements into user stories
3. ✅ Analyze existing MVVM patterns (using discovered skills)
4. ✅ Plan implementation with Clean Architecture
5. ✅ Create Core layer (Services, Managers, NetworkRouters)
6. ✅ Create Presentation layer (Views, ViewModels, Models)
7. ✅ Create Design System components
8. ✅ Generate comprehensive XCTests
9. ✅ Run quality gates (SwiftLint, build, 80% coverage)
10. ✅ Create beads epic for multi-session tracking

## 📚 Available Commands

### `/ios-dev` - Main Development Workflow

Full-featured development with all quality gates and parallel execution.

**Examples:**

**Authentication:**
```
/ios-dev add user authentication with JWT tokens
/ios-dev implement OAuth2 login with Apple Sign-In
/ios-dev create biometric authentication (Face ID/Touch ID)
```

**API Integration:**
```
/ios-dev create product catalog with REST API
/ios-dev implement GraphQL client for posts
/ios-dev add WebSocket real-time chat
```

**SwiftUI Features:**
```
/ios-dev create custom video player with AVKit
/ios-dev implement dark mode with theme switching
/ios-dev build onboarding flow with SwiftUI
```

**tvOS-Specific:**
```
/ios-dev implement focus-based side menu for tvOS
/ios-dev add top shelf support for tvOS
/ios-dev create tvOS hero carousel with focus handling
```

**State Management:**
```
/ios-dev add shopping cart with @StateObject
/ios-dev implement multi-step form with validation
/ios-dev create global settings with @EnvironmentObject
```

### `/ios-feature` - Feature-Driven Development

Focused on complete vertical slices (Core → Presentation → Design System).

### `/ios-debug` - Debugging Workflow

Analyzes logs, crashes, and network issues.

### `/ios-refactor` - Refactoring Workflow

Code quality improvements and architectural modernization.

## 🏗️ Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│       Presentation Layer                 │
│   Views → ViewModels → Models            │
│          (SwiftUI + MVVM)                │
├─────────────────────────────────────────┤
│          Core Layer                      │
│  Services → Managers → Networking        │
│        (Business Logic)                  │
├─────────────────────────────────────────┤
│       Design System Layer                │
│   Atoms → Molecules → Organisms          │
│      (Atomic Design + Theme)             │
└─────────────────────────────────────────┘
```

### MVVM Pattern

**BaseViewModel:**
```swift
@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: Error?
}
```

**View-ViewModel Binding:**
```swift
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.loadData() }
    }
}
```

## 🛡️ Quality Gates

### SwiftLint
```bash
swiftlint lint --strict
```

**Enforces:**
- Line length limits (120 chars)
- No force unwrapping
- Proper access control
- Trailing closures

### Build Validation
```bash
xcodebuild clean build -scheme AppScheme
```

**Validates:**
- Zero build errors
- Warnings < 10
- CocoaPods integration

### Test Coverage
```bash
xcodebuild test -enableCodeCoverage YES
```

**Requires:**
- 80% minimum coverage
- Test pyramid (70% unit, 20% integration, 10% UI)
- All critical paths covered

### SwiftGen
```bash
swiftgen config lint
```

**Validates:**
- Type-safe asset access
- Localization strings
- Color definitions

## 📱 Platform Support

### iOS-Specific Patterns
- Tab bar navigation
- Touch gestures
- Haptic feedback
- Size classes (compact/regular)

### tvOS-Specific Patterns
- Focus management (@FocusState)
- Remote control handling
- Top shelf support
- Parallax effects
- Large card UI patterns

### Universal Patterns
- Platform detection (#if os(tvOS))
- Adaptive layouts
- Shared ViewModels with platform-specific UI

## 🧠 Memory Systems

### Working Memory (24h TTL)
- Stores verified facts discovered during inspection
- Shared across all agents in current session
- Eliminates redundant codebase analysis
- 100% consistency across agents

### Episodic Memory (Permanent)
- Learns from successful executions
- Reuses proven approaches for similar tasks
- 15-30% faster on repeat patterns

## 📊 Parallel Execution

**Independent Phases (Run Concurrently):**
- Phase 4a: Core Layer (Services, Managers)
- Phase 4b: Presentation Layer (Views, ViewModels)
- Phase 4c: Design System (Components, Resources)

**Sequential Phases:**
- Phase 5: Testing & Quality Gates (depends on 4a, 4b, 4c)

**Time Savings:** ~40 minutes on medium features (125min → 85min)

## 🔗 Beads Integration

Automatically creates beads epics and subtasks:

```bash
# Epic created for feature
PROJ-42: User Authentication Feature

# Subtasks created for each phase
PROJ-43: Phase 1 - Requirements Analysis
PROJ-44: Phase 2 - Codebase Inspection
PROJ-45: Phase 3 - Implementation Planning
PROJ-46: Phase 4a - Core Layer
PROJ-47: Phase 4b - Presentation Layer
PROJ-48: Phase 4c - Design System
PROJ-49: Phase 5 - Testing & Quality Gates
```

## 🔧 Hooks System

The plugin includes an automated hooks system that runs during your workflow:

### Available Hooks

**SessionStart:**
- `discover-skills.sh` - Auto-discovers skills in `.claude/skills/` and categorizes them
- Populates working memory with discovered skills
- Creates `.claude/reactree-ios-dev.local.md` with skill inventory

**UserPromptSubmit:**
- `detect-intent.sh` - Analyzes prompts and suggests appropriate workflows
- Routes feature requests → `/ios-dev` or `/ios-feature`
- Routes debugging → `/ios-debug`
- Routes refactoring → `/ios-refactor`

**PreToolUse (Edit/Write):**
- `pre-edit-validation.sh` - Validates Swift syntax before edits
- Checks MVVM patterns (View → ViewModel separation)
- Warns about common pitfalls (force unwrapping, etc.)

**PostToolUse (Write):**
- `post-write-validation.sh` - Runs SwiftLint on written files
- Validates against rules (e.g., services must have protocols)

### Customizing Hooks

Edit `hooks/hooks.json` to customize hook behavior:

```json
{
  "hooks": {
    "SessionStart": ["discover-skills"],
    "UserPromptSubmit": ["detect-intent"],
    "PreToolUse": ["pre-edit-validation"],
    "PostToolUse": ["post-write-validation"]
  }
}
```

Disable hooks by removing them from the array or setting `enabled: false` in plugin configuration.

## 📖 Examples

See `examples/` directory for complete implementations:

### Core Features
- `authentication-feature.md` - JWT authentication with Keychain
- `api-integration-feature.md` - REST API with Alamofire
- `video-player-feature.md` - Custom video player with AVKit

### Advanced Features (v2.0.0)
- `offline-sync-feature.md` - Complete offline-first data sync with Core Data, conflict resolution, and background sync
- `push-notifications-feature.md` - APNs setup, rich notifications, interactive actions, and testing strategies
- `tvos-focus-navigation.md` - tvOS focus engine, focus groups, parallax effects, and remote control handling

## 🔍 Troubleshooting

### Skills Not Discovered

**Problem:** Skills aren't showing up in workflow execution.

**Solution:**
1. Run `/ios-init` to initialize skill discovery
2. Verify skills exist in `.claude/skills/` directory
3. Check `.claude/reactree-ios-dev.local.md` for discovered skills inventory
4. Restart Claude Code session to reload skills

### SwiftLint Errors

**Problem:** SwiftLint validation fails during quality gates.

**Solution:**
1. Install SwiftLint: `brew install swiftlint`
2. Create `.swiftlint.yml` configuration file
3. Run `swiftlint autocorrect` to fix common issues
4. Disable specific rules if needed in `.swiftlint.yml`

### Build Failures

**Problem:** xcodebuild fails during validation.

**Solution:**
1. Verify Xcode is installed and up to date
2. Open project in Xcode and build manually to see detailed errors
3. Check CocoaPods integration: `pod install`
4. Clean build folder: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### Memory System Not Working

**Problem:** Agents repeat codebase analysis across sessions.

**Solution:**
1. Verify `.claude/reactree-memory.jsonl` exists
2. Check file permissions (should be readable/writable)
3. Ensure working memory is within 24h TTL
4. Re-run `/ios-init` to reinitialize memory systems

### Hooks Not Executing

**Problem:** SessionStart or PreToolUse hooks don't run.

**Solution:**
1. Verify `hooks/hooks.json` exists and is valid JSON
2. Check hook scripts have execute permissions: `chmod +x hooks/scripts/*.sh`
3. Ensure hook scripts don't have syntax errors
4. Check Claude Code console for hook error messages

## 🤝 Contributing

This plugin is part of the ReAcTree family of development tools. See the main repository for contribution guidelines.

For customization options, see `CUSTOMIZATION.md` for detailed instructions on:
- Adding custom skills
- Extending agents
- Modifying hooks
- Project-specific rules

## 📄 License

MIT License - See LICENSE file for details.

## 🔗 Related Projects

- `reactree-rails-dev` - Rails development with ReAcTree
- `reactree-flutter-dev` - Flutter development with ReAcTree

---

**Version:** 2.0.0
**Author:** Mohamad Kaakati
**Repository:** https://github.com/kaakati/ios-enterprise-dev
**Release Date:** January 2026

### What's New in v2.0.0

- 🆕 `/ios-init` command for automated project setup
- 🆕 Hooks system for workflow automation (6 hook scripts)
- 📚 13 new skills (27 total): error-handling, concurrency, accessibility, performance, security, and more
- 🤖 3 new utility agents: swiftgen-coordinator, accessibility-specialist, performance-profiler
- 📖 3 new advanced examples: offline-sync, push-notifications, tvOS focus navigation
- 🔧 Enhanced agents with 2,000+ lines of implementation patterns
- 📝 Expanded debug/refactor commands (19-281 lines → 3,370-3,693 lines)
