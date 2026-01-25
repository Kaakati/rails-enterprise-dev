---
name: "Rails Error Prevention"
description: "Expert checklist for preventing common Rails runtime errors BEFORE writing code. Use when: (1) Creating ViewComponents - template/method exposure errors, (2) Writing GROUP BY queries - PostgreSQL grouping errors, (3) Building views that call component methods, (4) Debugging 'undefined method' errors. Trigger keywords: errors, bugs, NoMethodError, template not found, N+1, GROUP BY, PG::GroupingError, undefined method, nil, debugging, prevention"
version: 1.1.0
---

# Rails Error Prevention

**Critical Rule**: Review the relevant section BEFORE writing code, not after errors occur.

## The #1 Cause of Runtime Errors

```
WRONG: Service has method → View can call it through component
RIGHT: Service has method + Component EXPOSES it = View can call it
```

Every layer must explicitly expose what the next layer needs. Views cannot reach through components to access service internals.

## Error Prevention Decision Tree

```
What are you building?
│
├─ ViewComponent
│   └─ Go to: ViewComponent Errors
│
├─ ActiveRecord query with GROUP BY
│   └─ Go to: GROUP BY Errors
│
├─ View that calls component methods
│   └─ Go to: Method Exposure Verification
│
├─ Controller action
│   └─ Go to: Controller Errors
│
└─ Code with potential nil values
    └─ Go to: Nil Errors
```

---

## ViewComponent Errors

### Template Not Found
```
Error: Couldn't find a template file or inline render method for {Component}
```

**Verification before creating:**
```bash
# Check existing pattern (inline vs file template)
head -50 $(find app/components -name '*_component.rb' | head -1)
grep -l 'def call' app/components/**/*_component.rb | head -3
```

**Requirements:**
```
app/components/namespace/name_component.rb      ← Class file
app/components/namespace/name_component.html.erb ← Template (unless inline)
```

**NEVER** create a component without checking the project's template pattern first.

### Helper Method Errors
```
Error: undefined local variable or method 'link_to' for #<MyComponent>
Hint: Did you mean `helpers.link_to`?
```

**Rule**: ALL Rails helpers need `helpers.` prefix in ViewComponents:
```ruby
# WRONG                    # RIGHT
link_to(...)              helpers.link_to(...)
image_tag(...)            helpers.image_tag(...)
number_to_currency(...)   helpers.number_to_currency(...)
time_ago_in_words(...)    helpers.time_ago_in_words(...)
content_tag(...)          helpers.content_tag(...)
```

**Or delegate explicitly:**
```ruby
class MyComponent < ViewComponent::Base
  delegate :link_to, :number_to_currency, to: :helpers
end
```

---

## Method Exposure Verification

**MANDATORY before writing view code:**

```bash
# 1. List all methods view will call
grep -oE '@[a-z_]+\.[a-z_]+' app/views/{path}/*.erb | sort -u

# 2. List all public methods in component
grep -E '^\s+def [a-z_]+' app/components/{component}_component.rb

# 3. Any view call without matching component method = BUG
```

**Fix missing methods:**
```ruby
# Option 1: Delegation (simple pass-through)
delegate :calculate_total, :success_rate, to: :@service

# Option 2: Wrapper (for transformation)
def formatted_total
  helpers.number_to_currency(@service.calculate_total)
end

# Option 3: Expose service (use sparingly)
attr_reader :service
# View calls: component.service.calculate_total
```

---

## GROUP BY Errors (PostgreSQL)

```
Error: PG::GroupingError: column "table.column" must appear in GROUP BY clause
```

**Rule**: Every non-aggregated SELECT column MUST be in GROUP BY.

### NEVER Combine These:
```ruby
# FATAL: includes/preload + group
Task.includes(:user).group(:status).count  # ERROR!

# FATAL: select with non-grouped columns
Task.select(:status, :id).group(:status)   # ERROR! (id not grouped)
```

### Correct Patterns:
```ruby
# Simple aggregation (no associations needed)
Task.group(:status).count
# => { "pending" => 10, "completed" => 25 }

# Multiple columns
Task.group(:status, :task_type).count
# => { ["pending", "express"] => 5, ... }

# If you need associated data, query separately
status_counts = Task.group(:status).count
tasks_by_status = status_counts.keys.each_with_object({}) do |status, hash|
  hash[status] = Task.where(status: status).includes(:user).limit(5)
end
```

**Pre-query checklist:**
```
[ ] Is this a GROUP BY query?
[ ] Are ALL SELECT columns either in GROUP BY or aggregates?
[ ] Have I removed includes/preload/eager_load?
[ ] Tested in rails console first?
```

---

## N+1 Queries

**Detection**: Multiple identical queries in logs.

```ruby
# WRONG - N+1
tasks.each { |t| puts t.user.name }  # Query per task!

# RIGHT
tasks.includes(:user).each { |t| puts t.user.name }  # 2 queries total
```

**Loading strategy:**
```ruby
includes(:user)      # Smart (preload or eager_load)
preload(:user)       # Separate queries (can't filter)
eager_load(:user)    # Single LEFT JOIN (can filter)
joins(:user)         # INNER JOIN only (no loading)
```

---

## Nil Errors

```
Error: undefined method 'foo' for nil:NilClass
```

**Prevention patterns:**
```ruby
# Safe navigation
user&.profile&.settings&.theme

# Guard clause
return unless user&.profile

# With default
user&.profile&.theme || 'default'

# Early return
def process(user)
  return if user.nil?
  # ...
end
```

---

## Controller Errors

### Missing Template
```
Error: ActionView::MissingTemplate
```

**Every non-redirect action needs:**
- A view file at `app/views/{controller}/{action}.html.erb`, OR
- Explicit render: `render json:`, `render partial:`, `head :ok`

### Unknown Action
```
Error: AbstractController::ActionNotFound
```

**Causes:**
- Route points to non-existent action
- Action is `private` or `protected` (must be `public`)

---

## Ambiguous Column (Joins)

```
Error: PG::AmbiguousColumn: column reference "status" is ambiguous
```

**Always qualify columns when joining:**
```ruby
# WRONG
User.joins(:tasks).where(status: 'active')

# RIGHT
User.joins(:tasks).where(users: { status: 'active' })
# OR
User.joins(:tasks).where('users.status = ?', 'active')
```

---

## Quick Prevention Checklists

### Before Creating ViewComponent
```
[ ] Checked existing template pattern (inline vs file)
[ ] Both .rb and .html.erb created (unless inline)
[ ] ALL methods view needs are PUBLIC in component
[ ] ALL Rails helpers use `helpers.` prefix
```

### Before Writing View Code
```
[ ] Listed ALL methods view will call on component
[ ] EACH method exists in component class (verified)
[ ] Missing methods added to component FIRST
```

### Before GROUP BY Query
```
[ ] ALL SELECT columns are grouped or aggregated
[ ] NO includes/preload/eager_load used
[ ] Tested in rails console
```

### Before Any Code
```
[ ] Inspected existing similar code for patterns
[ ] All dependencies exist (methods, files, routes)
[ ] Method exposure verified across all layers
```
