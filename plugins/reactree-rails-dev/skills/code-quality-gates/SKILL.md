---
name: "Code Quality Gates"
description: "Expert decision trees for Solargraph, Sorbet, and Rubocop validation in Rails. Use when: (1) Choosing which quality tool for a task, (2) Debugging type errors or lint failures, (3) Setting up validation pipelines, (4) Deciding strictness levels. Trigger keywords: quality gates, validation, solargraph, sorbet, rubocop, type checking, linting, code quality, static analysis, type safety, srb tc"
version: 1.1.0
---

# Code Quality Gates

Expert patterns for coordinating Solargraph, Sorbet, and Rubocop in Rails codebases.

## Tool Selection Decision Tree

```
What do you need?
│
├─ "Find undefined methods/constants" → Solargraph
│   └─ Run: solargraph check app/models/user.rb
│
├─ "Type safety and nil protection" → Sorbet
│   └─ Run: bundle exec srb tc app/services/
│
├─ "Style consistency and formatting" → Rubocop
│   └─ Run: rubocop -a app/controllers/
│
└─ "Full validation before commit" → All three in sequence
    └─ Order: Rubocop (fast) → Solargraph → Sorbet (slowest)
```

## When to Use Each Tool

| Scenario | Tool | Why |
|----------|------|-----|
| Pre-commit quick check | Rubocop `-a` | Fast, auto-fixes most issues |
| Refactoring safety net | Sorbet | Catches method signature changes |
| Debugging "undefined method" | Solargraph | Shows what methods exist on type |
| CI pipeline blocking | All three | Different error classes |
| New file creation | Sorbet `# typed: true` | Type-safe from start |

## Sorbet Strictness Levels (Critical Decision)

```ruby
# typed: ignore   # Skip entirely - use for generated files only
# typed: false    # Syntax only - legacy code, migrate gradually
# typed: true     # Type inference - NEW FILES START HERE
# typed: strict   # Explicit sigs required - core business logic
# typed: strong   # No T.untyped - API boundaries, critical paths
```

**Decision matrix:**
```
Is this file...
├─ Generated code (schema.rb)? → ignore
├─ Legacy with many issues? → false (upgrade later)
├─ New production code? → true (minimum standard)
├─ Core business logic? → strict
└─ Public API boundary? → strong
```

## NEVER Do This (Common Mistakes)

**NEVER** add `# typed: strict` to a file with dynamic metaprogramming:
```ruby
# typed: strict  # WRONG - will fail on dynamic methods
class Report
  [:daily, :weekly, :monthly].each do |period|
    define_method("#{period}_summary") { calculate(period) }
  end
end
```
→ Use `# typed: false` or add explicit Sorbet shims

**NEVER** silence Rubocop inline without a reason:
```ruby
# rubocop:disable all  # WRONG - hides real issues
def method
  # ...
end
```
→ Disable specific cops with justification: `# rubocop:disable Layout/LineLength # URL constant`

**NEVER** ignore Solargraph "undefined method" on ActiveRecord:
```ruby
user.email  # Solargraph warning: undefined method
```
→ This means your `.solargraph.yml` lacks Rails support. Add `require: ['rails']`

**NEVER** skip validation in CI to "save time":
→ Quality issues compound exponentially. Block merges on failures.

## Sorbet Signature Patterns (Expert)

```ruby
# Nilable return - forces caller to handle nil
sig { params(id: Integer).returns(T.nilable(User)) }
def find_user(id)
  User.find_by(id: id)
end

# Non-nil assertion - use when you KNOW it exists
sig { params(id: Integer).returns(User) }
def find_user!(id)
  T.must(User.find_by(id: id))  # Raises if nil
end

# Block parameters
sig { params(block: T.proc.params(item: String).returns(Integer)).returns(T::Array[Integer]) }
def map_items(&block)
  items.map(&block)
end

# Self-returning for chaining
sig { returns(T.self_type) }
def configure
  # ...
  self
end
```

## Error Resolution Quick Reference

| Error | Tool | Fix |
|-------|------|-----|
| "Method does not exist on NilClass" | Sorbet | Add nil check or `T.must()` |
| "Expected String, got T.untyped" | Sorbet | Add `sig` to source method |
| "Undefined method 'foo'" | Solargraph | Check method exists, check require |
| "Layout/LineLength: Line too long" | Rubocop | Break line or increase max |
| "Method signature is missing" | Sorbet strict | Add `sig { }` block |

## Validation Pipeline Order

**For modified files:**
```bash
# 1. Fast syntax check (catches obvious errors)
ruby -c "$FILE"

# 2. Style enforcement (auto-fixable)
rubocop -a "$FILE"

# 3. Diagnostics (undefined methods/constants)
solargraph check "$FILE" 2>/dev/null || true

# 4. Type safety (if typed file)
if grep -q "# typed:" "$FILE"; then
  bundle exec srb tc "$FILE"
fi
```

## Gradual Adoption Strategy

```
Week 1: Rubocop only (easiest)
  └─ Add .rubocop.yml, run on CI

Week 2-3: Add Solargraph
  └─ Add .solargraph.yml with Rails support
  └─ Fix "undefined constant" errors

Week 4+: Introduce Sorbet
  └─ Run: bundle exec srb init
  └─ Add tapioca: bundle exec tapioca init && tapioca gems
  └─ Start new files with # typed: true
  └─ Upgrade old files one at a time
```

## Configuration Quick Start

**.rubocop.yml** (minimal):
```yaml
AllCops:
  TargetRubyVersion: 3.2
  NewCops: enable
  Exclude: ['db/schema.rb', 'vendor/**/*']

Layout/LineLength:
  Max: 120
```

**.solargraph.yml** (with Rails):
```yaml
include: ["**/*.rb"]
exclude: ["spec/**/*", "vendor/**/*"]
require: ["rails"]
reporters: ["rubocop"]
```

**sorbet/config** (project root):
```
--dir
.
--ignore=/vendor/
--ignore=/tmp/
```

## Pre-Implementation Checklist

Before writing code, verify:
```
[ ] Do I know which tools are installed? (bundle exec srb --version)
[ ] Is the file typed? If so, what level?
[ ] Are there existing type signatures I need to match?
[ ] Will Rubocop auto-fix formatting on save? (check IDE settings)
```
