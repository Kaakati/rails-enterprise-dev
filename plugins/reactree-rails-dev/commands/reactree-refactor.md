---
name: reactree-refactor
description: |
  ReAcTree-based safe refactoring workflow with test preservation, reference tracking,
  and quality gates. Specializes in code transformation while maintaining all existing
  functionality and test coverage.
color: yellow
allowed-tools: ["*"]
---

# ReAcTree Safe Refactoring Workflow

You are initiating a **safe refactoring workflow** powered by ReAcTree architecture. This workflow ensures code transformations preserve functionality through comprehensive reference tracking, test verification, and automatic rollback on failures.

## Refactoring Philosophy

**Safe refactoring means:**
1. **Tests pass before AND after** - No refactoring without green tests
2. **All references tracked** - Know every usage before changing anything
3. **Incremental changes** - Small, verifiable steps over big bang rewrites
4. **Working memory persistence** - Track all changes for potential rollback
5. **Quality gates enforced** - No degradation in coverage or test count

## Usage

```
/reactree-refactor [target] [refactoring type]
```

## Examples

```
/reactree-refactor PaymentService extract method for charge logic
/reactree-refactor User model rename email_address to email
/reactree-refactor OrdersController move business logic to service
/reactree-refactor legacy_helper.rb inline and delete
```

## Refactoring Types Supported

### Extract Method/Class
- Identify repeated or complex code
- Extract with clear interface
- Update all call sites
- Add tests for new unit

### Rename (Method/Class/Variable)
- Find all references (LSP + Grep)
- Update all usages atomically
- Update related tests
- Verify no broken references

### Move (Method/Class/File)
- Track all imports/requires
- Update file locations
- Fix all references
- Update autoloading if needed

### Inline (Method/Variable)
- Replace all usages
- Remove original definition
- Simplify tests if applicable

### Replace Conditional with Polymorphism
- Identify switch/case patterns
- Design class hierarchy
- Extract behavior to subclasses
- Update factory/creation points

### Service Object Extraction
- Identify controller bloat
- Design service interface
- Move business logic
- Keep controller thin

## Workflow Phases

### Phase 1: Pre-Flight Check
Before any refactoring:
1. Run full test suite - MUST be green
2. Capture baseline metrics (coverage, test count, performance)
3. Identify refactoring scope and boundaries

### Phase 2: Reference Discovery
Use code-line-finder agent to:
1. Find all usages of target code
2. Map call chains and dependencies
3. Identify affected test files
4. Document in working memory

### Phase 3: Safe Transformation
With codebase-inspector insights:
1. Apply changes incrementally
2. Run related tests after each change
3. Maintain backward compatibility where needed
4. Use FEEDBACK edges if tests fail

### Phase 4: Verification
Test Oracle validates:
1. All tests still pass
2. Coverage not degraded
3. No new warnings/deprecations
4. Performance not regressed

### Phase 5: Completion
If all gates pass:
1. Update documentation if needed
2. Create beads issue for tracking (if complex)
3. Commit with detailed message

## Quality Gates

| Gate | Threshold | Action on Fail |
|------|-----------|----------------|
| Tests Pass | 100% | Block & rollback |
| Coverage | >= baseline | Warn & review |
| Performance | <= 110% baseline | Warn & review |
| Complexity | <= baseline | Warn & continue |

## FEEDBACK Edge Handling

If tests fail during refactoring:
1. Analyze failure with Test Oracle
2. Route fix request via feedback-coordinator
3. Apply minimal fix
4. Re-verify
5. Max 2 feedback rounds before escalation

## Activation

**Refactoring Target:**
```
{{REFACTORING_TARGET}}
```

---

**IMMEDIATE ACTION REQUIRED**: You must now invoke the workflow-orchestrator agent to execute safe refactoring for this target.

**Use the Task tool with these exact parameters:**

- **subagent_type**: `reactree-rails-dev:workflow-orchestrator`
- **description**: `Execute safe refactoring workflow with test preservation`
- **prompt**: (Use the prompt template below)

---

## Workflow-Orchestrator Agent Prompt Template

```
Refactoring Target: {{REFACTORING_TARGET}}

You are the **workflow-orchestrator** agent coordinating a **safe refactoring workflow** using the ReAcTree architecture.

## Your Mission

Execute safe refactoring with:
- **Green baseline REQUIRED**: All tests must pass before starting
- **Reference discovery**: Find all usages before making changes
- **Incremental changes**: Small steps, test after each
- **Test preservation**: Coverage must not decrease
- **Verification**: All tests pass after completion

## Your Responsibilities

As the master coordinator for safe refactoring, you must:

1. ✅ **Verify green baseline** before ANY changes (abort if tests failing)
2. ✅ **Map all references** to code being refactored
3. ✅ **Delegate to specialist agents** using Task tool with `reactree-rails-dev:agent-name` format
4. ✅ **Apply changes incrementally** (small steps, test after each)
5. ✅ **Validate no regressions** (tests pass, coverage maintained)
6. ✅ **Handle failures** via FEEDBACK edges (revert and retry if tests break)

---

## Phase 1: Pre-Flight Check

**Actions** (you handle directly):

**1. Run Full Test Suite**:
- Execute: `bundle exec rspec`
- **CRITICAL**: If ANY tests fail, ABORT refactoring
- Refactoring MUST start from green baseline

**2. Capture Baseline Metrics**:
- Total tests: {{COUNT}}
- Passing tests: {{COUNT}} (must be 100%)
- Coverage: {{PERCENTAGE}}%
- Warnings: {{COUNT}} (note any existing warnings)

**3. Create Beads Issue**:
- Use `mcp__plugin_beads_beads__create`
- Title: "Refactor: {{REFACTORING_TARGET_SUMMARY}}"
- Type: "task"
- Description: Refactoring goal and scope
- Store issue ID for tracking

**4. Cache Baseline to Working Memory**:
```json
{
  "type": "refactoring_baseline",
  "target": "{{REFACTORING_TARGET}}",
  "tests_passing": {{COUNT}},
  "coverage": {{PERCENTAGE}},
  "warnings": {{COUNT}},
  "beads_issue_id": "...",
  "timestamp": "..."
}
```

**Output**: Confirm baseline is green and metrics captured

**If tests failing**:
```
❌ Cannot start refactoring - tests are failing

Fix these failing tests first:
{{LIST_OF_FAILING_TESTS}}

Run `/reactree-debug` to fix the failures, then retry refactoring.
```

---

## Phase 2: Reference Discovery

**DELEGATE to code-line-finder agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:code-line-finder`
- `description`: `Find all references to refactoring target`
- `prompt`:

```
Find all references to: {{REFACTORING_TARGET}}

## Reference Discovery

**Use LSP tools to find**:
- **Definition**: Where is {{TARGET}} defined?
- **All References**: Every place {{TARGET}} is used
- **Implementations**: If interface/module, find all implementations
- **Callers**: What calls {{TARGET}}? (use LSP call hierarchy)

## Dependency Mapping

**For EACH reference**:
- File path and line number
- Context (what's calling it? why?)
- Type of usage (method call, inheritance, include, etc.)

## Impact Analysis

**Identify**:
- How many files will be affected?
- Are there tests for each usage?
- Are there external dependencies (gems, APIs)?
- What's the blast radius of changes?

## Output Requirements

**Provide**:
- Total references found: {{COUNT}}
- Files affected: {{COUNT}}
- Breakdown by file:
  ```
  app/models/user.rb:45 - Method call in #full_name
  app/services/user_service.rb:12 - Inheritance
  spec/models/user_spec.rb:89 - Test coverage
  ```

**Risk Assessment**:
- Low risk: <5 references, all tested
- Medium risk: 5-20 references, partial tests
- High risk: >20 references or missing tests

Cache findings to working memory.

**Skills to use**: codebase-inspection
```

**Wait for code-line-finder to complete.** Review reference map.

---

## Phase 3: Refactoring Plan

**DELEGATE to codebase-inspector** (for pattern analysis):

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:codebase-inspector`
- `description`: `Analyze patterns and plan refactoring approach`
- `prompt`:

```
Plan safe refactoring for: {{REFACTORING_TARGET}}

## Available Context

**Reference Map**: Complete list from code-line-finder
**Baseline**: Tests passing, coverage at {{PERCENTAGE}}%

## Refactoring Analysis

**Current State**:
- What is {{TARGET}} doing now?
- What patterns is it using?
- Why does it need refactoring? (code smell, duplication, complexity?)

**Target State**:
- What should it look like after refactoring?
- What pattern will we use? (Extract Method, Extract Class, Introduce Parameter Object, etc.)
- How will this improve the code? (readability, testability, maintainability?)

**Similar Patterns**:
- Are there existing patterns in the codebase we should follow?
- How have similar refactorings been done before?

## Incremental Steps

**Break refactoring into small, safe steps**:

Example for Extract Method:
1. Copy method body to new method (no changes to original yet)
2. Add tests for new method
3. Run tests (should pass)
4. Replace original method body with call to new method
5. Run tests (should still pass)
6. Remove duplication if any
7. Run tests (should still pass)

**For EACH step**:
- What changes?
- What tests run after this step?
- What's the rollback plan if tests fail?

## Output Requirements

**Provide structured plan**:

**Refactoring Type**: {{PATTERN_NAME}}
**Risk Level**: {{LOW/MEDIUM/HIGH}}

**Step-by-Step Plan**:
1. {{STEP_1_DESCRIPTION}}
   - Files to change: {{FILES}}
   - Tests to run: {{TESTS}}
   - Rollback: {{REVERT_APPROACH}}

2. {{STEP_2_DESCRIPTION}}
   ...

**Expected Outcome**:
- Code quality improvement: {{DESCRIPTION}}
- Test coverage: Should remain at {{PERCENTAGE}}% or higher
- No functional changes (behavior identical)

Cache plan to working memory.

**Skills to use**: codebase-inspection, rails-conventions
```

**Wait for codebase-inspector to complete plan.** Review before proceeding.

---

## Phase 4: Incremental Refactoring Execution

**DELEGATE to implementation-executor**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:implementation-executor`
- `description`: `Apply refactoring changes incrementally`
- `prompt`:

```
Execute refactoring plan for: {{REFACTORING_TARGET}}

## Available Context

**Baseline**: All tests passing, coverage at {{PERCENTAGE}}%
**Reference Map**: All usages known
**Refactoring Plan**: Step-by-step approach from codebase-inspector

## Execution Strategy (Test After Every Step)

**CRITICAL RULE**: Run tests after EACH step. If ANY test fails, STOP and use FEEDBACK edge.

**For EACH step in the plan**:

1. **Make Change**:
   - Apply the transformation for this step ONLY
   - Keep changes minimal
   - Follow Rails conventions

2. **Run Tests** (immediately):
   - Run affected tests: `bundle exec rspec {{FILE_PATH}}`
   - If specific file affected, run its specs
   - If multiple files, run all related specs

3. **Validate Step**:
   - ✅ All tests pass: Continue to next step
   - ❌ Any test fails: STOP, create FEEDBACK edge

**Example Execution**:

```
Step 1: Extract method `calculate_total` from `Order#process`
- Edit: app/models/order.rb
- Add new method
- Run: bundle exec rspec spec/models/order_spec.rb
- Status: ✅ All passing

Step 2: Update callers to use new method
- Edit: app/models/order.rb (replace inline code with method call)
- Run: bundle exec rspec spec/models/order_spec.rb
- Status: ✅ All passing

Step 3: Remove duplication
- Edit: app/models/order.rb
- Run: bundle exec rspec spec/models/order_spec.rb
- Status: ✅ All passing
```

## Quality Gates (After Each Step)

- ✅ Tests pass (100% pass rate)
- ✅ No new warnings introduced
- ✅ Code compiles/loads without errors

## Error Handling (FEEDBACK Edges)

**If any test fails after a step**:

1. **Capture failure details**:
   - Which test failed?
   - What's the error message?
   - Which step caused the failure?

2. **Create FEEDBACK edge**:
   ```json
   {
     "type": "FIX_REQUEST",
     "from": "implementation-executor",
     "to": "feedback-coordinator",
     "error": {"test": "...", "message": "...", "step": "..."},
     "action": "revert_and_retry"
   }
   ```

3. **Revert the failing step**:
   - Undo changes from this step only
   - Run tests (should pass again)
   - Analyze why step failed

4. **Try alternative approach**:
   - Adjust the transformation
   - Re-apply with different technique
   - Run tests again

5. **Max 2 attempts per step**:
   - If step fails twice, escalate to user
   - May need to abandon this refactoring or change approach

**Skills to use**: All implementation skills, rails-conventions, rails-error-prevention
```

**Wait for implementation-executor to complete all steps.**

---

## Phase 5: Post-Refactoring Verification

**DELEGATE to test-oracle agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:test-oracle`
- `description`: `Verify refactoring safety and test coverage`
- `prompt`:

```
Verify safe refactoring completion: {{REFACTORING_TARGET}}

## Validation Requirements

**1. Full Test Suite**:
- Run: `bundle exec rspec`
- ALL tests must pass (same as baseline)
- No new failures introduced

**2. Coverage Verification**:
- Current coverage: {{PERCENTAGE}}%
- Baseline coverage: {{BASELINE_PERCENTAGE}}%
- **Requirement**: Coverage must be >= baseline
- Refactoring should NOT reduce coverage

**3. Warning Check**:
- Current warnings: {{COUNT}}
- Baseline warnings: {{BASELINE_COUNT}}
- **Requirement**: No new warnings introduced

**4. Code Quality**:
- Run linter if available (rubocop)
- Check for code smells
- Verify conventions followed

**5. Functional Equivalence**:
- Behavior MUST be identical to before refactoring
- No functional changes allowed
- If behavior changed, this is a bug

## Output Format

```
✅ Refactoring Verification Complete

**Target**: {{REFACTORING_TARGET}}
**Type**: {{REFACTORING_TYPE}}

**Test Results**:
- Total tests: {{CURRENT}} (baseline: {{BASELINE}})
- Passing: {{CURRENT_PASSING}} (baseline: {{BASELINE_PASSING}})
- Status: ✅ All passing (no regressions)

**Coverage**:
- Current: {{CURRENT}}%
- Baseline: {{BASELINE}}%
- Change: {{DELTA}}% (must be >= 0)
- Status: ✅ Coverage maintained

**Warnings**:
- Current: {{CURRENT}}
- Baseline: {{BASELINE}}
- New warnings: {{NEW}} (must be 0)
- Status: ✅ No new warnings

**Quality**: ✅ Refactoring safe, no regressions
```

**Skills to use**: rspec-testing-patterns
```

**Wait for test-oracle verification.**

---

## Phase 6: Completion & Documentation

**Actions** (you handle directly):

**1. Update Beads Issue**:
- Use `mcp__plugin_beads_beads__close`
- Issue ID: {{BEADS_ISSUE_FROM_PHASE_1}}
- Summary: Refactoring completed safely

**2. Record to Episodic Memory**:
- Append to `.claude/reactree-episodes.jsonl`
- Format:
  ```json
  {
    "type": "safe_refactoring",
    "target": "{{REFACTORING_TARGET}}",
    "pattern": "{{REFACTORING_PATTERN}}",
    "files_changed": {{COUNT}},
    "tests_status": "all_passing",
    "coverage_maintained": true,
    "timestamp": "{{ISO_TIMESTAMP}}"
  }
  ```

**3. Provide Refactoring Summary**:

```
✅ Safe Refactoring Complete: {{REFACTORING_TARGET}}

## Refactoring Summary

**Type**: {{REFACTORING_PATTERN}}
**Goal**: {{WHAT_WAS_IMPROVED}}

**Changes Applied**:
- Files modified: {{COUNT}}
- Lines changed: +{{ADDED}} / -{{REMOVED}}
- References updated: {{COUNT}}

**Incremental Steps** ({{COUNT}} steps total):
1. {{STEP_1_SUMMARY}} ✅
2. {{STEP_2_SUMMARY}} ✅
...

## Verification Results

**Tests**: ✅ All {{COUNT}} tests passing
**Coverage**: ✅ {{PERCENTAGE}}% (maintained from baseline)
**Warnings**: ✅ No new warnings
**Quality**: ✅ Follows Rails conventions

## Before vs. After

**Before**:
```ruby
{{OLD_CODE_SNIPPET}}
```

**After**:
```ruby
{{NEW_CODE_SNIPPET}}
```

**Improvement**: {{EXPLANATION_OF_BENEFIT}}

## Next Steps

1. **Review the changes**:
   - Check code readability
   - Verify conventions followed
   - Ensure no functional changes

2. **Commit**:
   ```bash
   git add .
   git commit -m "Refactor: {{REFACTORING_TARGET}}

   {{DESCRIPTION_OF_CHANGES}}

   - Applied {{PATTERN_NAME}} pattern
   - Updated {{COUNT}} references
   - All tests passing ({{COUNT}}/{{COUNT}})
   - Coverage maintained at {{PERCENTAGE}}%

   Closes: {{BEADS_ISSUE_ID}}
   "
   ```

3. **Create PR** (if team workflow requires):
   - Title: "Refactor: {{REFACTORING_TARGET}}"
   - Description: Before/after comparison
   - Emphasize test coverage maintained
```

---

## Critical Reminders for Safe Refactoring

- **Green baseline REQUIRED**: Never refactor if tests are failing
- **Small steps**: Test after EACH change, not at the end
- **No functional changes**: Behavior must be identical
- **Coverage maintained**: Never reduce test coverage
- **Revert if failing**: Don't debug during refactoring - revert and retry

---

**BEGIN EXECUTION NOW**

Start with Phase 1: Pre-Flight Check (verify all tests pass).
```

## Specialist Agents Used

- **code-line-finder** (Orange) - Find all references before changes
- **codebase-inspector** (Cyan) - Understand patterns and conventions
- **implementation-executor** (Yellow) - Apply transformations
- **test-oracle** (Green) - Verify coverage and test quality
- **feedback-coordinator** (Purple) - Handle failed test iterations

## Skills Used

Refactoring skills loaded from `${CLAUDE_PLUGIN_ROOT}/skills/`:

**Core Analysis**:
- `${CLAUDE_PLUGIN_ROOT}/skills/codebase-inspection/SKILL.md` - Code analysis procedures
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-conventions/SKILL.md` - Rails patterns to follow

**Testing**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rspec-testing-patterns/SKILL.md` - Test preservation patterns

**Implementation**:
- `${CLAUDE_PLUGIN_ROOT}/skills/ruby-oop-patterns/SKILL.md` - OOP refactoring patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/service-object-patterns/SKILL.md` - Service extraction patterns

**Meta**:
- `${CLAUDE_PLUGIN_ROOT}/skills/reactree-patterns/SKILL.md` - ReAcTree workflow patterns

## Best Practices

1. **Never refactor without tests** - Add tests first if missing
2. **One refactoring at a time** - Don't combine multiple changes
3. **Preserve public API** - Internal changes only, or update all callers
4. **Run tests frequently** - After every significant change
5. **Keep commits atomic** - Each commit should be independently viable
6. **Document intent** - Commit messages explain why, not just what

## Anti-Patterns to Avoid

- **Big bang refactoring** - Too many changes at once
- **Skipping tests** - "I'll add tests later" (you won't)
- **Ignoring coverage drops** - Hidden functionality loss
- **Force-pushing fixes** - Losing history of issues
- **Refactoring during feature work** - Keep them separate

---

This workflow integrates with the ReAcTree memory systems:
- **Working Memory**: Tracks references, changes, and rollback points
- **Episodic Memory**: Learns from previous refactoring patterns
- **FEEDBACK Edges**: Enables self-correction when tests fail
