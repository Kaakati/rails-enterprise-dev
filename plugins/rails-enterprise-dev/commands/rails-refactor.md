---
name: rails-refactor
description: Safe refactoring workflow with test preservation
allowed-tools: ["*"]
---

# Rails Refactoring Workflow

Safe, incremental refactoring with:
- Test-first verification
- Small, focused changes
- Continuous validation
- Beads tracking of improvements

## Usage

```
/rails-refactor [target code or improvement description]
```

## Examples

```
/rails-refactor Extract TaskManager services into smaller classes
/rails-refactor Move common controller logic to concern
/rails-refactor Optimize N+1 queries in bundles index
/rails-refactor Simplify complex conditional in Task model
```

## Process

1. **Ensure Tests Exist** - Verify current behavior tested
2. **Create Beads Issue** - Track refactoring work
3. **Plan Incremental Changes** - Break into small steps
4. **Make Change** - Single focused refactoring
5. **Run Tests** - Ensure no regression
6. **Commit** - Small, atomic commit
7. **Repeat** - Until refactoring complete

## Activation

```
{{REFACTORING_TARGET}}

Please activate the Rails Refactoring workflow:
1. Verify tests exist for target code (add if missing)
2. Create beads issue for refactoring
3. Use activerecord-patterns, service-object-patterns skills for guidance
4. Plan incremental refactoring steps
5. Execute one step at a time with test validation
6. Use git commits for each safe checkpoint
7. Document improvements

Start by verifying test coverage.
```

## Principles

- **Tests First** - Never refactor without tests
- **Small Steps** - One change at a time
- **Always Green** - Tests must pass after each step
- **Preserve Behavior** - No functional changes
- **Document** - Explain improvements in beads comments

## Skill Usage

**If available**:
- `rails-error-prevention` - Avoid introducing new issues
- `activerecord-patterns` - Database refactoring patterns
- `service-object-patterns` - Service layer improvements
- `rspec-testing-patterns` - Test coverage strategies

---

This workflow emphasizes safety and incremental progress over speed.
