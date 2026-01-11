# Changelog

All notable changes to the reactree-ios-dev plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-11

### Added

#### Core Features
- iOS and tvOS universal development support
- SwiftUI-only implementation (modern approach)
- MVVM architecture with BaseViewModel pattern
- Clean Architecture layer separation
- Alamofire networking integration
- 80% test coverage enforcement
- Beads task tracking integration

#### Agents (11 total)
- **workflow-orchestrator**: Master coordinator for 6-phase ReAcTree workflows
- **codebase-inspector**: Analyzes Swift/SwiftUI patterns and architecture
- **ios-planner**: Plans MVVM implementation with parallel execution
- **implementation-executor**: Coordinates specialist agents
- **test-oracle**: Validates tests and coverage (80% threshold)
- **core-lead**: Implements Core layer (Services, Managers, Networking)
- **presentation-lead**: Implements Presentation layer (Views, ViewModels, Models)
- **design-system-lead**: Implements Design System (Atomic Design components)
- **quality-guardian**: Enforces quality gates (SwiftLint, build, tests)
- **file-finder**: Fast file discovery by pattern
- **log-analyzer**: Analyzes Xcode build logs and crash reports

#### Skills (14 total)
- **swift-conventions**: Swift 5 naming conventions and best practices
- **swiftui-patterns**: SwiftUI state management and platform-specific patterns
- **mvvm-architecture**: BaseViewModel and View-ViewModel binding
- **clean-architecture-ios**: Layer separation and dependency rules
- **alamofire-patterns**: NetworkRouter protocol and request handling
- **api-integration**: Service layer and API endpoint definitions
- **session-management**: SessionManager and Keychain integration
- **atomic-design-ios**: Atoms, Molecules, Organisms components
- **navigation-patterns**: NavigationStack and NavigationPath
- **theme-management**: ThemeManager and SwiftGen integration
- **xctest-patterns**: Unit, integration, and UI testing
- **swiftgen-integration**: Type-safe asset generation
- **code-quality-gates**: SwiftLint and build validation
- **localization-ios**: LanguageManager and RTL support

#### Commands (4 total)
- **/ios-dev**: Main development workflow with full ReAcTree orchestration
- **/ios-feature**: Feature-driven development workflow
- **/ios-debug**: Debugging and log analysis workflow
- **/ios-refactor**: Refactoring and code quality workflow

#### Rules (12 total)
- **core/services.md**: Service layer Protocol-Oriented Programming
- **core/managers.md**: Manager Singleton patterns
- **core/networking.md**: NetworkRouter and Alamofire patterns
- **presentation/views.md**: SwiftUI view structure and state management
- **presentation/viewmodels.md**: BaseViewModel and @Published properties
- **presentation/models.md**: Codable struct patterns
- **design-system/components.md**: Atomic design hierarchy
- **design-system/resources.md**: SwiftGen resource access
- **testing/unit-tests.md**: XCTest structure and naming
- **testing/ui-tests.md**: UI test patterns with accessibility IDs
- **quality-gates/swiftlint.md**: Linting rules and enforcement
- **quality-gates/build-validation.md**: Build success criteria

#### Examples (3 total)
- **authentication-feature.md**: JWT authentication with Keychain storage
- **api-integration-feature.md**: REST API with Alamofire and MVVM
- **video-player-feature.md**: Custom video player with AVKit

### Quality Gates
- SwiftLint strict mode enforcement
- Xcodebuild clean build validation
- 80% test coverage requirement
- SwiftGen configuration linting

### Platform Features
- iOS-specific: Tab bar, touch gestures, haptic feedback, size classes
- tvOS-specific: FocusManager, remote control, top shelf, parallax effects
- Universal: Platform detection, adaptive layouts, conditional modifiers

### Performance
- 30-50% faster workflows through parallel execution
- Working memory eliminates redundant codebase analysis
- Episodic learning reuses proven patterns (15-30% speed gain on similar features)

---

## [Unreleased]

### Planned
- UIKit interop patterns for legacy code
- watchOS support
- macOS catalyst patterns
- Combine integration patterns
- Core Data integration
- SwiftData integration (iOS 17+)
