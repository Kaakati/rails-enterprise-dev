# Claude Code Plugin Marketplace

Enterprise-grade development plugins for Claude Code with multi-agent orchestration, automatic skill discovery, and comprehensive workflows.

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [rails-enterprise-dev](#rails-enterprise-dev) | 1.0.1 | Enterprise Rails workflow with multi-agent orchestration |
| [reactree-rails-dev](#reactree-rails-dev) | 2.9.1 | ReAcTree-based hierarchical agent orchestration for Rails |
| [reactree-flutter-dev](#reactree-flutter-dev) | 1.1.0 | Flutter development with GetX and Clean Architecture |
| [reactree-ios-dev](#reactree-ios-dev) | 2.0.0 | iOS/tvOS development with SwiftUI and MVVM |

---

## rails-enterprise-dev

Enterprise-grade Rails development workflow with multi-agent orchestration, automatic skill discovery, and beads task tracking.

### Features

- **Automatic Skill Discovery** - Uses skills from your project's `.claude/skills/` directory
- **Multi-Agent Orchestration** - Coordinates specialist agents through 6-phase workflow
- **Beads Integration** - Tracks all work with persistent issue tracking
- **Quality Gates** - Validates each phase before proceeding
- **Incremental Implementation** - Checkpoints at every layer

### Quick Start

```bash
/rails-dev add JWT authentication with refresh tokens
```

### Commands

| Command | Description |
|---------|-------------|
| `/rails-dev [feature]` | Main workflow for feature development |
| `/rails-feature [story]` | Feature-driven development with user stories |
| `/rails-debug [error]` | Systematic debugging workflow |
| `/rails-refactor [target]` | Safe refactoring with test preservation |

---

## reactree-rails-dev

ReAcTree-based hierarchical agent orchestration for Rails development with parallel execution, 24h TTL memory caching, and smart intent detection.

### Features

- **ReAcTree Architecture** - Hierarchical task decomposition with control flow nodes
- **Parallel Execution** - Run independent tasks concurrently
- **Dual Memory Systems** - Working memory + episodic memory with 24h TTL
- **Smart Intent Detection** - Auto-suggests workflows based on prompts
- **UX Engineer Agent** - Accessibility and responsive design
- **14 Specialized Agents** - Optimized model selection (Opus/Haiku)
- **Comprehensive Skills Library** - 16+ production-ready skills

### Quick Start

```bash
/reactree-dev implement user subscription billing
```

### Commands

| Command | Description |
|---------|-------------|
| `/reactree-dev [feature]` | Main ReAcTree workflow with parallel execution |
| `/reactree-feature [story]` | Feature-driven with test-first development |
| `/reactree-debug [error]` | Debug with FEEDBACK edges for self-correction |

### Agents

- **workflow-orchestrator** - Manages entire ReAcTree workflow
- **rails-planner** - Creates implementation plans
- **implementation-executor** - Coordinates code generation
- **test-oracle** - Test planning with coverage validation
- **feedback-coordinator** - FEEDBACK edge routing
- **ux-engineer** - Accessibility and responsive design
- **ui-specialist** - TailAdmin dashboard UI

---

## reactree-flutter-dev

Flutter development with GetX state management, Clean Architecture, multi-agent orchestration, and comprehensive testing patterns.

### Features

- **GetX State Management** - Reactive controllers and dependency injection
- **Clean Architecture** - Domain, Data, Presentation layers
- **Multi-Agent Orchestration** - Specialized Flutter agents
- **Quality Gates** - Automated validation at each phase
- **Testing Patterns** - Unit, widget, integration, and golden tests
- **Navigation Patterns** - GetX routing with guards
- **i18n Support** - Internationalization patterns
- **Performance Optimization** - Widget rebuilds, memory management
- **Accessibility Patterns** - Screen reader and semantics support

### Quick Start

```bash
/flutter-dev add offline-first data sync
```

### Commands

| Command | Description |
|---------|-------------|
| `/flutter-dev [feature]` | Main Flutter development workflow |
| `/flutter-feature [story]` | Feature-driven Flutter development |
| `/flutter-debug [error]` | Flutter debugging workflow |

---

## reactree-ios-dev

iOS and tvOS development with SwiftUI, MVVM, Clean Architecture, and enterprise-grade tooling.

### Features

- **SwiftUI & MVVM** - Modern iOS architecture patterns
- **Clean Architecture** - Domain, Data, Presentation separation
- **14 Specialized Agents** - iOS-specific expertise
- **27 Comprehensive Skills** - Production-ready patterns
- **Automated Quality Gates** - Swift linting and testing
- **Hooks System** - Pre/post tool automation
- **One-Command Setup** - `/ios-init` initializes everything
- **Beads Integration** - Issue tracking across sessions
- **Offline Sync** - Core Data and CloudKit patterns
- **Push Notifications** - APNs implementation patterns
- **tvOS Focus Navigation** - Focus engine and remote control
- **Accessibility Testing** - VoiceOver and accessibility audit
- **Performance Profiling** - Instruments integration

### Quick Start

```bash
/ios-init                    # Initialize iOS project
/ios-dev add biometric auth  # Implement feature
```

### Commands

| Command | Description |
|---------|-------------|
| `/ios-init` | Initialize iOS project with all configurations |
| `/ios-dev [feature]` | Main iOS development workflow |
| `/ios-feature [story]` | Feature-driven iOS development |
| `/ios-debug [error]` | iOS debugging workflow |
| `/tvos-dev [feature]` | tvOS-specific development |

### Agents

- **ios-architect** - System design and architecture
- **swiftui-specialist** - SwiftUI views and modifiers
- **data-persistence** - Core Data, SwiftData, CloudKit
- **networking-specialist** - URLSession, async/await
- **accessibility-auditor** - VoiceOver compliance
- **performance-profiler** - Instruments and optimization
- **tvos-specialist** - Focus engine and remote control

---

## Installation

### From Marketplace

```bash
# Install via Claude Code plugin marketplace (coming soon)
claude plugins install rails-enterprise-dev
claude plugins install reactree-rails-dev
claude plugins install reactree-flutter-dev
claude plugins install reactree-ios-dev
```

### Manual Installation

```bash
# Clone repository
git clone https://github.com/kaakati/rails-enterprise-dev.git

# Copy desired plugin to your project
cp -r rails-enterprise-dev/plugins/reactree-rails-dev .claude/plugins/
```

---

## Common Features

All plugins share these capabilities:

### Beads Integration

Track work with persistent issue tracking:

```bash
bd show [issue-id]    # Detailed view
bd ready              # See ready tasks
bd stats              # Project statistics
bd list --status in_progress
```

### Quality Gates

Automated validation at each phase:
- Database migrations
- Model validations
- Service patterns
- Component rendering
- Test coverage

### Skill Discovery

Plugins auto-discover skills from `.claude/skills/`:

```
.claude/skills/
├── rails-conventions/SKILL.md
├── activerecord-patterns/SKILL.md
├── service-object-patterns/SKILL.md
└── your-custom-skill/SKILL.md
```

### Multi-Agent Orchestration

Coordinate specialist agents through hierarchical workflows:

```
Orchestrator
├── Planner (creates implementation plan)
├── Inspector (analyzes codebase)
├── Executor (coordinates specialists)
│   ├── Data Lead
│   ├── Backend Lead
│   ├── UI Specialist
│   └── Test Specialist
└── Reviewer (validates implementation)
```

---

## Configuration

Create project-specific config in `.claude/[plugin-name].local.md`:

```markdown
---
enabled: true
quality_gates_enabled: true
test_coverage_threshold: 90
---
```

Add to `.gitignore`:
```gitignore
.claude/*.local.md
```

---

## Repository Structure

```
rails-enterprise-dev/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace manifest
├── plugins/
│   ├── rails-enterprise-dev/  # Enterprise Rails plugin
│   ├── reactree-rails-dev/    # ReAcTree Rails plugin
│   ├── reactree-flutter-dev/  # Flutter plugin
│   └── reactree-ios-dev/      # iOS/tvOS plugin
├── README.md                  # This file
└── CUSTOMIZATION.md           # Customization guide
```

---

## Contributing

To enhance the plugins:

1. Add specialized commands in `plugins/[name]/commands/`
2. Create skills in `plugins/[name]/skills/`
3. Add hooks in `plugins/[name]/hooks/`
4. Improve agents in `plugins/[name]/agents/`

---

## Support

- Documentation: Plugin-specific READMEs in each plugin directory
- Issues: [Report on GitHub](https://github.com/kaakati/rails-enterprise-dev/issues)

---

## License

MIT

---

**Happy coding!**
