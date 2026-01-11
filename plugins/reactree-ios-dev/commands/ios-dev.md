---
name: ios-dev
description: |
  ReAcTree-based iOS/tvOS development with parallel execution, working memory,
  and episodic learning for 30-50% faster workflows. Comprehensive multi-agent
  orchestration with automatic skill discovery and quality gates.
color: green
allowed-tools: ["*"]
---

# ReAcTree iOS/tvOS Development Workflow

You are initiating the **primary iOS/tvOS development workflow** powered by ReAcTree architecture.

## Development Philosophy

**Memory-first, quality-driven development means:**
1. **Skill-driven patterns** - Discover and apply project-specific conventions
2. **Memory persistence** - Share verified facts across agents, eliminate redundancy
3. **Parallel execution** - Run independent phases concurrently for 30-50% speed gains
4. **Quality gates** - Validate each phase before proceeding (SwiftLint, tests, build)
5. **Episodic learning** - Learn from successful executions to improve future workflows

## Usage

```
/ios-dev [your feature request]
```

## Examples

**Authentication & User Management:**
```
/ios-dev add user authentication with JWT tokens
/ios-dev implement OAuth2 login with Apple Sign-In
/ios-dev create user profile with avatar upload
/ios-dev add biometric authentication (Face ID/Touch ID)
```

**API Integration:**
```
/ios-dev create product catalog with REST API
/ios-dev implement GraphQL client for posts
/ios-dev add WebSocket real-time chat
/ios-dev build pagination for user list
```

**SwiftUI Features:**
```
/ios-dev add Hotwire-powered search with autocomplete
/ios-dev create custom video player with AVKit
/ios-dev implement dark mode with theme switching
/ios-dev build onboarding flow with SwiftUI
```

**tvOS-Specific Features:**
```
/ios-dev implement focus-based side menu for tvOS
/ios-dev add top shelf support for tvOS
/ios-dev create tvOS hero carousel with focus
/ios-dev build remote control playback for video
```

**State Management:**
```
/ios-dev add shopping cart with @StateObject
/ios-dev implement multi-step form with validation
/ios-dev create global theme controller
/ios-dev add settings screen with @AppStorage
```

**Data & Persistence:**
```
/ios-dev create Order model with Codable
/ios-dev implement Core Data stack for offline
/ios-dev add Keychain integration for secure tokens
/ios-dev build local caching with UserDefaults
```

## Workflow Activation

When you invoke `/ios-dev`, the workflow orchestrator will:

1. ✅ Detect Xcode project root (.xcodeproj/.xcworkspace)
2. ✅ Parse requirements into user stories
3. ✅ Analyze existing code patterns (codebase-inspector)
4. ✅ Plan implementation with MVVM architecture (ios-planner)
5. ✅ Execute in parallel phases (implementation-executor):
   - Phase 4a: Core Layer (Services, Managers)
   - Phase 4b: Presentation Layer (Views, ViewModels)
   - Phase 4c: Design System (Components)
6. ✅ Generate comprehensive tests (XCTest)
7. ✅ Run quality gates (SwiftLint, build, test coverage 80%)
8. ✅ Create beads epic for multi-session tracking

## Quality Gates

**SwiftLint**: Code style enforcement
**Build**: xcodebuild clean build
**Tests**: XCTest suite with 80% coverage
**SwiftGen**: Asset validation

## Platform Support

- iOS 15.0+
- tvOS 15.0+
- iPadOS 15.0+
