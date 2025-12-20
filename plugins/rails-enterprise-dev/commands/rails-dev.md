---
name: rails-dev
description: Enterprise Rails development workflow with multi-agent orchestration, skill discovery, and beads tracking
allowed-tools: ["*"]
---

# Rails Enterprise Development Workflow

Initiates comprehensive Rails development workflow with:
- Automatic skill discovery from `.claude/skills/`
- Beads issue tracking
- Multi-agent orchestration
- Quality gates at checkpoints
- Incremental implementation with validation

## Usage

```
/rails-dev [your feature request]
```

## Examples

```
/rails-dev add JWT authentication with refresh tokens
/rails-dev implement payment processing with Stripe
/rails-dev build admin dashboard for user management
/rails-dev add real-time notifications with Action Cable
```

## What Happens

When you run this command, the **workflow-orchestrator** agent:

1. **Discovers Skills** - Scans `.claude/skills/` for available guidance
2. **Creates Beads Issue** - Tracks entire feature (if beads installed)
3. **Phase 2: Inspection** - Analyzes codebase patterns
4. **Phase 3: Planning** - Creates detailed implementation plan
5. **Phase 4: Implementation** - Executes in phases with quality gates
6. **Phase 5: Review** - Final validation by Chief Reviewer
7. **Phase 6: Completion** - Closes beads issue, provides summary

## Workflow Activation

Invoking the workflow-orchestrator agent:

```
{{TASK_REQUEST}}

Please activate the Rails Enterprise Development workflow for the request above.

Follow this process:
1. Discover available skills in .claude/skills/
2. Create beads issue for tracking (if beads available)
3. Execute complete Inspect → Plan → Implement → Review workflow
4. Coordinate specialist agents for each phase
5. Apply quality gates at checkpoints
6. Provide progress updates throughout
7. Deliver final summary with beads issue ID

Start by discovering skills and initializing the workflow state.
```

The workflow orchestrator will manage all phases automatically.

## Configuration

The plugin uses `.claude/rails-enterprise-dev.local.md` for configuration:

```markdown
---
enabled: true
quality_gates_enabled: true
test_coverage_threshold: 90
auto_commit: false
---
```

**Settings**:
- `enabled`: Enable/disable plugin (default: true)
- `quality_gates_enabled`: Validate each phase before proceeding (default: true)
- `test_coverage_threshold`: Minimum test coverage % (default: 90)
- `auto_commit`: Auto-commit after successful implementation (default: false)

To disable quality gates temporarily:
```bash
# Edit .claude/rails-enterprise-dev.local.md
# Set quality_gates_enabled: false
```

## Skill Discovery

The workflow automatically discovers and uses skills from your project:

**Core Skills** (if available):
- `rails-conventions` - Rails patterns
- `rails-error-prevention` - Preventive checklists
- `codebase-inspection` - Analysis procedures

**Implementation Skills** (if available):
- `activerecord-patterns` - Database/models
- `service-object-patterns` - Service layer
- `viewcomponents-specialist` - UI components
- `hotwire-patterns` - Turbo/Stimulus
- `tailadmin-patterns` - TailAdmin UI
- `rspec-testing-patterns` - Testing
- Plus any custom project skills!

**Domain Skills** (project-specific):
- Auto-detected from `.claude/skills/` (e.g., `manifest-project-context`)

If skills aren't available, workflow continues with general Rails knowledge.

## Beads Integration

All work tracked in beads (if installed):
- Main feature epic created
- Subtasks for each implementation phase
- Dependencies enforced (Phase 2 → Phase 3 → etc.)
- Progress visible with `bd list` and `bd show [issue-id]`

**View progress**:
```bash
bd show [feature-id]  # Detailed view
bd ready              # See ready tasks
bd stats              # Project statistics
```

**If beads not installed**:
- Workflow continues without issue tracking
- Recommendation shown to install beads

## Quality Gates

When `quality_gates_enabled: true`, each phase validated:

**Database Phase**:
- Migrations run without errors
- Rollback works correctly
- Schema matches plan

**Model Phase**:
- Models load successfully
- Associations functional
- Specs pass

**Service Phase**:
- Pattern correct (Callable, etc.)
- Tests pass
- Error handling present

**Component Phase**:
- All view-called methods exposed
- Templates render without errors
- Follows UI framework patterns

**Test Phase**:
- All specs pass
- Coverage > threshold
- Edge cases included

Failed gates block progression until resolved.

## Next Steps After Completion

The workflow provides a summary with:
- Beads issue ID
- Files created/modified
- Skills used
- Quality validation results

**Your next steps**:
1. Review changes: `git diff`
2. Run full test suite: `bundle exec rspec`
3. Create commit: `git add . && git commit -m "Your message"`
4. Create PR: `gh pr create` (if using GitHub CLI)

## Specialized Variants

- `/rails-feature` - Feature-driven development with user stories
- `/rails-debug` - Systematic debugging workflow
- `/rails-refactor` - Safe refactoring with test preservation

## Troubleshooting

**Workflow interrupted?**
- State saved in `.claude/rails-enterprise-dev.local.md`
- Re-run `/rails-dev resume` to continue

**Quality gates too strict?**
- Temporarily disable: Set `quality_gates_enabled: false` in settings
- Or manually override when prompted

**Beads not working?**
- Install: `npm install -g @beads/cli`
- Or workflow continues without beads tracking

**Skills not being used?**
- Verify skills exist in `.claude/skills/`
- Check skill names match expected patterns
- Restart Claude Code after adding new skills

## Help & Support

- Plugin documentation: `.claude/plugins/rails-enterprise-dev/README.md`
- Skill customization: `.claude/plugins/rails-enterprise-dev/CUSTOMIZATION.md`
- Report issues: [GitHub repository]

---

**Ready to build!** 🚀
