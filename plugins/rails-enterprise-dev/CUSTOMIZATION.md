# Customizing Rails Enterprise Development Plugin

This guide explains how to customize the plugin for your specific Rails project.

## Table of Contents

- [Adding Project Skills](#adding-project-skills)
- [Configuring Settings](#configuring-settings)
- [Skill Naming Conventions](#skill-naming-conventions)
- [Creating Domain Skills](#creating-domain-skills)
- [Multi-Project Setup](#multi-project-setup)

## Adding Project Skills

The plugin automatically discovers and uses skills from `.claude/skills/`. Add custom skills to encode your team's patterns.

### Quick Start

1. **Create skill directory**:
```bash
mkdir -p .claude/skills/my-custom-patterns
```

2. **Create SKILL.md**:
```markdown
---
name: My Custom Patterns
description: Our team's coding standards and patterns
version: 1.0.0
---

# My Custom Patterns

## Overview

This skill documents our team's specific Rails patterns.

## Service Layer

### Pattern: Service Objects

We use the **dry-transaction** gem for all service objects:

```ruby
class MyService
  include Dry::Transaction

  step :validate
  step :persist
  step :notify

  private

  def validate(input)
    # Validation logic
  end

  def persist(input)
    # Persistence logic
  end

  def notify(result)
    # Notification logic
  end
end
```

### Usage

```ruby
result = MyService.new.call(params)

if result.success?
  # Handle success
else
  # Handle failure
end
```

## Testing

### Pattern: RSpec Structure

We organize specs by:
- `spec/models/` - Model unit tests
- `spec/services/` - Service unit tests
- `spec/requests/` - API integration tests
- `spec/features/` - User-facing features (Capybara)

...
```

3. **Plugin auto-discovers**:
- Restart Claude Code
- Run `/rails-dev` - skill is automatically used!

## Configuring Settings

Create `.claude/rails-enterprise-dev.local.md`:

```markdown
---
# Enable/disable plugin
enabled: true

# Workflow state (managed by plugin)
feature_id: null
workflow_phase: idle

# Quality control
quality_gates_enabled: true
test_coverage_threshold: 90

# Automation
auto_commit: false
auto_create_pr: false

# Custom settings
notification_webhook: https://hooks.slack.com/...
team_review_required: true
---

# Rails Enterprise Development

Project: My Rails App
Team: Engineering Team
```

**Add to `.gitignore`**:
```gitignore
.claude/*.local.md
```

### Available Settings

**enabled** (boolean, default: true)
- Enable/disable plugin
- Set to `false` to stop auto-detection

**quality_gates_enabled** (boolean, default: true)
- Validate each implementation phase
- Set to `false` for faster iteration (not recommended)

**test_coverage_threshold** (integer, default: 90)
- Minimum test coverage percentage
- Used in test phase validation

**auto_commit** (boolean, default: false)
- Automatically commit after each successful phase
- Set to `true` for hands-free workflow (experimental)

**auto_create_pr** (boolean, default: false)
- Automatically create PR when feature complete
- Requires GitHub CLI (`gh`)

## Skill Naming Conventions

The plugin categorizes skills based on naming patterns:

### Core Rails Skills

Pattern: `*convention*`, `*error-prevention*`, `*codebase*`

Example:
- `rails-conventions`
- `rails-error-prevention`
- `codebase-inspection`

### Data Layer Skills

Pattern: `*activerecord*`, `*model*`, `*database*`, `*schema*`

Example:
- `activerecord-patterns`
- `custom-model-patterns`
- `database-optimization`

### Service Layer Skills

Pattern: `*service*`, `*api*`

Example:
- `service-object-patterns`
- `api-development-patterns`
- `custom-api-conventions`

### UI Skills

Pattern: `*component*`, `*view*`, `*ui*`, `*hotwire*`, `*turbo*`, `*stimulus*`, `*frontend*`

Example:
- `viewcomponents-specialist`
- `hotwire-patterns`
- `tailadmin-patterns`
- `custom-ui-library`

### Domain Skills

Pattern: Anything not matching above patterns

Example:
- `ecommerce-domain`
- `healthcare-context`
- `fintech-compliance`
- `manifest-project-context`

**Domain skills** are automatically used during inspection and planning phases.

## Creating Domain Skills

Domain skills capture business logic and project-specific knowledge.

### Example: E-commerce Domain Skill

```markdown
---
name: E-commerce Domain
description: Business rules and domain knowledge for e-commerce platform
version: 1.0.0
---

# E-commerce Domain Knowledge

## Domain Models

### Order Model

**Business Rules**:
- Order must have at least one line item
- Total calculated from line items + tax + shipping
- Can only cancel if status is 'pending' or 'processing'
- Refunds require manager approval

**State Machine**:
```
pending → processing → shipped → delivered
              ↓
          cancelled
```

**Validation Rules**:
- Email required and must be valid
- Shipping address required
- Payment method validated before order creation

### Product Model

**Business Rules**:
- SKU must be unique
- Price cannot be negative
- Inventory decremented on order placement
- Low stock threshold: 10 units

## Integration Points

### Payment Gateway (Stripe)

- Use Stripe webhooks for payment confirmations
- Store Stripe customer ID in users table
- Handle failed payments with retry logic

### Shipping API

- Calculate shipping rates via ShipStation API
- Track shipments with tracking numbers
- Send shipping notifications to customers

## Business Workflows

### Checkout Flow

1. Validate cart (items in stock, prices current)
2. Create order (status: pending)
3. Process payment
4. If payment succeeds → order status: processing
5. Send order confirmation email
6. Trigger fulfillment job (Sidekiq)

### Refund Flow

1. Manager approves refund
2. Create refund record
3. Process refund via Stripe
4. Update order status
5. Restore inventory
6. Send refund confirmation email
```

### Using Domain Skills

When implementing e-commerce features, the plugin:
1. Discovers `ecommerce-domain` skill
2. Invokes during inspection for business context
3. Invokes during planning for validation rules
4. References during implementation for state machines

Example workflow:
```bash
/rails-dev implement order cancellation

# Plugin flow:
# 1. Discovers ecommerce-domain skill
# 2. Inspection: Understands Order state machine
# 3. Planning: Knows "can only cancel if pending/processing"
# 4. Implementation: Adds state validation before cancellation
# 5. Tests: Includes edge cases from skill
```

## Multi-Project Setup

Same plugin, different skills per project:

### Project A: SaaS Platform

```
.claude/skills/
├── rails-conventions/
├── activerecord-patterns/
├── service-object-patterns/
├── api-development-patterns/
├── tailadmin-patterns/
└── saas-domain/           ← Domain-specific
```

**saas-domain skill** includes:
- Multi-tenancy patterns
- Subscription management
- Billing logic
- Feature flags

### Project B: E-commerce Store

```
.claude/skills/
├── rails-conventions/
├── activerecord-patterns/
├── service-object-patterns/
├── bootstrap-patterns/     ← Different UI
└── ecommerce-domain/       ← Domain-specific
```

**ecommerce-domain skill** includes:
- Product catalog
- Shopping cart
- Checkout flow
- Payment processing

### Project C: Healthcare App

```
.claude/skills/
├── rails-conventions/
├── activerecord-patterns/
├── service-object-patterns/
├── react-patterns/         ← Different frontend
└── healthcare-domain/      ← Domain-specific
```

**healthcare-domain skill** includes:
- HIPAA compliance
- Patient records
- Appointment scheduling
- Medical terminology

**Same plugin adapts to each project automatically!**

## Advanced Customization

### Custom Workflow Phases

To add custom phases, create custom orchestrator in project:

```markdown
# .claude/agents/custom-orchestrator.md
---
name: custom-orchestrator
description: Extended workflow with security phase
---

# Custom Workflow Orchestrator

Extends rails-enterprise-dev workflow with:
- Security audit phase
- Performance testing phase
- Accessibility validation phase

...
```

### Custom Quality Gates

Add project-specific validation:

```bash
# .claude/hooks/custom-validation.sh
#!/bin/bash

# Run Brakeman security scan
if ! bundle exec brakeman -q; then
  echo "⚠️ Security vulnerabilities detected"
  exit 2
fi

# Run bundle-audit
if ! bundle exec bundle-audit check; then
  echo "⚠️ Gem vulnerabilities detected"
  exit 2
fi

exit 0
```

Add to hooks configuration.

### Team-Specific Templates

Create skill with code templates:

```markdown
# .claude/skills/team-templates/SKILL.md

## Controller Template

```ruby
class ResourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_resource, only: [:show, :edit, :update, :destroy]

  def index
    @resources = current_account.resources.page(params[:page])
  end

  # ... (team-standard controller structure)
end
```
...
```

## Tips

1. **Start Small**: Add one skill at a time
2. **Document Patterns**: Skills are living documentation
3. **Keep Updated**: Update skills as patterns evolve
4. **Share Knowledge**: Skills encode team knowledge
5. **Test Integration**: Verify plugin uses new skills correctly

## Support

- Main docs: `README.md`
- Example skills: `.claude/skills/` in your project
- Plugin code: `.claude/plugins/rails-enterprise-dev/`

---

**Happy customizing!** 🎨
