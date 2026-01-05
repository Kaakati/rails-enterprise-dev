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

**Error Description:**
```
{{ERROR_DESCRIPTION}}
```

---

**IMMEDIATE ACTION REQUIRED**: You must now invoke the workflow-orchestrator agent to execute systematic debugging for this error.

**Use the Task tool with these exact parameters:**

- **subagent_type**: `reactree-rails-dev:workflow-orchestrator`
- **description**: `Execute systematic debugging workflow`
- **prompt**: (Use the prompt template below)

---

## Workflow-Orchestrator Agent Prompt Template

```
Error to Debug: {{ERROR_DESCRIPTION}}

You are the **workflow-orchestrator** agent coordinating a **systematic debugging workflow** using the ReAcTree architecture.

## Your Mission

Execute systematic debugging with:
- **Error reproduction**: Capture exact conditions that trigger the error
- **Root cause analysis**: Identify the underlying cause, not just symptoms
- **Minimal fix**: Apply smallest change that solves the problem
- **Regression test**: Add test to prevent this bug from recurring
- **Verification**: Ensure fix works and doesn't break anything else

## Your Responsibilities

As the master coordinator for debugging, you must:

1. ✅ **Reproduce the error** reliably before attempting any fix
2. ✅ **Find root cause** through systematic investigation
3. ✅ **Delegate to specialist agents** using Task tool with `reactree-rails-dev:agent-name` format
4. ✅ **Validate fix** with regression test and full test suite
5. ✅ **Track progress** in beads and working memory
6. ✅ **Handle failures** via FEEDBACK edges (fix attempts may fail)

---

## Phase 1: Error Capture & Reproduction

**Actions** (you handle directly):

**1. Parse Error Information**:

Extract from error description:
- **Error type**: Exception class (e.g., NoMethodError, ActiveRecord::RecordNotFound)
- **Error message**: Exact error text
- **Stack trace**: File and line numbers where error occurred
- **Context**: What user action triggered this? What were they trying to do?

**2. Create Beads Issue**:
- Use `mcp__plugin_beads_beads__create`
- Title: "Debug: {{ERROR_TYPE_SUMMARY}}"
- Type: "bug"
- Description: Full error details + reproduction steps
- Priority: Based on severity (1=critical/production down, 2=high/blocks users, 3=medium, 4=low)
- Store issue ID for tracking

**3. Identify Reproduction Conditions**:
- What URL or endpoint was accessed?
- What request parameters or data were used?
- What user state (logged in/out, permissions, etc.)?
- Are there logs available? (use log-analyzer agent if logs exist)

**4. Cache to Working Memory**:
```json
{
  "type": "error_context",
  "error_class": "...",
  "error_message": "...",
  "stack_trace": ["..."],
  "reproduction_steps": ["..."],
  "beads_issue_id": "...",
  "timestamp": "..."
}
```

**Output**: Confirm error captured, reproduction steps identified, beads issue created

---

## Phase 2: Log Analysis (if applicable)

**If Rails server logs are available**, DELEGATE to log-analyzer agent:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:log-analyzer`
- `description`: `Parse Rails logs for error context`
- `prompt`:

```
Analyze Rails server logs to find context for error: {{ERROR_DESCRIPTION}}

## Search Criteria

**Look for**:
- Log entries around the time of error
- Stack traces (full backtrace)
- Request parameters
- SQL queries executed before error
- Previous errors or warnings in same request
- Timestamp correlation

## Output Requirements

**For EACH relevant log entry**:
- Timestamp
- Log level (ERROR, WARN, INFO)
- Complete message
- Associated request ID (if available)

**Identify patterns**:
- Does error always occur with specific parameters?
- Are there related warnings before the error?
- What was the sequence of events leading to error?

Cache findings to working memory.

**Skills to use**: rails-error-prevention
```

**Wait for log-analyzer if used.** Otherwise skip to next phase.

---

## Phase 3: Code Investigation

**DELEGATE to codebase-inspector agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:codebase-inspector`
- `description`: `Understand code context around error`
- `prompt`:

```
Investigate codebase to understand error: {{ERROR_DESCRIPTION}}

## Investigation Focus

**Stack Trace Analysis**:
- Read files mentioned in stack trace (top to bottom)
- Understand what each method was trying to do
- Identify where the actual failure occurred (deepest point in our code, not gem code)

**Code Flow Tracing**:
- How did execution reach the failing point?
- What assumptions did the code make that turned out to be false?
- Are there nil checks, validations, or error handling missing?

**Context Understanding**:
- What models, services, or components are involved?
- What are the expected inputs vs. actual inputs?
- Are there similar patterns elsewhere in the codebase that work correctly?

## Output Requirements

**Provide**:
- File path and line number of actual failure point
- Explanation of what code was trying to do
- Explanation of why it failed (nil value, wrong type, missing record, etc.)
- Related code patterns that might be relevant
- Cache findings to working memory

**Skills to use**: codebase-inspection, rails-context-verification, rails-conventions
```

**Wait for codebase-inspector to complete.**

---

## Phase 4: Root Cause Analysis

**DELEGATE to code-line-finder agent** (for precise location and git history):

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:code-line-finder`
- `description`: `Locate exact failure point and check history`
- `prompt`:

```
Find exact location and history of error: {{ERROR_DESCRIPTION}}

## LSP Analysis

**Use LSP tools to**:
- Find definition of failing method
- Find all references to failing method
- Check for recent changes to this code

## Git History Analysis

**Check git history for**:
- When was this code last modified?
- What was the commit message?
- Did recent changes introduce this bug?
- Was this code working before? When did it break?

Use: `git log -p -- {{FILE_PATH}}` to see changes to the file
Use: `git blame {{FILE_PATH}}` to see who last touched relevant lines

## Output Requirements

**Provide**:
- Exact file and line number of failure
- Recent git commits affecting this code
- When bug was likely introduced (if recent change)
- Whether this is a regression or long-standing issue

Cache findings to working memory.

**Skills to use**: codebase-inspection
```

**Wait for code-line-finder to complete.**

---

## Phase 5: Root Cause Identification

**Actions** (you handle directly):

**Synthesize findings from investigation**:

From working memory, you now have:
- Error details (Phase 1)
- Log context (Phase 2, if applicable)
- Code context (Phase 3)
- Exact location and history (Phase 4)

**Identify root cause** (not just symptom):
- **Symptom**: What broke (e.g., "NoMethodError on nil")
- **Root cause**: Why it broke (e.g., "User model missing validation, allowed nil email")

**Examples of root vs. symptom**:
- ❌ Symptom: "called upcase on nil"
- ✅ Root cause: "Email not validated for presence, allowed nil in database"

- ❌ Symptom: "Record not found"
- ✅ Root cause: "Deletion missing dependent: :destroy, orphaned foreign keys"

**Document root cause**:
```json
{
  "type": "root_cause_identified",
  "symptom": "...",
  "root_cause": "...",
  "file": "...",
  "line": ...,
  "proposed_fix": "...",
  "timestamp": "..."
}
```

**Output**: Clear explanation of root cause

---

## Phase 6: Fix Planning with Test-First Approach

**DELEGATE to test-oracle agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:test-oracle`
- `description`: `Design regression test before fix`
- `prompt`:

```
Design regression test for bug: {{ERROR_DESCRIPTION}}

## Root Cause Context

**Root Cause**: {{ROOT_CAUSE_FROM_PHASE_5}}

## Regression Test Requirements

**Test must**:
1. Reproduce the exact error condition
2. FAIL without the fix (proves test catches the bug)
3. PASS with the fix (validates fix works)
4. Be clear and maintainable (future developers understand it)
5. Run quickly (unit test preferred over system test)

## Test Design

**Choose test type**:
- **Model spec**: If root cause is validation, association, or business logic
- **Service spec**: If root cause is in service layer
- **Request spec**: If root cause is in controller/routing
- **System spec**: If root cause is in UI interaction (last resort, slower)

**Test structure**:
```ruby
describe "Bug: {{BUG_SUMMARY}}" do
  it "{{DESCRIBES_EXPECTED_BEHAVIOR}}" do
    # Setup: Create conditions that trigger bug
    # Exercise: Perform action that caused error
    # Verify: Assert expected behavior (not error)
  end
end
```

## Output Requirements

**Provide**:
- Test file path (e.g., `spec/models/user_spec.rb`)
- Complete test code
- Explanation of what test does
- Confirmation test will fail before fix

**Skills to use**: rspec-testing-patterns, rails-conventions
```

**Wait for test-oracle to complete.** Review regression test plan.

---

## Phase 7: Fix Implementation (TDD: Red-Green)

**DELEGATE to implementation-executor agent**:

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:implementation-executor`
- `description**: `Implement minimal fix with regression test`
- `prompt`:

```
Implement minimal fix for: {{ERROR_DESCRIPTION}}

## Available Context

**Root Cause**: {{ROOT_CAUSE}}
**Regression Test**: Complete test from test-oracle
**Current Code**: {{FILE_AND_LINE_FROM_INVESTIGATION}}

## Fix Strategy (TDD: Red-Green)

**Step 1: RED - Write Failing Test**:
- Create regression test file (from test-oracle plan)
- Run test (should FAIL and reproduce the error)
- Confirm test failure message matches original error

**Step 2: GREEN - Minimal Fix**:
- Implement smallest possible change to fix root cause
- Examples of minimal fixes:
  - Add validation: `validates :email, presence: true`
  - Add nil check: `user&.email&.upcase`
  - Add dependent destroy: `has_many :posts, dependent: :destroy`
  - Fix typo in method name
  - Add missing rescue block

**DO NOT**:
- Refactor surrounding code (that's a separate task)
- Add extra features ("while I'm here...")
- Change code style unless it's part of the fix

**Step 3: Verify Fix**:
- Run regression test (should now PASS)
- Run related tests (should still pass)
- Document fix reasoning in code comment if non-obvious

## Quality Gates

- ✅ Regression test exists and passed
- ✅ Regression test fails when fix is removed (proves test works)
- ✅ Fix is minimal (no unrelated changes)
- ✅ Related tests still pass

## Error Handling (FEEDBACK Edges)

**If fix attempt fails**:
- Capture new error
- Route to feedback-coordinator
- Analyze if root cause diagnosis was wrong
- Try alternative fix approach
- Max 2 fix attempts before escalation

**Skills to use**: All implementation skills, rails-error-prevention
```

**Wait for implementation-executor to complete fix.**

---

## Phase 8: Verification

**DELEGATE to test-oracle agent** (validation mode):

**Invoke Task tool with:**
- `subagent_type`: `reactree-rails-dev:test-oracle`
- `description`: `Validate fix with full test suite`
- `prompt`:

```
Validate bug fix: {{ERROR_DESCRIPTION}}

## Validation Requirements

**1. Regression Test Validation**:
- Confirm regression test exists
- Confirm regression test passes with fix
- Confirm regression test fails without fix (temporarily revert fix to check)

**2. Related Tests**:
- Run tests in same file (e.g., all model specs)
- Ensure no regressions introduced

**3. Full Test Suite**:
- Run: `bundle exec rspec`
- All tests must pass
- No new failures introduced

**4. Manual Verification** (if possible):
- Reproduce original error scenario
- Confirm error no longer occurs

## Output Format

```
✅ Bug Fix Validated

**Original Error**: {{ERROR_DESCRIPTION}}
**Root Cause**: {{ROOT_CAUSE}}
**Fix Applied**: {{FIX_DESCRIPTION}}

**Regression Test**: spec/{{path}}/{{file}}_spec.rb
- ✅ Test passes with fix
- ✅ Test fails without fix (validated)

**Test Suite**: {{TOTAL}} tests
- ✅ All passing
- ✅ No regressions introduced

**Manual Verification**: {{RESULT}}
```

**Skills to use**: rspec-testing-patterns
```

**Wait for test-oracle validation.**

---

## Phase 9: Completion & Documentation

**Actions** (you handle directly):

**1. Update Beads Issue**:
- Use `mcp__plugin_beads_beads__update`
- Issue ID: {{BEADS_ISSUE_FROM_PHASE_1}}
- Status: "closed"
- Notes: Root cause, fix applied, regression test added

**2. Record to Episodic Memory**:
- Append to `.claude/reactree-episodes.jsonl`
- Format:
  ```json
  {
    "type": "bug_fixed",
    "error": "{{ERROR_TYPE}}",
    "root_cause": "{{ROOT_CAUSE}}",
    "fix_type": "{{FIX_TYPE}}",
    "regression_test": "{{TEST_PATH}}",
    "timestamp": "{{ISO_TIMESTAMP}}"
  }
  ```

**3. Provide Debug Summary**:

```
✅ Bug Fixed: {{ERROR_SUMMARY}}

## Original Error

```
{{ERROR_DESCRIPTION_WITH_STACK_TRACE}}
```

## Root Cause

**Symptom**: {{WHAT_BROKE}}
**Root Cause**: {{WHY_IT_BROKE}}

## Fix Applied

**File**: {{FILE_PATH}}:{{LINE_NUMBER}}
**Change**: {{DESCRIPTION_OF_FIX}}

**Code**:
```ruby
# Before:
{{OLD_CODE}}

# After:
{{NEW_CODE}}
```

## Regression Test

**Test**: {{TEST_FILE_PATH}}
- ✅ Test fails without fix (proves it catches the bug)
- ✅ Test passes with fix (validates fix works)
- ✅ Full test suite passes

## Verification

- ✅ Error no longer occurs
- ✅ No regressions introduced
- ✅ Beads issue closed: {{BEADS_ISSUE_ID}}

## Next Steps

1. **Commit the fix**:
   ```bash
   git add .
   git commit -m "Fix: {{ERROR_SUMMARY}}

   Root cause: {{ROOT_CAUSE}}
   Added regression test: {{TEST_PATH}}

   Closes: {{BEADS_ISSUE_ID}}
   "
   ```

2. **Deploy** (if production bug):
   - Create hotfix branch if needed
   - Run full test suite one more time
   - Deploy to production

3. **Monitor**: Watch for this error in logs after deployment
```

---

## Critical Reminders for Debugging

- **Reproduce FIRST**: Never attempt fix without reliable reproduction
- **Root cause, not symptom**: Understand WHY it broke, not just WHAT broke
- **Minimal fix**: Smallest change that solves the problem
- **Regression test REQUIRED**: Must have test that catches this bug
- **Verify thoroughly**: Full test suite must pass

---

**BEGIN EXECUTION NOW**

Start with Phase 1: Error Capture & Reproduction.
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
