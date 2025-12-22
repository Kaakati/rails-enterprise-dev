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
- **Refactoring log** for tracking renames/moves
- **Completeness validation** to catch orphaned references

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
3. **Initialize Refactoring Log** - Record planned changes (for renames/moves)
4. **Auto-detect Affected Files** - Find all references to old names
5. **Plan Incremental Changes** - Break into small steps
6. **Make Change** - Single focused refactoring
7. **Update Refactoring Progress** - Track files as completed
8. **Validate References** - Check for orphaned references
9. **Run Tests** - Ensure no regression
10. **Commit** - Small, atomic commit
11. **Repeat** - Until refactoring complete
12. **Final Validation** - Comprehensive completeness check
13. **Close Issue** - Mark refactoring complete

## Activation

```
{{REFACTORING_TARGET}}

Please activate the Rails Refactoring workflow with refactoring tracking:

### Step 1: Verify Tests
- Check test coverage for target code
- Add missing tests if needed
- Ensure all tests pass before starting

### Step 2: Create Beads Issue
- Create beads issue for refactoring work
- Type: `task` or `chore` depending on scope

### Step 3: Detect Refactoring Type
Determine if this refactoring involves:
- **Class rename**: `OldClass` → `NewClass`
- **Attribute rename**: `old_attr` → `new_attr`
- **Method rename**: `old_method` → `new_method`
- **Namespace change**: `Old::Namespace` → `New::Namespace`
- **File move**: Path changes
- **Other**: Complexity reduction, pattern extraction (no tracking needed)

### Step 4: Initialize Refactoring Log (if rename/move)
If refactoring involves renaming or moving:

```bash
# Create refactoring log in beads
bd comment $ISSUE_ID "🔄 Refactoring Log: [OldName] → [NewName]

**Type**: [class_rename|attribute_rename|method_rename|namespace_change]
**Started**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Status**: ⏳ In Progress

### Changes Planned
1. [Specific change]

### Affected Files (Auto-detected)
$(rg --files-with-matches '\b[OldName]\b' --type ruby 2>/dev/null | head -20)

### Validation Checklist
- [ ] No references to old name in Ruby files
- [ ] No references in view templates
- [ ] No references in routes
- [ ] No references in specs
- [ ] No references in factories

### Validation Command
bash hooks/scripts/validate-refactoring.sh --old-name [OldName] --new-name [NewName]"
```

### Step 5: Incremental Refactoring
For each file/change:
1. Make focused change
2. Update refactoring log progress (if tracking)
3. Run affected tests
4. Validate no orphaned references (for renames)
5. Commit if tests pass

### Step 6: Final Validation (for renames/moves)
Before closing:
```bash
bash hooks/scripts/validate-refactoring.sh --old-name [OldName] --new-name [NewName]
```

Must show 0 references to old name.

### Step 7: Complete
- Mark all tests passing
- Confirm refactoring log shows complete (if applicable)
- Close beads issue

### Skills to Use
- `rails-error-prevention` - Avoid introducing issues
- `activerecord-patterns` - Database refactoring
- `service-object-patterns` - Service improvements
- `rspec-testing-patterns` - Test coverage

Start by verifying test coverage and creating the beads issue.
```

## Principles

- **Tests First** - Never refactor without tests
- **Small Steps** - One change at a time
- **Always Green** - Tests must pass after each step
- **Preserve Behavior** - No functional changes
- **Document** - Explain improvements in beads comments
- **Validate Completeness** - For renames, ensure all references updated

## Refactoring Tracking & Validation

### When to Use Refactoring Tracking

Use refactoring tracking for:
- **Class renames**: `Payment` → `Transaction`
- **Attribute renames**: `user_id` → `account_id`
- **Method renames**: `process` → `execute`
- **Namespace changes**: `Services::Payment` → `Billing::Transaction`
- **Table renames**: `payments` → `transactions`
- **File moves**: Moving files between directories/namespaces

**Do NOT use for**:
- Complexity reduction (no name changes)
- Pattern extraction (new code, no renames)
- Performance optimization (no renames)
- Bug fixes (no renames)

### Refactoring Log Format

Track renames in beads comments with this format:

```markdown
🔄 Refactoring Log: OldName → NewName

**Type**: class_rename
**Started**: 2025-01-21 14:30:00 UTC
**Status**: ⏳ In Progress

### Changes Planned
1. Rename class `Payment` to `Transaction`
2. Update file path
3. Update all references

### Affected Files (Auto-detected)
- app/models/transaction.rb (was payment.rb)
- app/models/account.rb (association)
- app/controllers/payments_controller.rb
- app/views/payments/**/*
- spec/models/payment_spec.rb
- spec/factories/payments.rb
- config/routes.rb

### Validation Checklist
- [ ] No references to `Payment` in Ruby files
- [ ] No references in view templates
- [ ] No @payment variables
- [ ] No payment_path helpers
- [ ] No :payment factories

### Validation Command
bash hooks/scripts/validate-refactoring.sh --old-name Payment --new-name Transaction
```

### Validation Process

**During refactoring** (incremental):
```bash
# After updating each file, check remaining references
rg "\bPayment\b" --type ruby | wc -l
# Should decrease with each file updated
```

**Before closing** (comprehensive):
```bash
# Run full validation
bash hooks/scripts/validate-refactoring.sh \
  --old-name Payment \
  --new-name Transaction \
  --issue-id BD-123

# Exit code 0 = all references updated
# Exit code 1 = remaining references found (blocks closure)
```

### Handling Intentional Legacy References

Create `.refactorignore` for intentional old name references:

```gitignore
# Legacy API compatibility (can't change external contracts)
app/serializers/api/v1/*_serializer.rb

# Historical documentation
CHANGELOG.md
docs/migration_guides/*.md

# Rename migrations (reference old names by design)
db/migrate/*_rename_*.rb
```

### Validation Output Examples

**Success**:
```
✅ Refactoring validation PASSED
No remaining references to 'Payment' found.
```

**Failure**:
```
❌ Refactoring validation FAILED

Found 3 remaining references to 'Payment':

Ruby files (2 references):
app/models/invoice.rb:15:    belongs_to :payment
spec/models/invoice_spec.rb:8:  let(:payment) { create(:payment) }

Factories (1 reference):
spec/factories/invoices.rb:4:    payment { create(:payment) }
```

## Skill Usage

**If available**:
- `rails-error-prevention` - Avoid introducing new issues
- `activerecord-patterns` - Database refactoring patterns
- `service-object-patterns` - Service layer improvements
- `rspec-testing-patterns` - Test coverage strategies

---

This workflow emphasizes safety and incremental progress over speed.
