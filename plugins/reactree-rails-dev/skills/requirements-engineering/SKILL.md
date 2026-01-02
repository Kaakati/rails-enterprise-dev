---
name: "Requirements Engineering"
description: "Translating user prompts into structured requirements, user stories, and beads tasks for systematic implementation. Trigger keywords: requirements, user story, acceptance criteria, as a, i want, so that, given when then, task breakdown, epic creation"
version: 1.0.0
---

# Requirements Engineering

This skill provides patterns for translating natural language user prompts into structured requirements, user stories, acceptance criteria, and automatically generated beads tasks.

## 1. User Story Format Detection

### Standard Format

```
As a [actor/role]
I want [feature/capability]
So that [business benefit/value]
```

### Extraction Logic

**Pattern Matching**:
```bash
# Detect "As a/an" → Actor
ACTOR=$(echo "$prompt" | grep -ioE "as an? [a-z ]+" | sed 's/as an? //')

# Detect "I want" → Feature
FEATURE=$(echo "$prompt" | grep -ioE "i want [^.]*" | sed 's/i want //')

# Detect "So that" → Benefit
BENEFIT=$(echo "$prompt" | grep -ioE "so that [^.]*" | sed 's/so that //')
```

**Structured Output**:
```markdown
## User Story

**As a** developer
**I want** JWT authentication with refresh tokens
**So that** users can securely log in and stay authenticated

## Acceptance Criteria

- [ ] User can log in with email and password
- [ ] JWT access token is generated on successful login
- [ ] Refresh token is provided for token renewal
- [ ] Access token expires after 15 minutes
- [ ] Refresh token expires after 7 days
```

---

## 2. Given/When/Then Format

### BDD Acceptance Criteria

```
Given [initial context/precondition]
When [action/event occurs]
Then [expected outcome/result]
```

### Extraction

```bash
# Extract Given/When/Then if present
if echo "$prompt" | grep -qiE "given|when|then"; then
  echo "$prompt" | grep -ioE "(given|when|then) [^.]*" >> requirements.md
fi
```

**Example**:
```
Given a registered user
When they enter valid credentials
Then they receive a JWT access token and refresh token
And the access token expires in 15 minutes
```

---

## 3. Feature Request Parsing

### Keywords Detection

**Action Verbs** (indicate feature type):

| Verb | Feature Type | Example |
|------|--------------|---------|
| Implement/Build/Create | New Feature | "Implement user authentication" |
| Add/Include | Enhancement | "Add email notifications" |
| Fix/Debug | Bug Fix | "Fix login error" |
| Refactor/Cleanup | Refactoring | "Refactor payment service" |
| Optimize/Improve | Performance | "Optimize database queries" |

### Component Extraction

**Pattern**: "with X and Y"

```bash
# Extract "with X and Y" patterns
COMPONENTS=$(echo "$prompt" | grep -ioE "with [a-z, and]+" | sed 's/with //' | tr ',' '\n')
```

**Example**:
```
Input: "Add JWT authentication with refresh tokens and email verification"

Components:
- refresh tokens
- email verification
```

### Technology Constraints

**Pattern**: "using Z"

```bash
# Extract technology constraints
TECH=$(echo "$prompt" | grep -ioE "using [a-z ]+" | sed 's/using //')
```

**Example**:
```
Input: "Build payment system using Stripe"

Technology: Stripe
```

### Target Audience

**Pattern**: "for A"

```bash
# Extract target audience
AUDIENCE=$(echo "$prompt" | grep -ioE "for [a-z ]+" | sed 's/for //')
```

---

## 4. Task Breakdown

### Automatic Subtask Creation

**Strategy**: Break feature into technical layers

```
1. Database Layer (migrations, schema changes)
2. Model Layer (ActiveRecord models, validations)
3. Service Layer (business logic, external APIs)
4. Controller Layer (HTTP endpoints, routing)
5. View/Component Layer (UI, Hotwire components)
6. Testing Layer (RSpec tests, coverage)
```

### Example Breakdown

**User Story**: "Add JWT authentication with refresh tokens"

**Epic**: AUTH-001 - JWT Authentication System

**Subtasks**:
```
AUTH-002: Add User authentication columns (DB)
├─ Migration: add_auth_columns_to_users
├─ Columns: password_digest, refresh_token, token_expires_at
└─ Dependencies: None

AUTH-003: Implement JWT token generation (Model)
├─ User model: generate_jwt_token, generate_refresh_token
├─ Token expiration logic
└─ Dependencies: AUTH-002

AUTH-004: Create AuthService for login/refresh (Service)
├─ AuthService.login(email, password)
├─ AuthService.refresh_token(refresh_token)
├─ AuthService.verify_token(jwt)
└─ Dependencies: AUTH-003

AUTH-005: Add authentication endpoints (Controller)
├─ POST /auth/login
├─ POST /auth/refresh
├─ POST /auth/logout
└─ Dependencies: AUTH-004

AUTH-006: Add RSpec tests (Testing)
├─ Model tests for token generation
├─ Service tests for auth flow
├─ Controller tests for endpoints
└─ Dependencies: AUTH-005
```

### Dependency Detection

Identify dependencies automatically:

```
Database → Models (models depend on schema)
Models → Services (services use models)
Services → Controllers (controllers call services)
Controllers → Views (views render from controllers)
All layers → Tests (tests validate each layer)
```

---

## 5. Beads Task Creation

### create-beads-tasks.sh Integration

**Workflow**:

1. Extract requirements from `.claude/extracted-requirements.md`
2. Create epic with full description
3. Parse acceptance criteria
4. Generate subtasks with dependencies
5. Store epic ID for workflow

**Implementation**:

```bash
#!/bin/bash
# create-beads-tasks.sh

# Parse requirements file
REQUIREMENTS_FILE=".claude/extracted-requirements.md"

# Create epic
EPIC_ID=$(bd create \
  --type epic \
  --title "$FEATURE_TITLE" \
  --description "$(cat $REQUIREMENTS_FILE)")

# Parse acceptance criteria (lines starting with - or numbers)
grep -E "^-|^[0-9]+\." "$REQUIREMENTS_FILE" | while read -r criterion; do
  # Clean criterion (remove leading markers)
  criterion=$(echo "$criterion" | sed 's/^[- 0-9.]*//')

  if [ -n "$criterion" ]; then
    # Create subtask
    TASK_ID=$(bd create \
      --type task \
      --title "$criterion" \
      --priority 2 \
      --deps "$EPIC_ID")

    echo "Created task: $TASK_ID - $criterion"
  fi
done

# Store epic ID
echo "$EPIC_ID" > .claude/current-epic.txt
```

---

## 6. Intent Classification

### Multi-level Filtering

**Level 1**: Action Verb Detection

```bash
# Feature indicators
if echo "$prompt" | grep -qiE "add|implement|build|create"; then
  intent="feature"
  confidence="high"
fi

# Debug indicators
if echo "$prompt" | grep -qiE "fix|debug|troubleshoot|error"; then
  intent="debug"
  confidence="high"
fi

# Refactor indicators
if echo "$prompt" | grep -qiE "refactor|cleanup|optimize|restructure"; then
  intent="refactor"
  confidence="medium"
fi
```

**Level 2**: Context Analysis

```bash
# Check for domain context (Rails-specific)
if echo "$prompt" | grep -qiE "model|controller|migration|activerecord"; then
  context="rails"
fi

# Check for technical details
if echo "$prompt" | grep -qiE "jwt|oauth|api|rest"; then
  technical_context="authentication"
fi
```

**Level 3**: Complexity Scoring

```bash
# Word count
word_count=$(echo "$prompt" | wc -w)

if [ $word_count -gt 20 ]; then
  complexity="high"  # Complex feature request
elif [ $word_count -gt 10 ]; then
  complexity="medium"  # Standard feature
else
  complexity="low"  # Simple task
fi
```

---

## 7. Requirements Extraction Examples

### Example 1: User Story Format

**Input**:
```
"As a developer I want JWT authentication so that users can securely log in"
```

**Extracted Requirements**:
```markdown
## User Story

**As a** developer
**I want** JWT authentication
**So that** users can securely log in

## Components Detected

- JWT authentication
- User login

## Technical Layer Breakdown

1. Database: User authentication schema
2. Model: JWT token generation
3. Service: Authentication service
4. Controller: Login/logout endpoints
5. Testing: Auth flow tests
```

---

### Example 2: Feature with Components

**Input**:
```
"Add payment processing with Stripe integration and invoice generation"
```

**Extracted Requirements**:
```markdown
## Feature Request

**Description**: Add payment processing with Stripe integration and invoice generation

## Components Mentioned

- Stripe integration
- invoice generation

## Technology Stack

- Stripe (payment processor)

## Suggested Task Breakdown

1. Stripe API integration setup
2. Payment model and service
3. Invoice generation logic
4. Payment controller endpoints
5. Invoice PDF generation
6. RSpec tests for payment flow
```

---

### Example 3: BDD Format

**Input**:
```
"Given a user with a cart, when they checkout, then payment is processed and order is created"
```

**Extracted Requirements**:
```markdown
## Acceptance Criteria

**Given** a user with a cart
**When** they checkout
**Then** payment is processed and order is created

## Implied Tasks

1. Cart model and persistence
2. Checkout service
3. Payment processing integration
4. Order creation workflow
5. Transaction handling (atomic)
```

---

## 8. Routing Logic

### Workflow Selection

Based on extracted requirements, route to appropriate workflow:

```bash
# Complex feature with multiple components
if [ "$complexity" = "high" ] && [ "$component_count" -gt 3 ]; then
  workflow="/reactree-dev"
  create_beads_epic=true
fi

# Standard feature
if [ "$intent" = "feature" ] && [ "$complexity" = "medium" ]; then
  workflow="/reactree-feature"
  create_beads_tasks=true
fi

# Debugging
if [ "$intent" = "debug" ]; then
  workflow="/reactree-debug"
  create_beads_tasks=false
fi

# Refactoring
if [ "$intent" = "refactor" ]; then
  workflow="/reactree-dev --refactor"
  create_beads_tasks=true
fi
```

---

## 9. Output Format

### Structured Requirements File

**Location**: `.claude/extracted-requirements.md`

**Format**:
```markdown
---
intent: feature
confidence: high
complexity: medium
components: 3
created_at: 2026-01-02T10:30:00Z
---

## User Story

**As a** [actor]
**I want** [feature]
**So that** [benefit]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Components

- Component 1
- Component 2
- Component 3

## Suggested Technology

- Technology A
- Technology B

## Task Breakdown

1. Task 1 (Database)
2. Task 2 (Models)
3. Task 3 (Services)
4. Task 4 (Controllers)
5. Task 5 (Testing)

## Beads Epic

Created: EPIC-ID
Tasks: TASK-001, TASK-002, TASK-003
```

---

## 10. Best Practices

### User Story Writing

**Good**:
```
As a customer
I want to save my payment method
So that I can checkout faster on future purchases
```

**Bad**:
```
Add payment saving
```

### Acceptance Criteria

**Good** (Specific, Testable):
```
- User can add credit card
- Card is validated before saving
- Card number is masked in UI (only last 4 digits shown)
- Saved cards appear in checkout dropdown
```

**Bad** (Vague):
```
- Payment should work
- Cards are saved
```

### Component Extraction

**Good** (Granular):
```
- JWT token generation
- Refresh token rotation
- Token blacklisting
- Email verification
```

**Bad** (Too broad):
```
- Authentication
```

---

## 11. Integration with Smart Detection

### detect-intent.sh Enhancement

Add requirements extraction call:

```bash
# In detect-intent.sh (after intent scoring)

# Extract requirements
if extract_requirements "$USER_PROMPT"; then
  # Create beads tasks if enabled
  AUTO_CREATE=$(grep '^auto_create_beads_tasks:' .claude/reactree-rails-dev.local.md | sed 's/.*: *//')

  if [ "$AUTO_CREATE" = "true" ]; then
    bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/create-beads-tasks.sh "$USER_PROMPT"
  fi
fi
```

---

## Summary

Requirements Engineering enables:

1. **Automatic Translation**: User prompts → Structured requirements
2. **User Story Extraction**: As a... I want... So that...
3. **Acceptance Criteria**: Given/When/Then BDD format
4. **Component Detection**: Identify technical components
5. **Task Breakdown**: Automatic subtask generation
6. **Beads Integration**: Epic and task creation
7. **Intent Classification**: Route to appropriate workflow
8. **Complexity Analysis**: Determine feature scope

**Result**: Systematic translation of natural language requirements into actionable, tracked tasks with clear acceptance criteria.
