---
name: reactree-refactor
description: |
  ReAcTree-based safe refactoring workflow with test preservation, reference tracking,
  and quality gates. Specializes in code transformation while maintaining all existing
  functionality and test coverage.
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

```
{{REFACTORING_TARGET}}

Please activate the Safe Refactoring workflow:

1. **Pre-Flight Check**
   - Run test suite to ensure green baseline
   - Capture coverage metrics

2. **Reference Discovery**
   - Use code-line-finder to find all usages of the target
   - Map dependencies and affected files
   - Document findings in working memory

3. **Safe Transformation**
   - Apply refactoring incrementally
   - Run related tests after each change
   - Use FEEDBACK edges if tests fail

4. **Verification**
   - Test Oracle verifies all tests pass
   - Coverage has not degraded
   - No new warnings introduced

5. **Completion**
   - Commit with detailed message describing refactoring

Start with Pre-Flight Check to ensure test suite is green.
```

## Specialist Agents Used

- **code-line-finder** - Find all references before changes
- **codebase-inspector** - Understand patterns and conventions
- **implementation-executor** - Apply transformations
- **test-oracle** - Verify coverage and test quality
- **feedback-coordinator** - Handle failed test iterations

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
