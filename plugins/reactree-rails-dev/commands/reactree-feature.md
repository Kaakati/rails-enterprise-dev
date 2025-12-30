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

```
{{TASK_REQUEST}}

Please activate the ReAcTree Feature Development workflow for the request above.

Follow this process:
1. **Feature Definition**
   - If requirements-writing skill available, use it for structure
   - Define clear user story (As a [role] I can [action] so that [benefit])
   - List specific acceptance criteria
   - Identify edge cases

2. **Skill Discovery**
   - Discover available skills in .claude/skills/
   - Initialize working memory with feature context
   - Create beads epic for tracking

3. **Codebase Inspection**
   - Use codebase-inspector to understand existing patterns
   - Identify integration points
   - Map data requirements

4. **TDD Planning**
   - Design acceptance tests with test-oracle
   - Plan unit tests for each component
   - Establish coverage targets

5. **Implementation**
   - Execute with parallel phases where possible
   - Run tests after each component
   - Use FEEDBACK edges for failures

6. **Acceptance Validation**
   - Verify ALL acceptance criteria met
   - Run full test suite
   - Check edge cases

7. **Completion**
   - Close beads issue
   - Record successful episode to memory
   - Provide summary

Start with Feature Definition phase.
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
