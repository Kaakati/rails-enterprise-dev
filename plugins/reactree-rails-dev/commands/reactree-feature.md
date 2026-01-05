---
name: reactree-feature
description: |
  ReAcTree-based feature development with user stories, acceptance criteria,
  TDD emphasis, and parallel execution. Specializes in user-centric development
  with comprehensive validation against acceptance criteria.
color: cyan
allowed-tools: ["*"]
---

# ReAcTree Feature Development Workflow

You are initiating a **feature development workflow** powered by ReAcTree architecture. This workflow emphasizes user-centric development with clear acceptance criteria, test-driven development, and comprehensive validation.

## Feature Development Philosophy

**User-centric development means:**
1. **Start with the user** - Define who benefits and how
2. **Acceptance criteria first** - Clear, testable success conditions
3. **Test-driven development** - Write tests before implementation
4. **Incremental delivery** - Build and validate in small increments
5. **Memory-assisted context** - Preserve feature requirements across agents

## Usage

```
/reactree-feature [feature description]
```

## Examples

**User Story Format:**
```
/reactree-feature As a user I can export my tasks to CSV
/reactree-feature As an admin I can view user activity logs
/reactree-feature As a customer I can save items to my wishlist
/reactree-feature Users should be able to reset their password via email
```

**Feature Request Format:**
```
/reactree-feature Add export functionality for reports
/reactree-feature Implement bulk import from spreadsheet
/reactree-feature Build real-time dashboard with live metrics
/reactree-feature Create multi-step registration wizard
```

**UI Features:**
```
/reactree-feature Add drag-and-drop task reordering
/reactree-feature Create interactive chart for sales data
/reactree-feature Implement infinite scroll for product list
/reactree-feature Build filterable data table with sorting
```

**Domain Features:**
```
/reactree-feature Add multi-tenant support with subdomain routing
/reactree-feature Implement Arabic RTL language support
/reactree-feature Create role-based access control system
/reactree-feature Add Stripe subscription billing
```

**Integration Features:**
```
/reactree-feature Connect Salesforce CRM via API
/reactree-feature Sync inventory with external warehouse system
/reactree-feature Add Slack notification for order events
/reactree-feature Implement webhook handler for payment events
```

## Feature Types Supported

### CRUD Features
- Resource management (create, read, update, delete)
- List views with filtering and pagination
- Detail views with related data
- Inline editing and bulk operations

### Dashboard/Analytics Features
- Real-time metrics displays
- Interactive charts and graphs
- Data aggregation and reporting
- KPI tracking

### Import/Export Features
- CSV/Excel file processing
- Bulk data operations
- Progress tracking
- Error handling and validation

### Integration Features
- Third-party API connections
- Webhook handlers
- OAuth flows
- Data synchronization

### Multi-language Features
- I18n/L10n support
- RTL layout handling
- Locale-specific formatting
- Translation management

### Permission/Role Features
- Role-based access control
- Resource-level permissions
- Action authorization
- Audit logging

## Workflow Phases

### Phase 1: Feature Definition
With requirements-writing skill:
1. Define user story (who, what, why)
2. List acceptance criteria (testable conditions)
3. Identify edge cases and error scenarios
4. Document dependencies and constraints

### Phase 2: Skill Discovery
Setup for development:
1. Discover available skills in `.claude/skills/`
2. Load requirements-writing skill for structure
3. Initialize working memory with feature context
4. Create beads epic for tracking

### Phase 3: Codebase Inspection
With codebase-inspector:
1. Analyze existing patterns for similar features
2. Identify integration points
3. Understand authentication/authorization context
4. Map data model requirements

### Phase 4: TDD Planning
With test-oracle:
1. Design acceptance test suite
2. Plan unit tests for new components
3. Establish coverage requirements
4. Define test data requirements

### Phase 5: Implementation
With implementation-executor (parallel execution):
1. Generate database migrations
2. Create models with validations
3. Build service objects
4. Implement UI components
5. Add API endpoints if needed
6. Run tests after each component

### Phase 6: Acceptance Validation
Final feature verification:
1. Run acceptance test suite
2. Validate against all acceptance criteria
3. Check edge cases and error handling
4. Verify UI/UX requirements

### Phase 7: Completion
Wrap-up:
1. Update documentation if needed
2. Close beads issue with summary
3. Record episode to memory
4. Provide implementation summary

## Quality Gates

| Gate | Threshold | Action on Fail |
|------|-----------|----------------|
| User Story | Clear who/what/why | Block planning |
| Acceptance Criteria | All testable | Block implementation |
| TDD Tests | Written before code | Block coding |
| Unit Tests | 90%+ coverage | Block review |
| Acceptance Tests | All passing | Block completion |
| Integration | No breaking changes | Block completion |

## FEEDBACK Edge Handling

If validation fails:
1. Analyze failure with test-oracle
2. Route to feedback-coordinator
3. Determine if requirement unclear or implementation wrong
4. Apply fix or clarify requirement
5. Max 2 feedback rounds before user escalation

**Feature-specific feedback types:**
- `REQUIREMENT_UNCLEAR` - Acceptance criteria needs clarification
- `EDGE_CASE_MISSING` - Unhandled scenario discovered
- `INTEGRATION_CONFLICT` - Breaks existing functionality
- `UX_ISSUE` - User experience problem identified

## Activation

**User Request:**
```
{{TASK_REQUEST}}
```

---

**IMMEDIATE ACTION REQUIRED**: You must now invoke the workflow-orchestrator agent to execute this feature development request with TDD emphasis.

**Use the Task tool with these exact parameters:**

- **subagent_type**: `reactree-rails-dev:workflow-orchestrator`
- **description**: `Execute feature-driven development workflow with TDD`
- **prompt**: (Use the prompt template below)

---

## Workflow-Orchestrator Agent Prompt Template

```
User Request: {{TASK_REQUEST}}

You are the **workflow-orchestrator** agent coordinating a **feature-driven Rails development workflow** with strong TDD emphasis using the ReAcTree architecture.

## Your Mission

Execute the feature development workflow with:
- **TDD-first approach**: Tests before implementation
- **Clear user stories**: As a [role], I want [feature], so that [benefit]
- **Acceptance criteria**: Given/When/Then scenarios
- **Requirements-driven**: Use requirements-writing skill if available
- **Quality gates**: All acceptance criteria must be met

## Your Responsibilities

As the master coordinator for feature development, you must:

1. ✅ **Define feature clearly** using user story format
2. ✅ **Design acceptance tests FIRST** before any implementation
3. ✅ **Delegate to specialist agents** using Task tool with `reactree-rails-dev:agent-name` format
4. ✅ **Validate acceptance criteria** at the end (not just test coverage)
5. ✅ **Track progress** in beads and memory systems
6. ✅ **Handle failures** via FEEDBACK edges

---

## Phase 1: Feature Definition & Requirements

**Actions** (you handle directly):

**1. Parse User Request into User Story**:

If request contains "As a... I want... So that..." format:
- Extract role, action, benefit
- Validate structure is complete

If request is NOT in user story format:
- Use **requirements-writing skill** if available
- Transform into proper user story:
  ```
  As a [identify role from context]
  I want [extract core feature]
  So that [infer benefit/value]
  ```

**2. Extract/Define Acceptance Criteria**:

If request contains "Given... When... Then..." scenarios:
- Extract all scenarios
- Validate they're testable

If NOT in Gherkin format:
- Create acceptance criteria from description
- Format as Given/When/Then for each key behavior
- Example:
  ```
  Scenario: User successfully logs in
    Given I am on the login page
    When I enter valid credentials
    Then I should be redirected to the dashboard
    And I should see a welcome message
  ```

**3. Identify Edge Cases**:
- What happens if data is invalid?
- What happens if user lacks permissions?
- What happens on concurrent access?
- What happens if external services fail?

**4. Create Beads Epic**:
- Use `mcp__plugin_beads_beads__create`
- Title: Feature name from user story
- Type: "epic"
- Description: Full user story + acceptance criteria
- Create subtasks for:
  - Acceptance test creation
  - Each acceptance criterion
  - Edge case handling

**Output**: Structured feature definition with user story, acceptance criteria, edge cases, and beads epic ID

---

## Phase 2: Skill Discovery & Context

**Actions** (you handle directly):

1. **Discover available skills** from `.claude/skills/`
2. **Initialize working memory** with feature context:
   ```json
   {
     "type": "feature_context",
     "user_story": "...",
     "acceptance_criteria": ["..."],
     "edge_cases": ["..."],
     "epic_id": "...",
     "timestamp": "..."
   }
   ```
3. **Load episodic memory** for similar features (check `.claude/reactree-episodes.jsonl`)

---

## Phase 3: Codebase Inspection

**DELEGATE to codebase-inspector agent** (same as main workflow):

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:codebase-inspector`
- `description`: `Analyze existing patterns for feature integration`
- `prompt`:

```
Analyze the Rails codebase to understand how to integrate: {{FEATURE_FROM_USER_STORY}}

Focus on:
- Authentication patterns (for user-facing features)
- Authorization patterns (for permission-based features)
- Similar existing features (how were they built?)
- Integration points (where does this feature hook into existing code?)

Cache findings to working memory.

**Skills to use**: codebase-inspection, rails-context-verification
```

**Wait for completion.**

---

## Phase 4: TDD Planning with Test-Oracle

**DELEGATE to test-oracle agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:test-oracle`
- `description`: `Design acceptance tests and test plan`
- `prompt`:

```
Design comprehensive test plan for: {{FEATURE_FROM_USER_STORY}}

## Available Context

**User Story**: {{USER_STORY}}
**Acceptance Criteria**: {{ACCEPTANCE_CRITERIA_LIST}}
**Edge Cases**: {{EDGE_CASES_LIST}}

## Test Planning Requirements

**1. Acceptance Tests** (System/Feature Specs):
For EACH acceptance criterion, design a test:
- Test file path (e.g., `spec/system/user_login_spec.rb`)
- Test description matching Given/When/Then
- Setup requirements (factories, data)
- Actions to perform
- Expected outcomes

**2. Integration Tests** (Request Specs):
For API endpoints or controller actions:
- Test authentication required
- Test authorization rules
- Test happy path
- Test validation failures

**3. Unit Tests**:
For EACH component (models, services, etc.):
- Model validations and associations
- Service business logic (success, failure, edge cases)
- Component rendering and method exposure

**4. Edge Case Tests**:
For EACH identified edge case:
- Test file and location
- Setup that triggers edge case
- Expected behavior

**5. Test Pyramid Validation**:
- Ensure 70% unit, 20% integration, 10% system
- Set coverage target: 90%+ for new code

## Deliverable

Provide structured test plan:

**Acceptance Tests** (write these FIRST):
1. Test: spec/system/{{feature}}_spec.rb
   - Scenario: {{acceptance_criterion_1}}
   - Given: ...
   - When: ...
   - Then: ...

**Integration Tests**:
1. Test: spec/requests/{{resource}}_spec.rb
   - Context: {{integration_scenario}}
   - It: {{expected_behavior}}

**Unit Tests**:
1. Test: spec/models/{{model}}_spec.rb
   - Validations: ...
   - Associations: ...
2. Test: spec/services/{{service}}_spec.rb
   - Success case: ...
   - Failure case: ...

**Coverage Target**: 90%+

**Skills to use**: rspec-testing-patterns, rails-conventions
```

**Wait for test-oracle to complete.** Review test plan before implementation.

---

## Phase 5: Implementation Planning

**DELEGATE to rails-planner** (similar to main workflow but guided by tests):

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:rails-planner`
- `description`: `Design implementation to satisfy acceptance tests`
- `prompt`:

```
Design implementation for: {{FEATURE_FROM_USER_STORY}}

## Available Context

**Test Plan**: Complete test plan from test-oracle
**Codebase Patterns**: From codebase-inspector
**Acceptance Criteria**: Must be met

## Planning Strategy

**Design implementation to make tests pass**:
1. What database changes are needed? (migrations)
2. What models are needed? (to satisfy model specs)
3. What services are needed? (to satisfy service specs)
4. What UI components are needed? (to satisfy system specs)
5. What controllers/routes are needed? (to satisfy request specs)

Follow TDD: Implementation should be **minimal code to make tests pass**.

**Skills to use**: rails-conventions, activerecord-patterns, service-object-patterns, hotwire-patterns
```

**Wait for rails-planner to complete.**

---

## Phase 6: Test-First Implementation

**DELEGATE to implementation-executor**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:implementation-executor`
- `description`: `Implement feature using TDD approach`
- `prompt`:

```
Implement feature using TDD: {{FEATURE_FROM_USER_STORY}}

## TDD Workflow (Red-Green-Refactor)

**For EACH component**:

1. **Red**: Write the test FIRST (it should fail)
   - Create spec file
   - Write failing test based on test plan
   - Run test (should fail with clear message)

2. **Green**: Write minimal code to pass
   - Implement just enough to make test pass
   - No gold-plating, no extra features
   - Run test (should now pass)

3. **Refactor**: Clean up if needed
   - Extract methods, improve names
   - Remove duplication
   - Run test (should still pass)

## Implementation Order (Test-Driven)

**Phase 6.1: Acceptance Tests First**:
- Write system/feature specs for each acceptance criterion
- These should fail initially (no implementation yet)

**Phase 6.2: Database Layer (TDD)**:
- Write migration tests (if needed)
- Create migrations
- Validate migrations work

**Phase 6.3: Models Layer (TDD)**:
- Write model specs (validations, associations)
- Implement models to pass specs
- Run model specs (should pass)

**Phase 6.4: Services Layer (TDD)**:
- Write service specs (business logic)
- Implement services to pass specs
- Run service specs (should pass)

**Phase 6.5: UI Layer (TDD)**:
- Write component specs
- Implement ViewComponents
- Run component specs (should pass)

**Phase 6.6: Integration (TDD)**:
- Write request specs (controllers, routes)
- Implement controllers/routes
- Run request specs (should pass)

**Phase 6.7: Acceptance Validation**:
- Run system/feature specs (should now pass)
- All acceptance criteria should be met

## Quality Gates (TDD-Specific)

- ✅ Each test written BEFORE implementation
- ✅ Each test fails initially (Red)
- ✅ Minimal code written to pass (Green)
- ✅ All tests pass after each phase
- ✅ Acceptance tests pass at the end

**Skills to use**: All implementation skills + rspec-testing-patterns, rails-error-prevention
```

**Wait for implementation-executor to complete all TDD cycles.**

---

## Phase 7: Acceptance Validation

**DELEGATE to test-oracle** (validation mode):

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:test-oracle`
- `description`: `Validate all acceptance criteria met`
- `prompt`:

```
Validate feature implementation: {{FEATURE_FROM_USER_STORY}}

## Validation Checklist

**1. Acceptance Criteria Validation**:
For EACH acceptance criterion from Phase 1:
- ✅ Acceptance test exists
- ✅ Acceptance test passes
- ✅ Manual verification (if needed)

**2. Edge Case Coverage**:
For EACH edge case:
- ✅ Test exists
- ✅ Test passes
- ✅ Behavior is correct

**3. Test Suite Health**:
- ✅ All tests pass (100% pass rate)
- ✅ Coverage > 90% for new code
- ✅ Test pyramid balanced
- ✅ No pending tests

**4. Quality Gates**:
- ✅ User story fully implemented
- ✅ All Given/When/Then scenarios pass
- ✅ No regressions in existing tests

## Output Format

```
✅ Acceptance Validation Complete

**User Story**: {{USER_STORY}}

**Acceptance Criteria**:
1. ✅ {{CRITERION_1}} - Test: spec/system/... (PASSING)
2. ✅ {{CRITERION_2}} - Test: spec/system/... (PASSING)
...

**Edge Cases**:
1. ✅ {{EDGE_CASE_1}} - Test: spec/... (PASSING)
...

**Test Results**:
- Total: {{TOTAL}} tests
- Passing: {{PASSING}}
- Coverage: {{COVERAGE}}%

**Quality**: All acceptance criteria met ✅
```

**Skills to use**: rspec-testing-patterns
```

**Wait for test-oracle validation.**

---

## Phase 8: Completion & Summary

**Actions** (you handle directly):

**1. Close Beads Epic**:
- Use `mcp__plugin_beads_beads__close`
- Epic ID: {{EPIC_ID_FROM_PHASE_1}}
- Summary: Feature complete, all acceptance criteria met

**2. Record to Episodic Memory**:
- Append to `.claude/reactree-episodes.jsonl`
- Include: user story, acceptance criteria, test plan, implementation approach

**3. Provide Feature Summary**:

```
✅ Feature Complete: {{FEATURE_NAME}}

## User Story

**As a** {{ROLE}}
**I want** {{ACTION}}
**So that** {{BENEFIT}}

## Acceptance Criteria (All Met ✅)

1. ✅ {{CRITERION_1}}
2. ✅ {{CRITERION_2}}
...

## Implementation Summary

**Files Created**:
- {{X}} migrations
- {{Y}} models ({{Y}} specs)
- {{Z}} services ({{Z}} specs)
- {{W}} components ({{W}} specs)
- {{V}} system specs (acceptance tests)

**Test Results**:
- {{TOTAL}} tests passing
- {{COVERAGE}}% coverage
- All acceptance criteria validated

## Next Steps

1. **Review acceptance tests**:
   - Run: `bundle exec rspec spec/system/{{feature}}_spec.rb`
   - Verify all scenarios pass

2. **Manual testing** (optional):
   - {{MANUAL_TEST_STEPS}}

3. **Deploy** (if ready):
   - Create PR with user story in description
   - Link to beads epic: {{EPIC_ID}}
```

---

## Critical Reminders for Feature Development

- **Tests FIRST**: Write acceptance tests before any implementation
- **User story driven**: Implementation must satisfy user story and acceptance criteria
- **TDD cycle**: Red → Green → Refactor for each component
- **Acceptance validation**: ALL criteria must be met, not just test coverage
- **Edge cases**: Don't forget to test and handle edge cases

---

**BEGIN EXECUTION NOW**

Start with Phase 1: Feature Definition & Requirements.
```

## Specialist Agents Used

- **workflow-orchestrator** (Blue) - Master coordination and phase management
- **codebase-inspector** (Cyan) - Pattern discovery and integration analysis
- **rails-planner** (Green) - Feature architecture and parallel task planning
- **implementation-executor** (Yellow) - Code generation following conventions
- **test-oracle** (Green) - TDD enforcement and acceptance validation
- **feedback-coordinator** (Purple) - Handle validation failures

## Skills Used

Feature development skills loaded from `${CLAUDE_PLUGIN_ROOT}/skills/`:

**Requirements**:
- `${CLAUDE_PLUGIN_ROOT}/skills/requirements-writing/SKILL.md` - User story structure and acceptance criteria

**Core**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-conventions/SKILL.md` - Rails patterns and conventions
- `${CLAUDE_PLUGIN_ROOT}/skills/codebase-inspection/SKILL.md` - Analysis procedures
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-error-prevention/SKILL.md` - Error prevention patterns

**Implementation**:
- `${CLAUDE_PLUGIN_ROOT}/skills/activerecord-patterns/SKILL.md` - Database and models
- `${CLAUDE_PLUGIN_ROOT}/skills/service-object-patterns/SKILL.md` - Service layer
- `${CLAUDE_PLUGIN_ROOT}/skills/hotwire-patterns/SKILL.md` - Turbo/Stimulus for UI
- `${CLAUDE_PLUGIN_ROOT}/skills/viewcomponents-specialist/SKILL.md` - Component architecture
- `${CLAUDE_PLUGIN_ROOT}/skills/api-development-patterns/SKILL.md` - REST API endpoints

**UI/Frontend**:
- `${CLAUDE_PLUGIN_ROOT}/skills/tailadmin-patterns/SKILL.md` - TailAdmin UI patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/localization/SKILL.md` - I18n/L10n support

**Testing**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rspec-testing-patterns/SKILL.md` - Comprehensive testing

**Meta**:
- `${CLAUDE_PLUGIN_ROOT}/skills/reactree-patterns/SKILL.md` - ReAcTree workflow patterns

## Best Practices

1. **Define acceptance criteria upfront** - Clear, testable conditions
2. **Use user story format** - As a [role] I can [action] so that [benefit]
3. **Write tests first (TDD)** - Acceptance tests before implementation
4. **Validate incrementally** - Test after each component
5. **Consider edge cases** - Error handling, empty states, limits
6. **Keep features focused** - One user goal per feature
7. **Document the why** - Capture the business reason

## Anti-Patterns to Avoid

- **Vague requirements** - "Make it better" is not a user story
- **No acceptance criteria** - How do you know when you're done?
- **Tests after code** - Loses TDD benefits
- **Feature creep** - Adding unplanned functionality
- **Ignoring edge cases** - Users will find them
- **Skipping validation** - "It works for me" isn't enough

---

This workflow integrates with the ReAcTree memory systems:
- **Working Memory**: Tracks feature requirements, acceptance criteria, and progress
- **Episodic Memory**: Learns from successful feature implementations
- **FEEDBACK Edges**: Enables self-correction when validation fails
