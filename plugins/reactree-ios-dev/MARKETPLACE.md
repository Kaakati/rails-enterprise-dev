# ReAcTree iOS/tvOS Development - Marketplace Guide

## Plugin Marketplace Listing

### Display Name
**ReAcTree iOS/tvOS Development**

### Short Description (160 characters max)
Enterprise iOS/tvOS development with 14 AI agents, 27 skills, automated quality gates, and one-command setup. SwiftUI + MVVM + Clean Architecture.

### Long Description

Complete multi-agent orchestration system for professional iOS and tvOS development.

**🚀 Quick Setup**
One command initializes your entire development environment:
```
/ios-init
```

**🤖 14 Specialized Agents**
- Workflow Orchestration - 6-phase development lifecycle
- Code Generation - Core layer, Presentation layer, Design System
- Quality Gates - SwiftLint, build validation, 80% test coverage
- Testing - Test pyramid enforcement and coverage analysis
- Utilities - File discovery, log analysis, accessibility testing, performance profiling

**📚 27 Comprehensive Skills**
- **Core (4):** Swift conventions, SwiftUI patterns, MVVM architecture, Clean Architecture
- **Networking (2):** Alamofire patterns, API integration
- **UI (3):** Navigation, Atomic Design, Theme management
- **Data (2):** Model patterns, Core Data
- **Testing (2):** XCTest patterns, Quality gates
- **Advanced (13):** Error handling, Concurrency, Accessibility, Performance, Security, Dependency injection, Coordinator pattern, Combine, Push notifications, App lifecycle, and more
- **Platform (1):** tvOS-specific patterns
- **Tools (3):** SwiftGen, Localization, Session management

**⚡ Automated Workflows**
- `/ios-dev` - Complete feature development with full orchestration
- `/ios-feature` - Feature-driven development workflow
- `/ios-debug` - Debugging and log analysis
- `/ios-refactor` - Code quality improvements and refactoring

**🎯 Quality Assurance**
- SwiftLint strict mode enforcement
- Xcodebuild validation for iOS and tvOS
- 80% minimum test coverage
- Test pyramid validation (70% unit, 20% integration, 10% UI)
- Automated quality gate checkpoints

**🏗️ Architecture Patterns**
- MVVM (Model-View-ViewModel) with BaseViewModel
- Clean Architecture (Core → Presentation → Design System)
- Protocol-Oriented Programming
- Atomic Design (Atoms → Molecules → Organisms)
- Repository Pattern for data layer

**📱 Platform Support**
- Universal iOS and tvOS support
- Platform-specific patterns and best practices
- SwiftUI-only modern approach
- Async/await concurrency patterns
- Focus engine for tvOS

**💡 Advanced Features**
- Offline-first data sync with Core Data
- Push notifications with APNs and rich media
- tvOS focus navigation and parallax effects
- Accessibility testing (WCAG 2.1 Level AA)
- Performance profiling with Instruments
- Background sync with BGTaskScheduler

**🔗 Beads Integration**
- Automatic epic and task creation
- Multi-session work tracking
- Phase dependency management
- Progress visibility

**🧠 Memory Systems**
- Working memory (24h TTL) for codebase facts
- Episodic learning for proven patterns
- 15-30% faster on similar features
- 100% consistency across agents

**📦 What You Get**
- 71 files with 40,000+ lines of production-ready patterns
- Complete examples (authentication, offline sync, push notifications, tvOS navigation)
- 12 architectural rules (enforced automatically)
- Hooks system for auto-discovery and validation
- Comprehensive documentation

**⚙️ Requirements**
- Xcode 14.0+
- Swift 5.7+
- iOS 15.0+ / tvOS 15.0+
- SwiftLint (installed via Homebrew)

**🎓 Perfect For**
- Enterprise iOS/tvOS applications
- Teams following Clean Architecture
- Projects requiring high test coverage
- SwiftUI-first development
- Multi-platform iOS/tvOS apps

---

### Category
**Development**

### Tags
- ios-development
- tvos-development
- swiftui
- mobile-development
- enterprise
- architecture
- testing
- quality-assurance

### Keywords
ios, tvos, swift, swiftui, mvvm, alamofire, clean-architecture, reactree, multi-agent, quality-gates, beads, xctest, hooks, automation, workflow, orchestration, accessibility, performance, offline-sync, push-notifications, core-data, swiftgen, swiftlint, xcode, testing, atomic-design

---

## Installation Instructions

### Method 1: Quick Install (Recommended)

**Step 1: Clone or Download Plugin**
```bash
# Clone the repository
git clone https://github.com/kaakati/ios-enterprise-dev.git

# Or download ZIP and extract
```

**Step 2: Copy to Your iOS Project**
```bash
# Navigate to your iOS/tvOS project
cd /path/to/your/ios/project

# Create plugins directory
mkdir -p .claude/plugins

# Copy plugin
cp -r /path/to/ios-enterprise-dev/plugins/reactree-ios-dev .claude/plugins/
```

**Step 3: Initialize Plugin**
```
/ios-init
```

This will copy all agents, skills, rules, and memory systems to your project.

**Step 4: Install SwiftLint**
```bash
brew install swiftlint
```

**Step 5: Start Building**
```
/ios-dev add user authentication with JWT tokens
```

---

### Method 2: Manual Installation

**Step 1: Create Directory Structure**
```bash
cd /path/to/your/ios/project
mkdir -p .claude/plugins
mkdir -p .claude/agents
mkdir -p .claude/skills
mkdir -p .claude/rules
```

**Step 2: Copy Plugin**
```bash
# Copy entire plugin directory
cp -r /path/to/reactree-ios-dev .claude/plugins/
```

**Step 3: Copy Components Manually**
```bash
# Copy agents
cp .claude/plugins/reactree-ios-dev/agents/*.md .claude/agents/

# Copy skills
cp -r .claude/plugins/reactree-ios-dev/skills/* .claude/skills/

# Copy rules
cp -r .claude/plugins/reactree-ios-dev/rules/* .claude/rules/
```

**Step 4: Initialize Memory Files**
```bash
touch .claude/reactree-memory.jsonl
touch .claude/reactree-episodes.jsonl
touch .claude/reactree-feedback.jsonl
touch .claude/reactree-state.jsonl
```

**Step 5: Install Dependencies**
```bash
brew install swiftlint
brew install swiftgen  # Optional
```

---

### Method 3: Install via Package Manager (Future)

Once the plugin is listed on the Claude Code marketplace:

```bash
# Via Claude Code CLI
claude-code plugin install reactree-ios-dev

# Or via Claude Code UI
# Navigate to Plugins → Browse Marketplace → Search "ReAcTree iOS"
```

---

## Verification

After installation, verify everything is set up correctly:

**Check Directory Structure:**
```bash
tree .claude -L 2
```

Expected output:
```
.claude/
├── agents/
│   ├── workflow-orchestrator.md
│   ├── codebase-inspector.md
│   ├── ios-planner.md
│   ├── implementation-executor.md
│   └── ... (14 total)
├── skills/
│   ├── swift-conventions/
│   ├── swiftui-patterns/
│   ├── mvvm-architecture/
│   └── ... (27 total)
├── rules/
│   ├── core/
│   ├── presentation/
│   ├── design-system/
│   └── ... (5 categories)
├── plugins/
│   └── reactree-ios-dev/
├── reactree-memory.jsonl
├── reactree-episodes.jsonl
├── reactree-feedback.jsonl
├── reactree-state.jsonl
└── reactree-ios-dev.local.md
```

**Verify Commands Available:**
```
/ios-init
/ios-dev
/ios-feature
/ios-debug
/ios-refactor
```

**Check Configuration:**
```bash
cat .claude/reactree-ios-dev.local.md
```

---

## Quick Start Examples

### Example 1: Authentication Feature
```
/ios-dev add user authentication with JWT tokens, Keychain storage, and biometric login
```

**Result:**
- SessionManager singleton
- KeychainService for secure token storage
- AuthenticationService with login/logout
- LoginView with SwiftUI
- LoginViewModel with @Published state
- BiometricAuthManager for Face ID/Touch ID
- Comprehensive XCTests (80%+ coverage)
- Quality gates passed (SwiftLint + build + tests)

### Example 2: Product Catalog with API
```
/ios-dev create product catalog with REST API, offline caching, and search
```

**Result:**
- ProductService with Alamofire NetworkRouter
- ProductRepository with Core Data caching
- ProductListView with LazyVStack
- ProductListViewModel with async/await
- SearchBar component
- ProductDetailView and ViewModel
- Network reachability monitoring
- Complete test suite

### Example 3: Debugging Workflow
```
/ios-debug analyze crash logs and fix memory leak in ProfileViewModel
```

**Result:**
- Crash log symbolication and analysis
- Memory leak detection with Instruments
- Root cause identification
- Fix implementation with proper ARC
- Prevention patterns added
- Validation tests

### Example 4: Refactoring Legacy Code
```
/ios-refactor convert UserProfileViewController to MVVM with SwiftUI
```

**Result:**
- UIKit → SwiftUI migration
- Extract UserProfileViewModel
- Protocol-based dependency injection
- Clean Architecture layer separation
- Comprehensive tests for new code
- Quality gates validation

---

## Support & Resources

### Documentation
- **README:** Complete feature overview and usage guide
- **CHANGELOG:** Version history and migration guides
- **CUSTOMIZATION:** How to extend and customize the plugin
- **Examples:** 6 real-world implementation examples

### Repository
https://github.com/kaakati/ios-enterprise-dev

### Issues & Feature Requests
https://github.com/kaakati/ios-enterprise-dev/issues

### Discussions
https://github.com/kaakati/ios-enterprise-dev/discussions

### Author
Mohamad Kaakati (hello@kaakati.me)

---

## Pricing

**Free and Open Source** under MIT License

---

## Marketplace Submission Checklist

- [x] plugin.json with comprehensive metadata
- [x] README.md with features and installation
- [x] CHANGELOG.md with version history
- [x] MARKETPLACE.md with marketplace description
- [x] LICENSE file (MIT)
- [x] CUSTOMIZATION.md for advanced users
- [x] Examples directory with real-world implementations
- [x] All agents documented and tested
- [x] All skills comprehensive (200-600 lines each)
- [x] All commands functional (/ios-init, /ios-dev, /ios-feature, /ios-debug, /ios-refactor)
- [x] Hooks system complete (4 hooks with shell scripts)
- [x] Version 2.0.0 release tagged
- [x] Repository publicly accessible

---

## Marketplace Assets

### Screenshots (to be added)

1. **Init Command** - Screenshot of `/ios-init` running with colorful output
2. **Agent Coordination** - Visual of 6-phase workflow with agents
3. **Code Generation** - Before/after of generated MVVM code
4. **Quality Gates** - Terminal showing SwiftLint + build + tests passing
5. **Skill Discovery** - Screenshot of discovered skills inventory
6. **Example Output** - Authentication feature generated code

### Banner Image (to be added)
- Dimensions: 1200x630px
- Include logo, tagline, key features (14 agents, 27 skills, /ios-init)
- Modern design with iOS/tvOS aesthetic

### Icon (to be added)
- Dimensions: 512x512px
- Transparent background
- Simple, recognizable logo
- Works at small sizes

---

## SEO Optimization

### Meta Title
ReAcTree iOS/tvOS Development - Enterprise-Grade Multi-Agent Plugin for Claude Code

### Meta Description
Professional iOS/tvOS development with 14 AI agents, 27 comprehensive skills, automated quality gates, and one-command setup. SwiftUI + MVVM + Clean Architecture.

### Search Terms
- iOS development plugin
- tvOS development automation
- SwiftUI multi-agent system
- MVVM architecture generator
- Clean Architecture iOS
- iOS quality gates
- SwiftUI testing automation
- iOS enterprise development
- tvOS focus navigation
- SwiftUI offline sync
- iOS push notifications
- Xcode automation

---

## Version History for Marketplace

### v2.0.0 (2026-01-11) - Current
- ✅ Added `/ios-init` command for one-command setup
- ✅ 13 new skills (27 total)
- ✅ 3 new utility agents (14 total)
- ✅ Hooks system with auto-discovery
- ✅ 3 advanced examples (offline sync, push notifications, tvOS navigation)
- ✅ Enhanced commands (ios-debug, ios-refactor)
- ✅ Comprehensive documentation

### v1.0.0 (2025-12-15) - Initial Release
- 11 agents for workflow orchestration
- 14 foundational skills
- 4 commands (/ios-dev, /ios-feature, /ios-debug, /ios-refactor)
- 12 architectural rules
- Quality gates (SwiftLint, build, coverage)
- Beads integration
- 3 basic examples

---

## License

MIT License - See LICENSE file for details.

Copyright (c) 2025-2026 Mohamad Kaakati

---

**Ready for Claude Code Marketplace! 🚀**
