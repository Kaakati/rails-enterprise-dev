# Rails Enterprise Development Plugin

Enterprise-grade Rails development workflow with multi-agent orchestration, automatic skill discovery, and beads task tracking.

## Features

- 🔍 **Automatic Skill Discovery** - Uses skills from your project's `.claude/skills/` directory
- 🎯 **Multi-Agent Orchestration** - Coordinates specialist agents through 6-phase workflow
- 📋 **Beads Integration** - Tracks all work with persistent issue tracking
- ✅ **Quality Gates** - Validates each phase before proceeding
- 🔄 **Incremental Implementation** - Checkpoints at every layer
- 🎨 **Generic & Portable** - Works with ANY Rails project
- 🛡️ **Error Prevention** - Consults skills to avoid common pitfalls

## Quick Start

### Installation

The plugin is already installed in `.claude/plugins/rails-enterprise-dev/`.

### Basic Usage

```bash
/rails-dev add JWT authentication with refresh tokens
```

This single command:
1. Discovers skills in your `.claude/skills/`
2. Creates beads issue for tracking
3. Analyzes your codebase patterns
4. Creates implementation plan
5. Implements in phases with quality validation
6. Reviews and completes

### Configuration

Create `.claude/rails-enterprise-dev.local.md` (optional):

```markdown
---
enabled: true
quality_gates_enabled: true
test_coverage_threshold: 90
---
```

**Add to `.gitignore`**:
```gitignore
.claude/*.local.md
```

## How It Works

### 6-Phase Workflow

```
Phase 1: Initialization
  ├─ Discover skills in .claude/skills/
  ├─ Create beads issue (if available)
  └─ Initialize workflow state

Phase 2: Inspection
  ├─ Invoke codebase-inspection skill (if available)
  ├─ Invoke rails-conventions skill (if available)
  ├─ Invoke domain skills (if available)
  └─ Analyze existing patterns

Phase 3: Planning
  ├─ Invoke rails-error-prevention skill
  ├─ Invoke feature-specific skills
  └─ Create detailed implementation plan

Phase 4: Implementation (Incremental)
  ├─ Database → Models → Services → Components → Controllers → Views → Tests
  ├─ Each layer: Invoke skills → Delegate to specialist → Validate
  └─ Quality gates at each checkpoint

Phase 5: Review
  └─ Chief Reviewer validates entire implementation

Phase 6: Completion
  ├─ Close beads issue
  └─ Provide summary with next steps
```

### Skill Discovery

The plugin automatically discovers skills from `.claude/skills/`:

**Core Skills**:
- `rails-conventions` - Rails patterns
- `rails-error-prevention` - Preventive checklists
- `codebase-inspection` - Analysis procedures

**Implementation Skills**:
- `activerecord-patterns` - Database/models
- `service-object-patterns` - Service layer
- `api-development-patterns` - API design
- `sidekiq-async-patterns` - Background jobs
- `viewcomponents-specialist` - UI components
- `hotwire-patterns` - Turbo/Stimulus
- `tailadmin-patterns` - TailAdmin UI
- `localization` - i18n
- `rspec-testing-patterns` - Testing

**Domain Skills** (auto-detected):
- Any skill not matching known patterns (e.g., `manifest-project-context`)

### Agent Coordination

The plugin coordinates your project's specialist agents:

- **workflow-orchestrator** - Manages entire workflow
- **codebase-inspector** - Analyzes project patterns
- **rails-planner** - Creates implementation plan
- **implementation-executor** - Coordinates code generation

These delegate to your project agents:
- Data Lead, ActiveRecord Specialist (database/models)
- Backend Lead, API Specialist (services/controllers)
- Async Specialist (background jobs)
- UI Specialist, Frontend Lead (components/views)
- Turbo Hotwire Specialist (real-time features)
- RSpec Specialist (tests)
- Chief Reviewer (final validation)

## Commands

### `/rails-dev [feature request]`

Main workflow for feature development.

Examples:
```bash
/rails-dev add payment processing with Stripe
/rails-dev build admin dashboard for user management
/rails-dev implement real-time notifications
```

### `/rails-feature [description]`

Feature-driven development with user stories.

Examples:
```bash
/rails-feature User can export tasks to CSV
/rails-feature Admin sees real-time delivery metrics
```

### `/rails-debug [error]`

Systematic debugging workflow.

Examples:
```bash
/rails-debug NoMethodError in TasksController#index
/rails-debug Slow query on bundles page
```

### `/rails-refactor [target]`

Safe refactoring with test preservation.

Examples:
```bash
/rails-refactor Extract services into smaller classes
/rails-refactor Optimize N+1 queries in index
```

## Beads Integration

If beads is installed (`bd` command available):

**View Progress**:
```bash
bd show [issue-id]    # Detailed feature view
bd ready              # See ready tasks
bd stats              # Project statistics
bd list --status in_progress  # Active work
```

**Install Beads** (if not installed):
```bash
npm install -g @beads/cli
bd init
```

Without beads, workflow continues with manual tracking.

## Quality Gates

When `quality_gates_enabled: true`, each phase validated:

**Database**: Migrations run, rollback works
**Models**: Load successfully, specs pass
**Services**: Pattern correct, tests pass
**Components**: Methods exposed, renders without errors
**Controllers**: Routes defined, specs pass
**Views**: Only calls exposed methods
**Tests**: All pass, coverage > threshold

To disable temporarily:
```markdown
# .claude/rails-enterprise-dev.local.md
---
quality_gates_enabled: false
---
```

## Customization

### Adding Project Skills

1. Create skill directory:
```bash
mkdir -p .claude/skills/my-custom-patterns
```

2. Add `SKILL.md`:
```markdown
---
name: My Custom Patterns
description: Our team's coding standards
---

# My Custom Patterns

## Service Layer
- Always use dry-transaction gem
- Include logging in all services
...
```

3. Plugin auto-discovers on next run!

### Skill Naming for Auto-Categorization

**Data layer**: `activerecord-*`, `*-model*`, `*-database*`
**Service layer**: `service-*`, `*-service-*`, `api-*`
**UI**: `*-component*`, `*-view*`, `*-ui-*`, `hotwire-*`
**Domain**: Anything else (e.g., `ecommerce-domain`, `healthcare-context`)

See `CUSTOMIZATION.md` for more details.

## Troubleshooting

### Workflow Interrupted

State saved in `.claude/rails-enterprise-dev.local.md`. Check:
```bash
cat .claude/rails-enterprise-dev.local.md
```

Resume workflow by re-running command.

### Skills Not Being Used

1. Verify skills exist: `ls .claude/skills/`
2. Check skill has `SKILL.md` file
3. Restart Claude Code
4. Re-run command

### Quality Gates Too Strict

Temporarily disable in settings:
```yaml
quality_gates_enabled: false
```

Or manually override when prompted.

### Beads Issues

- Install: `npm install -g @beads/cli`
- Initialize: `bd init`
- Check status: `bd stats`

Workflow continues without beads if unavailable.

## Multi-Project Usage

The plugin is **generic and portable**:

**Project A** (Manifest LMS):
- Has 15 skills including `manifest-project-context`
- Plugin uses all skills for domain-aware implementation

**Project B** (Simple API):
- Has 5 basic skills
- Plugin adapts, uses what's available

**Project C** (Different UI):
- Has `bootstrap-patterns` instead of `tailadmin-patterns`
- Plugin uses Bootstrap patterns for UI

Same plugin, adapts to each project!

## Architecture

```
Plugin discovers skills → Coordinates agents → Tracks with beads

Skills (project-specific)
  ↓ provide guidance
Agents (plugin-provided)
  ↓ coordinate
Specialists (project-provided)
  ↓ implement code
```

**Separation of concerns**:
- Plugin: Workflow orchestration
- Skills: Project patterns and conventions
- Agents: Coordination logic
- Specialists: Code generation

## Files

```
.claude/plugins/rails-enterprise-dev/
├── agents/
│   ├── workflow-orchestrator.md       # Main coordinator
│   ├── codebase-inspector.md          # Pattern analysis
│   ├── rails-planner.md               # Implementation planning
│   └── implementation-executor.md     # Phase execution
├── commands/
│   ├── rails-dev.md                   # Main workflow
│   ├── rails-feature.md               # Feature variant
│   ├── rails-debug.md                 # Debug variant
│   └── rails-refactor.md              # Refactor variant
├── skills/
│   ├── skill-discovery/SKILL.md       # How skill discovery works
│   ├── workflow-orchestration/SKILL.md  # Agent coordination
│   └── beads-integration/SKILL.md     # Task tracking patterns
└── hooks/
    └── scripts/
        ├── discover-skills.sh         # Skill scanner
        ├── detect-rails-context.sh    # Auto-suggest workflow
        ├── validate-implementation.sh # Quality gates
        └── track-progress.sh          # Beads updates
```

## Contributing

To enhance the plugin:

1. Add more specialized commands in `commands/`
2. Create additional skills in `skills/`
3. Add hooks for automation in `hooks/`
4. Improve agents in `agents/`

## Support

- Documentation: This file + `CUSTOMIZATION.md`
- Skill patterns: `.claude/skills/*/SKILL.md` in your project
- Issues: [Report on GitHub]

## Version

**v1.0.0** - Initial release

## License

MIT

---

**Happy Rails development!** 🚀
