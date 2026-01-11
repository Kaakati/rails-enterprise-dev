# ReAcTree iOS/tvOS Development Plugin

Multi-agent orchestration for iOS and tvOS development with SwiftUI, MVVM, Clean Architecture, and comprehensive quality gates.

## 🚀 Features

- **iOS & tvOS Support**: Universal plugin for iPhone, iPad, and Apple TV development
- **Clean Architecture + MVVM**: Enforces proper layer separation and testability
- **SwiftUI-Only**: Modern SwiftUI patterns with state management best practices
- **Alamofire Networking**: Best practices for REST API integration
- **Quality Gates**: SwiftLint, build validation, 80% test coverage enforcement
- **Multi-Agent Workflow**: Specialized agents for Core, Presentation, and Design System layers
- **Beads Integration**: Track multi-session work with automatic task creation
- **Parallel Execution**: 30-50% faster workflows through intelligent parallelization
- **Working Memory**: Eliminates redundant codebase analysis across agents
- **Episodic Learning**: Reuses proven approaches for similar features

## 📦 Installation

### Manual Installation

```bash
cd /path/to/your/ios/project
mkdir -p .claude/plugins
cp -r path/to/reactree-ios-dev .claude/plugins/
```

### Requirements

- Xcode 14.0+
- iOS 15.0+ / tvOS 15.0+
- Swift 5.7+
- CocoaPods or Swift Package Manager

## 🎯 Quick Start

### Basic Usage

```
/ios-dev add user authentication with JWT tokens
```

The plugin will:
1. ✅ Detect Xcode project root
2. ✅ Parse requirements into user stories
3. ✅ Analyze existing MVVM patterns
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

## 📖 Examples

See `examples/` directory for complete implementations:
- `authentication-feature.md` - JWT authentication with Keychain
- `api-integration-feature.md` - REST API with Alamofire
- `video-player-feature.md` - Custom video player with AVKit

## 🤝 Contributing

This plugin is part of the ReAcTree family of development tools. See the main repository for contribution guidelines.

## 📄 License

MIT License - See LICENSE file for details.

## 🔗 Related Projects

- `reactree-rails-dev` - Rails development with ReAcTree
- `reactree-flutter-dev` - Flutter development with ReAcTree

---

**Version:** 1.0.0
**Author:** Mohamad Kaakati
**Repository:** https://github.com/kaakati/ios-enterprise-dev
