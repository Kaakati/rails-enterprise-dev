---
name: reactree-debug
description: |
  ReAcTree-based systematic debugging with memory-assisted analysis, log parsing,
  root cause identification, and regression prevention. Uses specialized agents
  for comprehensive error investigation and fix verification.
color: orange
allowed-tools: ["*"]
---

# ReAcTree Debugging Workflow

You are initiating a **systematic debugging workflow** powered by ReAcTree architecture. This workflow ensures thorough error investigation, root cause identification, and regression prevention through specialized agents and memory systems.

## Debugging Philosophy

**Systematic debugging means:**
1. **Reproduce first** - Never fix what you can't reproduce
2. **Trace the full path** - Follow the error from trigger to failure point
3. **Understand before fixing** - Root cause, not symptoms
4. **Prevent recurrence** - Regression tests are mandatory
5. **Document findings** - Memory system preserves investigation insights

## Usage

```
/reactree-debug [error description or stack trace]
```

## Examples

**Error Messages:**
```
/reactree-debug NoMethodError in TasksController#index
/reactree-debug ArgumentError: wrong number of arguments
/reactree-debug ActiveRecord::RecordNotFound in UsersController#show
/reactree-debug undefined method 'map' for nil:NilClass
```

**Symptom Descriptions:**
```
/reactree-debug Users can't login after password reset
/reactree-debug Page loads but data is missing
/reactree-debug Button click does nothing
/reactree-debug Form submits but record not saved
```

**Performance Issues:**
```
/reactree-debug Slow query on bundles index page
/reactree-debug Request timeout on dashboard load
/reactree-debug Memory leak in background job
/reactree-debug N+1 query detected in reports
```

**Security & Integration:**
```
/reactree-debug Unauthorized access to admin panel
/reactree-debug CSRF token verification failed
/reactree-debug API returns 500 for valid request
/reactree-debug Sidekiq job keeps failing with retry
```

## Bug Types Supported

### Runtime Errors
- NoMethodError, ArgumentError, TypeError
- ActiveRecord exceptions
- Nil reference errors
- Timeout errors

### Logic Errors
- Wrong behavior (works but incorrect result)
- Race conditions
- State management issues
- Business logic failures

### Performance Issues
- Slow database queries
- N+1 query problems
- Memory leaks
- Request timeouts
- High CPU usage

### Integration Failures
- API communication errors
- External service failures
- Webhook processing issues
- Background job failures

### Security Issues
- Authentication failures
- Authorization bypass
- Session problems
- CSRF/XSS vulnerabilities

### Data Issues
- Validation failures
- Data inconsistency
- Migration issues
- Serialization errors

## Workflow Phases

### Phase 1: Error Capture
Before investigating:
1. Capture exact error message and stack trace
2. Identify reproduction steps
3. Check logs for additional context
4. Document environment conditions

### Phase 2: Investigation
Using codebase-inspector and log-analyzer:
1. Analyze stack trace to identify failure point
2. Parse relevant log files for context
3. Trace request flow through the application
4. Map affected code paths

### Phase 3: Root Cause Analysis
Using code-line-finder:
1. Locate exact failing code
2. Understand the expected vs actual behavior
3. Identify when the bug was introduced (git blame)
4. Determine scope of impact

### Phase 4: Fix Planning
Before implementing:
1. Design minimal fix with least side effects
2. Identify all affected code paths
3. Plan regression tests
4. Consider rollback strategy

### Phase 5: Fix Implementation
With implementation-executor:
1. Apply fix incrementally
2. Run affected tests after each change
3. Use FEEDBACK edges if tests fail
4. Verify fix resolves the original error

### Phase 6: Regression Test Addition
With test-oracle:
1. Write test that reproduces the bug
2. Verify test fails without fix
3. Verify test passes with fix
4. Add edge case tests

### Phase 7: Verification
Final validation:
1. Confirm original error no longer occurs
2. Run full test suite
3. Check for unintended side effects
4. Document the fix in commit message

## Quality Gates

| Gate | Threshold | Action on Fail |
|------|-----------|----------------|
| Reproduction | Error captured and reproducible | Block investigation |
| Root Cause | Clearly identified | Block fix planning |
| Fix Applied | No new errors introduced | Rollback and retry |
| Regression Test | Test added and passes | Block completion |
| Full Suite | 100% tests pass | Block completion |

## FEEDBACK Edge Handling

If fix attempts fail:
1. Analyze new failure with test-oracle
2. Route issue to feedback-coordinator
3. Determine if original diagnosis was correct
4. Apply refined fix or re-investigate
5. Max 3 feedback rounds before escalation to user

**Debug-specific feedback types:**
- `FIX_FAILED` - Fix introduced new errors
- `WRONG_ROOT_CAUSE` - Need to re-investigate
- `INCOMPLETE_FIX` - Partial resolution only
- `TEST_FLAKY` - Regression test unreliable

## Activation

```
{{ERROR_DESCRIPTION}}

Please activate the ReAcTree Debugging workflow for the error above.

Follow this process:
1. **Error Capture**
   - Parse error message and stack trace
   - Use log-analyzer to find related log entries
   - Identify reproduction conditions

2. **Investigation**
   - Use codebase-inspector to understand affected code
   - Trace the error path through the application
   - Document findings in working memory

3. **Root Cause Analysis**
   - Use code-line-finder to locate exact failure point
   - Check git history for recent changes
   - Identify the underlying cause

4. **Fix Planning**
   - Design minimal fix
   - Plan regression tests

5. **Fix Implementation**
   - Apply fix with FEEDBACK edges for failed attempts
   - Run affected tests

6. **Regression Test**
   - Add test that would have caught this bug
   - Verify test fails without fix, passes with fix

7. **Verification**
   - Run full test suite
   - Confirm error is resolved

Create beads issue for tracking if beads available.
Start with Error Capture phase.
```

## Specialist Agents Used

- **codebase-inspector** (Cyan) - Deep code analysis and pattern understanding
- **code-line-finder** (Orange) - Precise location of failing code with LSP
- **log-analyzer** (Red) - Parse Rails server logs for error context
- **test-oracle** (Green) - Regression test validation and TDD guidance
- **feedback-coordinator** (Purple) - Handle failed fix attempts and re-routing
- **implementation-executor** (Yellow) - Apply fixes following conventions
- **git-diff-analyzer** (Magenta) - Check git history for recent changes

## Skills Used

Debugging skills loaded from `${CLAUDE_PLUGIN_ROOT}/skills/`:

**Error Analysis**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-error-prevention/SKILL.md` - Common error patterns and prevention
- `${CLAUDE_PLUGIN_ROOT}/skills/codebase-inspection/SKILL.md` - Code analysis procedures

**Testing**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rspec-testing-patterns/SKILL.md` - Regression test patterns

**Implementation**:
- `${CLAUDE_PLUGIN_ROOT}/skills/rails-conventions/SKILL.md` - Rails patterns for fixes
- `${CLAUDE_PLUGIN_ROOT}/skills/activerecord-patterns/SKILL.md` - Database-related fixes

**Meta**:
- `${CLAUDE_PLUGIN_ROOT}/skills/reactree-patterns/SKILL.md` - ReAcTree workflow patterns

## Best Practices

1. **Reproduce before investigating** - Confirm the error is real and reproducible
2. **Read the full stack trace** - Don't stop at the first line
3. **Check the logs** - Server logs often have more context
4. **Minimal fixes only** - Fix the bug, don't refactor
5. **Test-first for regression** - Write the test before the fix
6. **Document the root cause** - Future you will thank you
7. **Verify in same conditions** - Test in the same environment as the error

## Anti-Patterns to Avoid

- **Symptom fixing** - Fixing what you see, not what caused it
- **Shotgun debugging** - Random changes hoping something works
- **Silent exception handling** - Catching and ignoring errors
- **No regression test** - "It works now" isn't enough
- **Blame-driven debugging** - Focus on the code, not who wrote it
- **Over-engineering the fix** - Keep it simple

---

This workflow integrates with the ReAcTree memory systems:
- **Working Memory**: Tracks investigation findings, hypotheses, and verified facts
- **Episodic Memory**: Learns from successful debugging patterns
- **FEEDBACK Edges**: Enables self-correction when fixes fail
