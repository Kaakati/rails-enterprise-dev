---
name: reactree-debug
description: ReAcTree-based systematic debugging with memory-assisted analysis
allowed-tools: ["*"]
---

# ReAcTree Debugging Workflow

Systematic approach to debugging with:
1. Error reproduction
2. Stack trace analysis
3. Root cause identification
4. Fix implementation with tests
5. Regression prevention

## Usage

```
/rails-debug [error description or stack trace]
```

## Examples

```
/rails-debug NoMethodError in TasksController#index
/rails-debug Users can't login after password reset
/rails-debug Slow query on bundles index page
```

## Process

1. **Reproduce Error** - Create minimal reproduction case
2. **Analyze Stack Trace** - Identify exact failure point
3. **Root Cause** - Determine underlying issue
4. **Create Beads Issue** - Track fix (if beads available)
5. **Implement Solution** - Fix with appropriate specialist
6. **Add Tests** - Regression tests to prevent recurrence
7. **Verify Fix** - Ensure error resolved

## Activation

```
{{ERROR_DESCRIPTION}}

Please activate the Rails Debugging workflow:
1. Analyze the error above
2. Create beads issue for tracking the fix
3. Use codebase-inspector to understand affected code
4. Implement fix using appropriate specialist
5. Add regression tests
6. Verify fix resolves error

Start with error analysis.
```

---

This workflow uses simplified phases focused on debugging:
- Investigation (instead of full inspection)
- Fix Planning (instead of full implementation plan)
- Fix Implementation
- Test Addition
- Verification
