---
name: "Rails Conventions & Patterns"
description: "Comprehensive Ruby on Rails conventions, design patterns, and idiomatic code standards. Use this skill when writing any Rails code including controllers, models, services, or when making architectural decisions about code organization, naming conventions, and Rails best practices."
---

# Rails Conventions & Patterns Skill

This skill provides authoritative guidance on Ruby on Rails conventions, design patterns, and idiomatic code standards for production applications.

## When to Use This Skill

- Writing new Rails controllers, models, or services
- Refactoring existing Rails code
- Making decisions about code organization
- Choosing between different Rails patterns
- Ensuring code follows Rails conventions
- Reviewing Rails code for convention compliance

## Ruby & Rails Versions

```yaml
ruby: "3.2+ (prefer 3.3+ for YJIT benefits)"
rails: "7.1+ (prefer 8.0+ for new projects)"
```

## File Organization Standards

### Models
```yaml
location: "app/models/"
max_lines: 200
guidance: |
  Focus on associations, validations, scopes, and essential callbacks.
  Extract business logic to Service Objects.
  Keep models focused on data persistence and domain rules.
```

### Controllers
```yaml
location: "app/controllers/"
max_lines: 100
guidance: |
  Limit to REST actions. Use before_action for shared logic.
  Complex operations delegate to Service Objects.
  Follow "Skinny Controller, Fat Model (but not too fat)" pattern.
```

### Services
```yaml
location: "app/services/"
naming: "{Domain}Manager::{Action} (e.g., OrdersManager::CreateOrder)"
structure: |
  class OrdersManager::CreateOrder
    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      # Single public entry point
      # Returns Result object or raises
    end

    private

    # Small, focused private methods
  end
```

### Methods
```yaml
max_lines: 15
max_params: 4
guidance: "If method needs more params, use a Parameter Object or Hash"
```

## Naming Conventions

```yaml
classes: "PascalCase"
methods: "snake_case"
predicates: "end with ? (e.g., active?, valid?)"
dangerous_methods: "end with ! (e.g., save!, destroy!)"
constants: "SCREAMING_SNAKE_CASE"
private_methods: "Prefix with purpose, not underscore"
```

## Ruby Idioms

### Prefer
- Guard clauses over nested conditionals
- Explicit returns for clarity
- `&.` (safe navigation) over `try`
- Keyword arguments for 2+ parameters
- `Struct`/`Data` for simple value objects
- `frozen_string_literal: true` pragma

### Avoid
- `unless` with `else`
- Nested ternaries
- `and`/`or` for control flow
- Monkey patching in application code

## Pattern Decision Tree

**Always inspect existing codebase patterns before recommending any pattern.**

### Service Object
```ruby
# Use when:
# - Business logic spans multiple models
# - Operation has multiple steps
# - Logic doesn't belong to any single model
# - Need to orchestrate external services

# Avoid when:
# - Simple CRUD operation
# - Logic clearly belongs to one model
# - Single-line delegation

# Inspect first:
# ls app/services/
# Check existing service naming convention
```

### Form Object
```ruby
# Use when:
# - Form spans multiple models
# - Complex validations not tied to persistence
# - Wizard/multi-step forms

# Avoid when:
# - Standard single-model form
# - Simple attribute updates

# Inspect first:
# ls app/forms/ 2>/dev/null
# grep -r 'include ActiveModel' app/ --include='*.rb'
```

### Query Object
```ruby
# Use when:
# - Complex queries with multiple conditions
# - Query logic reused across controllers
# - Query needs composition/chaining

# Avoid when:
# - Simple scope suffices
# - One-off query

# Inspect first:
# ls app/queries/ 2>/dev/null
# grep -r 'class.*Query' app/ --include='*.rb'
```

### Concern
```ruby
# Use when:
# - Truly shared behavior across 3+ unrelated models
# - Behavior is cohesive and self-contained

# Avoid when:
# - Only 1-2 models share the code
# - Behavior is not cohesive
# - Just to 'clean up' a model

# Inspect first:
# ls app/models/concerns/ app/controllers/concerns/
# Check how many models use each concern
```

### Decorator/Presenter
```ruby
# Use when:
# - View logic becoming complex
# - Same presentation logic in multiple views
# - Need to augment model for display

# Avoid when:
# - Simple attribute display
# - One-off formatting

# Inspect first:
# ls app/decorators/ app/presenters/ 2>/dev/null
# grep 'draper' Gemfile
```

## Method Visibility Rules

### Public
```ruby
# Callable from anywhere, defines the API
# Controller actions must be public
# Methods called from views must be public
# Service interface methods

# Rails context:
# - Controller: only public methods are routable
# - Model: public methods accessible from controllers/views
# - Component: only public methods callable from templates
```

### Private
```ruby
# Can only be called within the class, without explicit receiver
# Implementation details
# Helper methods not part of public API
# Methods that should never be called externally

# Rails context:
# - Controller: helper methods, before_action callbacks
# - Service: internal computation methods
# - Model: internal validation helpers

# CRITICAL: Private methods CANNOT be called from outside the class.
# If a view needs data, the component MUST have a public method.
```

### Protected
```ruby
# Callable from same class or subclasses
# Methods meant for inheritance
# Rare in typical Rails apps

# Rails context:
# - Occasionally in base controllers/models for shared behavior
```

## Delegation Patterns

### Using delegate
```ruby
# Creates public forwarding methods
# LIMITATION: Cannot delegate to private methods on target

delegate :method1, :method2, to: :target

class Component < ViewComponent::Base
  delegate :total, :count, to: :@service
  
  def initialize(service:)
    @service = service
  end
end
# Now view can call component.total
```

### Wrapper Methods
```ruby
# Use when:
# - Need to transform data
# - Need to add caching
# - Need different method names
# - Need to handle errors

class Component < ViewComponent::Base
  def total
    @service.calculate_total
  rescue ServiceError
    0
  end
end
```

### attr_reader Exposure
```ruby
# Expose the underlying object directly
# Use sparingly - breaks encapsulation

class Component < ViewComponent::Base
  attr_reader :service
  
  def initialize(service:)
    @service = service
  end
end
# View calls: component.service.calculate_total
```

## Rails Request Cycle

```
Request → Route → Controller#action
       → Controller → Service/Model (business logic)
       → Controller → sets @instance_variables
       → Controller → renders View
       → View → calls methods on @variables
       → View → renders Components
       → Component → accesses only its own methods
```

**Key Insight**: Each layer can only access what the previous layer explicitly provides. Views can't magically access service internals.

## Implementation Order

Always implement in dependency order (bottom-up):

```
1. Database migrations (if needed)
2. Models (foundation)
3. Services (business logic)
4. Components (presentation wrappers)
5. Controllers (orchestration)
6. Views (final layer)
7. Tests (verify everything works)
```

**Rationale**: Each layer depends on the ones below it. Implementing bottom-up ensures dependencies exist before they're used.

## Code Quality Standards

### Method Size
- Maximum 15 lines per method
- Single responsibility per method
- Extract complex logic to private helper methods

### Class Size
- Models: max 200 lines
- Controllers: max 100 lines
- Services: max 150 lines

### Parameter Count
- Maximum 4 parameters
- Use keyword arguments for 2+ parameters
- Use Parameter Objects for complex cases

## Quick Reference

### Before Writing Any Code
```bash
# Check existing patterns
ls app/services/
ls app/models/
grep -r 'class.*Service' app/ --include='*.rb' -l | head -10

# Check naming conventions
head -30 $(find app/services -name '*.rb' | head -1)

# Check dependencies
cat Gemfile | grep -v '^#' | grep -v '^$'
```

### Common File Locations
```
app/models/           - ActiveRecord models
app/controllers/      - Controllers
app/services/         - Service objects
app/components/       - ViewComponents
app/queries/          - Query objects
app/forms/            - Form objects
app/presenters/       - Presenters/Decorators
app/serializers/      - API serializers
app/jobs/             - Background jobs
```
