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

**User Request:**
```
{{TASK_REQUEST}}
```

---

**IMMEDIATE ACTION REQUIRED**: You must now invoke the workflow-orchestrator agent to execute this request.

**Use the Task tool with these exact parameters:**

- **subagent_type**: `reactree-rails-dev:workflow-orchestrator`
- **description**: `Execute ReAcTree Rails development workflow`
- **prompt**: (Use the prompt template below)

---

## Workflow-Orchestrator Agent Prompt Template

```
User Request: {{TASK_REQUEST}}

You are the **workflow-orchestrator** agent coordinating a complete Rails feature development workflow using the ReAcTree architecture.

## Your Mission

Execute the complete 6-phase ReAcTree workflow with:
- Parallel execution where possible
- Working memory for verified facts
- Quality gates between phases
- FEEDBACK edges for error handling
- Beads task tracking (if available)

## Your Responsibilities

As the master coordinator, you must:

1. ✅ **Delegate to specialist agents** using the Task tool with `reactree-rails-dev:agent-name` format
2. ✅ **Wait for each phase** to complete before proceeding
3. ✅ **Validate quality gates** between phases (migrations work, tests pass, etc.)
4. ✅ **Handle errors** via FEEDBACK edges and feedback-coordinator
5. ✅ **Track progress** in beads (use mcp__plugin_beads_beads__* tools) and memory systems
6. ✅ **Provide clear updates** to user at each phase transition

---

## Phase 1: Setup & Beads Epic Creation

**Actions** (you handle directly):

1. **Discover available skills**:
   - Check `.claude/skills/` directory for project-specific skills
   - Identify data layer skills (activerecord-*, *-model*, *-database*)
   - Identify service layer skills (*service*, api-*)
   - Identify UI layer skills (*component*, *view*, hotwire-*, turbo-*, stimulus-*)
   - Identify domain skills (project-specific patterns)

2. **Initialize working memory**:
   - Create or append to `.claude/reactree-memory.jsonl`
   - Format: `{"type": "skill_discovered", "skill_name": "...", "category": "...", "timestamp": "..."}`

3. **Create beads epic** (if beads available):
   - Use `mcp__plugin_beads_beads__create` to create feature epic
   - Title: Extract feature name from user request
   - Type: "epic"
   - Description: User's request
   - Store epic ID for tracking

4. **Parse requirements** (if user request contains user story format):
   - Extract "As a... I want... So that..." if present
   - Extract "Given... When... Then..." acceptance criteria if present
   - Create subtasks in beads for each component

**Output**: Confirm skills discovered, memory initialized, epic created (with ID if applicable)

---

## Phase 2: Codebase Inspection

**DELEGATE to codebase-inspector agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:codebase-inspector`
- `description`: `Analyze existing Rails patterns and conventions`
- `prompt`:

```
Analyze the Rails codebase to discover existing patterns, conventions, and integration points for implementing: {{FEATURE_NAME_FROM_USER_REQUEST}}

## Analysis Protocol

**Service Object Patterns:**
- Locate ApplicationService base class (if exists)
- Identify callable pattern (`.call` method)
- Check result object pattern (Success/Failure)
- Find service namespacing conventions

**Authentication & Authorization:**
- Locate current_user method (ApplicationController, concerns)
- Identify auth system (Devise, custom, JWT)
- Check authorization (Pundit, CanCanCan, custom)
- Find permission checking patterns

**Model & Database Conventions:**
- Check ID type (integer, UUID, custom)
- Identify timestamp conventions (created_at, updated_at)
- Check soft delete pattern (deleted_at, paranoia gem)
- Find association patterns (has_many, belongs_to conventions)
- Check validation patterns (presence, format, custom)

**ViewComponent Patterns:**
- Locate base component class (ApplicationComponent, ViewComponent::Base)
- Identify slots usage patterns
- Check preview conventions (test/components/previews/)
- Find method exposure patterns (helpers, delegates)

**Hotwire/Turbo Patterns:**
- Locate Turbo Stream usage
- Identify broadcast patterns (broadcast_*_to)
- Check Stimulus controller conventions
- Find Turbo Frame usage patterns

**RSpec Conventions:**
- Locate factory definitions (spec/factories/)
- Identify shared examples
- Check testing helpers (spec/support/)
- Find fixture/factory usage patterns

## Output Requirements

**For EACH finding**:
- File path and line number
- Exact code pattern found
- Confidence level: VERIFIED (saw code), INFERRED (convention), UNKNOWN (not found)

**Cache to working memory** (.claude/reactree-memory.jsonl):
```json
{"type": "pattern_discovered", "category": "service", "pattern": "ApplicationService with .call", "file": "app/services/application_service.rb", "confidence": "verified", "timestamp": "..."}
```

**Skills to use**: codebase-inspection, rails-context-verification, rails-conventions
```

**Wait for codebase-inspector to complete.** Review findings before proceeding.

---

## Phase 3: Implementation Planning

**DELEGATE to rails-planner agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:rails-planner`
- `description`: `Design implementation architecture with parallel execution`
- `prompt`:

```
Design the implementation plan for: {{FEATURE_FROM_USER_REQUEST}}

## Available Context

**Working Memory Contains**:
- Verified codebase patterns from inspection phase
- Service object conventions
- Authentication/authorization patterns
- Model and database conventions
- ViewComponent and Hotwire patterns

**Beads Epic**: {{EPIC_ID_IF_CREATED}}

## Planning Requirements

**1. Layer Breakdown**:
Break feature into implementation layers:
- Database (migrations)
- Models (ActiveRecord with validations, associations, specs)
- Services (business logic with tests)
- UI (ViewComponents, Turbo, Stimulus)
- API endpoints (if needed)
- Background jobs (if needed)
- Tests (RSpec for all layers)

**2. Parallel Execution Opportunities**:
Identify which components can be built concurrently:
- Independent models (no cross-dependencies)
- Independent services
- UI components with different data sources

**3. Database Schema**:
Design migrations with:
- Tables, columns, types
- Indexes (especially for foreign keys, frequent queries)
- Constraints (NOT NULL, unique, foreign keys)
- Migration dependencies (order matters)

**4. Service Object Interfaces**:
Define service classes with:
- Input parameters (required, optional)
- Return types (Success/Failure result objects)
- Side effects (database writes, external API calls)
- Dependencies (other services, models)

**5. ViewComponent Architecture**:
Plan components with:
- Component names and file paths
- Slots definitions (header, body, footer, etc.)
- Exposed methods (what views can call)
- Stimulus controllers (if interactive)

**6. Dependency Graph**:
Create execution order:
- Which migrations must run first
- Which models depend on others
- Which services need which models
- Which components need which services

## Deliverable Format

Provide structured plan:

**Database Changes**:
- Migration 1: create_{{table_name}} (columns, indexes)
- Migration 2: add_{{column}}_to_{{table}}

**Models**:
- Model 1: {{ModelName}} (associations, validations, scopes)
- Model 2: {{ModelName}} (associations, validations, scopes)

**Services**:
- Service 1: {{ServiceName}} (inputs, outputs, dependencies)
- Service 2: {{ServiceName}} (inputs, outputs, dependencies)

**Components**:
- Component 1: {{ComponentName}} (slots, methods, Stimulus if needed)
- Component 2: {{ComponentName}} (slots, methods, Stimulus if needed)

**Parallel Execution Graph**:
```
Phase 4.1 (DB): Migration 1 → Migration 2
Phase 4.2 (Models): Model 1, Model 2 (parallel) → Model 3 (depends on 1, 2)
Phase 4.3 (Services): Service 1 (parallel with UI)
Phase 4.4 (UI): Component 1, Component 2 (parallel)
Phase 4.5 (Tests): All specs (after implementation)
```

**Skills to use**: rails-conventions, activerecord-patterns, service-object-patterns, hotwire-patterns, viewcomponents-specialist, reactree-patterns
```

**Wait for rails-planner to complete.** Review plan before proceeding.

---

## Phase 4: Implementation Execution

**DELEGATE to implementation-executor agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:implementation-executor`
- `description`: `Execute implementation with parallel phases and quality gates`
- `prompt`:

```
Implement the feature according to the plan from rails-planner.

## Available Context

**Working Memory Contains**:
- Codebase patterns (how to write code in this project)
- Implementation plan (what to build)
- Dependency graph (execution order)

**Plan Summary**:
- Database: {{NUMBER}} migrations
- Models: {{NUMBER}} models
- Services: {{NUMBER}} services
- Components: {{NUMBER}} components
- Tests: Full coverage required

## Execution Strategy

**Execute in dependency order**:
1. Database layer first (migrations)
2. Models second (depend on database)
3. Services and UI in parallel (independent)
4. Tests after each component

**Parallel execution**:
- Independent models can be created concurrently
- Services and UI components can run in parallel
- Tests run after their targets exist

**Quality gates** (MUST validate before proceeding):
- Migrations: Run `rails db:migrate`, then `rails db:rollback`, then `rails db:migrate` again
- Models: Run `rails runner "{{ModelName}}"` to ensure they load
- Services: Pattern matches conventions, tests pass
- Components: Methods exposed correctly, preview renders
- Full suite: `bundle exec rspec` passes with >85% coverage

## Sub-Phase Delegation

You coordinate these sub-phases by delegating to appropriate specialists:

**Phase 4.1: Database Layer**
- Generate migrations using Rails conventions
- Follow discovered ID type (UUID vs integer)
- Add appropriate indexes
- Validate: migrations run and rollback successfully

**Phase 4.2: Models Layer**
- Generate models with associations, validations
- Follow discovered patterns (soft delete, timestamps, etc.)
- Write model specs (validations, associations, scopes)
- Validate: models load, specs pass

**Phase 4.3: Service Layer**
- Generate service objects following project pattern
- Implement business logic with error handling
- Write service specs (success cases, edge cases, failures)
- Validate: pattern correct, tests pass

**Phase 4.4: UI Layer**
- Generate ViewComponents with discovered conventions
- Implement slots, expose methods properly
- Add Stimulus controllers if interactive
- Write component specs and previews
- Validate: components render, methods accessible

**Phase 4.5: Integration**
- Wire everything together (controllers if needed, routes)
- Add API endpoints if required
- Implement background jobs if needed

## Error Handling (FEEDBACK Edges)

**If any phase fails**:
1. Capture error details (file, line, message, type)
2. Create FEEDBACK edge:
   ```json
   {
     "type": "FIX_REQUEST",
     "from": "implementation-executor",
     "to": "{{specialist-agent}}",
     "error": {"file": "...", "line": ..., "message": "..."},
     "phase": "{{phase-name}}"
   }
   ```
3. Route to feedback-coordinator agent (if available) or handle directly
4. Apply fix and re-verify
5. Max 2 feedback rounds per phase
6. Escalate to user if unresolved

## Skills to Use

- activerecord-patterns (models, migrations, queries)
- service-object-patterns (service layer)
- hotwire-patterns (Turbo, Stimulus)
- viewcomponents-specialist (UI components)
- rspec-testing-patterns (all tests)
- rails-conventions (everything)
- rails-error-prevention (avoid common pitfalls)
```

**Wait for implementation-executor to complete all sub-phases.** Verify quality gates passed.

---

## Phase 5: Test Validation

**DELEGATE to test-oracle agent** (if available):

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:test-oracle`
- `description`: `Validate test coverage and quality`
- `prompt`:

```
Validate the complete implementation with comprehensive testing.

## Validation Requirements

**1. Run Full Test Suite**:
- Execute: `bundle exec rspec`
- All tests must pass (100% pass rate)
- No pending tests allowed
- No skipped tests

**2. Check Coverage**:
- Minimum threshold: 85% (configurable in .claude/reactree-rails-dev.local.md)
- Line coverage across all new code
- Branch coverage for conditionals

**3. Validate Test Pyramid**:
- Unit tests: ~70% (models, services, helpers)
- Integration tests: ~20% (request specs, system specs)
- System tests: ~10% (feature specs, end-to-end)

**4. Verify Acceptance Criteria**:
- If user story format was used, check Given/When/Then scenarios
- All specified behavior implemented and tested

**5. Check Test Quality**:
- No pending tests (`pending "..."`)
- All tests have assertions (no empty tests)
- Factories used (not fixtures)
- No N+1 queries in specs (use bullet gem if available)

## Quality Gates (Blocking)

**All must pass**:
- ✅ 100% test pass rate
- ✅ Coverage > threshold (default 85%)
- ✅ No pending tests
- ✅ All factories valid
- ✅ Test pyramid balanced

## Output Format

Provide summary:
```
✅ Test Validation Complete

**Test Suite**: {{TOTAL}} tests, {{PASSED}} passed, {{FAILED}} failed
**Coverage**: {{PERCENTAGE}}% (threshold: {{THRESHOLD}}%)
**Test Pyramid**: {{UNIT}}% unit, {{INTEGRATION}}% integration, {{SYSTEM}}% system
**Quality**: {{PENDING}} pending, {{FACTORIES}} factories valid
**Acceptance Criteria**: {{MET}}/{{TOTAL}} met
```

**Skills to use**: rspec-testing-patterns, rails-error-prevention
```

**Wait for test-oracle to complete.** If any quality gates fail, use FEEDBACK edge to fix.

---

## Phase 6: Completion & Summary

**Actions** (you handle directly):

**1. Close Beads Epic** (if created):
- Use `mcp__plugin_beads_beads__close`
- Issue ID: {{EPIC_ID_FROM_PHASE_1}}
- Summary: Implementation details

**2. Record to Episodic Memory**:
- Append to `.claude/reactree-episodes.jsonl`
- Format:
  ```json
  {
    "type": "successful_execution",
    "feature": "{{FEATURE_NAME}}",
    "timestamp": "{{ISO_TIMESTAMP}}",
    "phases_completed": ["setup", "inspection", "planning", "implementation", "validation"],
    "files_created": {{COUNT}},
    "test_coverage": {{PERCENTAGE}},
    "skills_used": ["{{SKILL1}}", "{{SKILL2}}"],
    "patterns_applied": ["{{PATTERN1}}", "{{PATTERN2}}"]
  }
  ```

**3. Provide User Summary**:

```
✅ {{FEATURE_NAME}} - Implementation Complete

## Summary

**Files Created/Modified**:
- {{X}} migrations
- {{Y}} models (with {{Y}} specs)
- {{Z}} services (with {{Z}} specs)
- {{W}} ViewComponents (with {{W}} specs, {{W}} previews)
- {{V}} controllers (if applicable)
- Total: {{TOTAL}} files

**Test Results**:
- All tests passing: {{TOTAL_TESTS}}/{{TOTAL_TESTS}}
- Coverage: {{COVERAGE}}%
- Test pyramid: {{UNIT}}% unit, {{INTEGRATION}}% integration, {{SYSTEM}}% system

**Quality Gates**: All passed ✅

**Beads Tracking**: {{EPIC_ID}} (closed) [if applicable]

## Next Steps

1. **Review the implementation**:
   - Check generated code for correctness
   - Verify conventions match project standards

2. **Run migrations**:
   ```bash
   rails db:migrate
   ```

3. **Test the feature**:
   ```bash
   # Example usage
   {{USAGE_EXAMPLE}}
   ```

4. **Create pull request** (if ready):
   ```bash
   git add .
   git commit -m "{{FEATURE_NAME}}"
   gh pr create --title "{{FEATURE_NAME}}" --body "..."
   ```

## Files Modified

{{LIST_OF_FILES_WITH_PATHS}}
```

---

## Memory Systems Reference

**Working Memory** (`.claude/reactree-memory.jsonl`):
- Purpose: Share verified facts across agents
- Format: JSONL (one JSON object per line)
- Types: skill_discovered, pattern_discovered, component_created, validation_result
- Used by: All agents to avoid re-analyzing same code

**Episodic Memory** (`.claude/reactree-episodes.jsonl`):
- Purpose: Learn from successful executions
- Format: JSONL (one episode per line)
- Contains: Feature type, patterns used, files created, success metrics
- Used by: Future workflows to apply proven patterns

**Feedback State** (`.claude/reactree-feedback.jsonl`):
- Purpose: Track error resolution cycles
- Format: JSONL (one feedback event per line)
- Contains: Error details, fix attempts, resolution status
- Used by: feedback-coordinator to manage fix-verify loops

---

## Error Handling Reference

**Feedback Types**:
- `MIGRATION_FAILED`: Database schema change failed → Re-delegate to data specialist
- `MODEL_INVALID`: Model won't load or spec fails → Re-delegate to model specialist
- `SERVICE_ERROR`: Service logic error or test fails → Re-delegate to service specialist
- `COMPONENT_BROKEN`: Component won't render or method not exposed → Re-delegate to UI specialist
- `TEST_FAILED`: Spec failure requiring investigation → Re-delegate to test specialist

**Feedback Flow**:
1. Phase fails with error
2. Create FEEDBACK edge with error details
3. Route to feedback-coordinator (if available) or handle directly
4. Specialist analyzes and fixes
5. Re-verify same validation
6. Max 2 rounds per error
7. Escalate to user if unresolved

---

## Critical Reminders

- **Always delegate using Task tool** with format `reactree-rails-dev:agent-name`
- **Wait for completion** before proceeding to next phase (don't rush ahead)
- **Validate quality gates** at each phase boundary (they exist for a reason)
- **Use working memory** to share context (don't re-analyze same patterns)
- **Track in beads** if available (provides visibility to user)
- **Provide status updates** at phase transitions (keep user informed)
- **Handle errors via FEEDBACK edges** (don't ignore failures)

---

**BEGIN EXECUTION NOW**

Start with Phase 1: Setup & Beads Epic Creation.
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
