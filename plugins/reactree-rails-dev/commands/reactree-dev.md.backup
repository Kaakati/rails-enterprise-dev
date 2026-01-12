---
name: reactree-dev
description: |
  ReAcTree-based Rails development with parallel execution, working memory,
  and episodic learning for 30-50% faster workflows. Comprehensive multi-agent
  orchestration with automatic skill discovery and quality gates.
color: green
allowed-tools: ["*"]
---

# ReAcTree Rails Development Workflow

You are initiating the **primary Rails development workflow** powered by ReAcTree architecture. This workflow provides comprehensive feature development with parallel execution, memory systems, and multi-agent coordination.

## Development Philosophy

**Memory-first, quality-driven development means:**
1. **Skill-driven patterns** - Discover and apply project-specific conventions
2. **Memory persistence** - Share verified facts across agents, eliminate redundancy
3. **Parallel execution** - Run independent phases concurrently for 30-50% speed gains
4. **Quality gates** - Validate each phase before proceeding
5. **Episodic learning** - Learn from successful executions to improve future workflows

## Usage

```
/reactree-dev [your feature request]
```

## Examples

**Authentication & Authorization:**
```
/reactree-dev add JWT authentication with refresh tokens
/reactree-dev implement OAuth2 login with Google
/reactree-dev add SSO integration with SAML
/reactree-dev create role-based access control system
```

**API Development:**
```
/reactree-dev create REST API for user management
/reactree-dev add GraphQL endpoint for products
/reactree-dev build webhook receiver for Stripe events
/reactree-dev implement API versioning with v2 namespace
```

**Real-time Features:**
```
/reactree-dev add real-time notifications with Action Cable
/reactree-dev implement live chat feature
/reactree-dev create collaborative document editing
/reactree-dev add live dashboard updates with Turbo Streams
```

**Background Processing:**
```
/reactree-dev implement Sidekiq job for report generation
/reactree-dev add async email processing
/reactree-dev create scheduled data synchronization
/reactree-dev build batch import with progress tracking
```

**UI/Frontend:**
```
/reactree-dev add Hotwire-powered search with autocomplete
/reactree-dev create ViewComponent for user card
/reactree-dev implement TailAdmin dashboard layout
/reactree-dev build Stimulus controller for form validation
```

**Data & Models:**
```
/reactree-dev add Order model with polymorphic associations
/reactree-dev create migration for multi-tenant schema
/reactree-dev implement soft delete for all models
/reactree-dev add full-text search with PostgreSQL
```

## Development Types Supported

### New Feature Development
- Complete feature with models, services, UI, and tests
- Multi-layer implementation following conventions
- Parallel execution of independent components

### API Endpoint Creation
- RESTful resource endpoints
- GraphQL queries and mutations
- Webhook handlers
- API versioning

### Background Job Implementation
- Sidekiq/ActiveJob workers
- Scheduled tasks
- Async processing pipelines
- Retry and error handling

### Real-time Feature Development
- Action Cable channels
- Turbo Streams broadcasts
- Live updates and notifications
- Collaborative features

### UI Component Building
- ViewComponents with previews
- Hotwire/Turbo integration
- Stimulus controllers
- TailAdmin patterns

### Data Model Design
- ActiveRecord models with validations
- Complex associations
- Database migrations
- Query optimization

## Workflow Phases

### Phase 0: Setup
Initialization:
1. Discover available skills in `.claude/skills/`
2. Initialize working memory system
3. Load episodic memory for patterns
4. Create beads issue for tracking (if available)

### Phase 2: Inspection
With codebase-inspector:
1. Analyze existing patterns and conventions
2. Identify integration points
3. Understand authentication/authorization context
4. Map data model requirements
5. Write findings to working memory

### Phase 3: Planning
With rails-planner:
1. Design implementation architecture
2. Identify parallel execution opportunities
3. Plan database schema changes
4. Define service interfaces
5. Map component dependencies

### Phase 4: Implementation
With implementation-executor (parallel where possible):
1. Generate database migrations
2. Create models with validations and specs
3. Build service objects with tests
4. Implement UI components
5. Add API endpoints if needed
6. Run tests after each component
7. Use FEEDBACK edges for failures

### Phase 5: Review
With test-oracle:
1. Run full test suite
2. Validate coverage thresholds
3. Check quality gates
4. Verify all acceptance criteria

### Phase 6: Completion
Wrap-up:
1. Update documentation if needed
2. Close beads issue with summary
3. Record successful episode to episodic memory
4. Provide implementation summary

## Quality Gates

| Gate | Threshold | Action on Fail |
|------|-----------|----------------|
| Migrations | Run and rollback successfully | Block models |
| Models | Load successfully, specs pass | Block services |
| Services | Pattern correct, tests pass | Block components |
| Components | Render without errors | Block review |
| Full Suite | 100% pass, coverage > 90% | Block completion |

## FEEDBACK Edge Handling

If any phase fails:
1. Analyze failure with appropriate specialist
2. Route to feedback-coordinator
3. Apply fix and re-verify
4. Max 2 feedback rounds per phase before escalation

**Development-specific feedback types:**
- `MIGRATION_FAILED` - Database change issue
- `MODEL_INVALID` - Validation or association problem
- `SERVICE_ERROR` - Business logic failure
- `COMPONENT_BROKEN` - UI rendering issue
- `TEST_FAILED` - Spec failure requiring investigation

## Activation

```
{{TASK_REQUEST}}

Please activate the ReAcTree Rails Development workflow for the request above.

Follow this process:
1. **Phase 0: Setup**
   - Discover available skills in .claude/skills/
   - Initialize working memory system (.claude/reactree-memory.jsonl)
   - Create beads issue for tracking (if beads available)

2. **Phase 2: Inspection**
   - Use codebase-inspector to analyze existing patterns
   - Write verified facts to working memory
   - Identify integration points

3. **Phase 3: Planning**
   - Use rails-planner to design implementation
   - Identify parallel execution opportunities
   - Create dependency graph for phases

4. **Phase 4: Implementation**
   - Execute with parallel phases where possible
   - Run tests after each component
   - Use FEEDBACK edges for any failures
   - Coordinate specialist agents

5. **Phase 5: Review**
   - Use test-oracle to verify all tests pass
   - Check coverage thresholds
   - Validate quality gates

6. **Phase 6: Completion**
   - Close beads issue with summary
   - Record successful episode to episodic memory
   - Provide implementation summary

Start by discovering skills and initializing memory systems.
```

## Specialist Agents Used

- **workflow-orchestrator** (Blue) - Master coordination and phase management
- **codebase-inspector** (Cyan) - Pattern discovery and convention analysis
- **rails-planner** (Green) - Implementation architecture and parallel planning
- **implementation-executor** (Yellow) - Code generation following conventions
- **test-oracle** (Green) - Test planning, validation, and TDD enforcement
- **feedback-coordinator** (Purple) - Error routing and fix cycles
- **control-flow-manager** (Purple) - LOOP/CONDITIONAL execution patterns
- **file-finder** (Cyan) - Fast file discovery in Rails projects
- **code-line-finder** (Orange) - Precise code location with LSP
- **git-diff-analyzer** (Magenta) - Change analysis and PR preparation
- **log-analyzer** (Red) - Rails log parsing for debugging

## Skills Used

Skills loaded from `${CLAUDE_PLUGIN_ROOT}/skills/`:

**Core Skills**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-conventions/SKILL.md` - Rails patterns and conventions
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-error-prevention/SKILL.md` - Error prevention checklists
- `${CLAUDE_PLUGIN_ROOT}/skills/codebase-inspection/SKILL.md` - Analysis procedures
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-context-verification/SKILL.md` - Context verification

**Implementation Skills**:
- `${CLAUDE_PLUGIN_ROOT}/skills/activerecord-patterns/SKILL.md` - Database and models
- `${CLAUDE_PLUGIN_ROOT}/skills/service-object-patterns/SKILL.md` - Service layer patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/hotwire-patterns/SKILL.md` - Turbo/Stimulus integration
- `${CLAUDE_PLUGIN_ROOT}/skills/viewcomponents-specialist/SKILL.md` - Component architecture
- `${CLAUDE_PLUGIN_ROOT}/skills/sidekiq-async-patterns/SKILL.md` - Background job patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/api-development-patterns/SKILL.md` - REST API patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/ruby-oop-patterns/SKILL.md` - OOP and design patterns

**UI/Frontend Skills**:
- `${CLAUDE_PLUGIN_ROOT}/skills/tailadmin-patterns/SKILL.md` - TailAdmin UI patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/localization/SKILL.md` - I18n/L10n support

**Testing Skills**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rspec-testing-patterns/SKILL.md` - Comprehensive testing

**Domain Skills**:
- `${CLAUDE_PLUGIN_ROOT}/skills/requirements-writing/SKILL.md` - User story structure

**Meta Skills**:
- `${CLAUDE_PLUGIN_ROOT}/skills/reactree-patterns/SKILL.md` - ReAcTree workflow patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/smart-detection/SKILL.md` - Intent detection

## Memory Files

The plugin creates memory files in your project:

- `.claude/reactree-memory.jsonl` - **Working memory** (shared knowledge across agents)
- `.claude/reactree-episodes.jsonl` - **Episodic memory** (successful execution history)
- `.claude/reactree-feedback.jsonl` - **Feedback state** (error tracking)
- `.claude/reactree-state.jsonl` - **Control flow state** (LOOP/CONDITIONAL progress)

These files enable:
- Faster workflows (cached patterns)
- Consistent decisions (verified facts shared)
- Continuous improvement (learn from success)

## Configuration

The plugin uses `.claude/reactree-rails-dev.local.md` for settings:

```yaml
---
enabled: true
quality_gates_enabled: true
test_coverage_threshold: 90
auto_commit: false
---
```

## Beads Integration

All work tracked in beads (if installed):
- Main feature epic created
- Subtasks for each implementation phase
- Dependencies enforced
- Progress visible with `bd list` and `bd show [issue-id]`

## Best Practices

1. **Let skills guide implementation** - Use discovered conventions
2. **Trust working memory** - Don't re-analyze verified facts
3. **Leverage parallelism** - Independent phases run concurrently
4. **Validate incrementally** - Test after each component
5. **Use FEEDBACK edges** - Let the system self-correct
6. **Record episodes** - Future workflows benefit from past success
7. **Follow quality gates** - Don't skip validation

## Anti-Patterns to Avoid

- **Ignoring discovered patterns** - The codebase knows best
- **Redundant analysis** - Working memory exists for a reason
- **Sequential everything** - Use parallel execution opportunities
- **Skipping quality gates** - They exist for a reason
- **Manual error handling** - Let FEEDBACK edges work
- **Not recording episodes** - Loses learning opportunity

## Specialized Variants

For specific use cases, consider:
- `/reactree-feature` - Feature-driven with user stories and TDD emphasis
- `/reactree-debug` - Systematic debugging with root cause analysis
- `/reactree-refactor` - Safe refactoring with test preservation

## Troubleshooting

**Workflow interrupted?**
- State saved in memory files
- Re-run to continue from last checkpoint

**Quality gates too strict?**
- Temporarily disable in `.claude/reactree-rails-dev.local.md`
- Set `quality_gates_enabled: false`

**Skills not being used?**
- Verify skills exist in `.claude/skills/`
- Run `/reactree-init` to discover and copy bundled skills

---

This workflow integrates with the ReAcTree memory systems:
- **Working Memory**: Tracks verified facts, patterns, and component states
- **Episodic Memory**: Learns from successful implementations
- **FEEDBACK Edges**: Enables self-correction when phases fail
