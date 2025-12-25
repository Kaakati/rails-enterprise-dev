---
name: reactree-dev
description: ReAcTree-based Rails development with parallel execution, working memory, and episodic learning for 30-50% faster workflows
allowed-tools: ["*"]
---

# ReAcTree Rails Development Workflow

Initiates hierarchical Rails development workflow with:
- **Parallel execution** of independent phases (30-50% faster)
- **Working memory** system (eliminates redundant analysis)
- **Episodic memory** (learns from successful executions)
- **Fallback patterns** (resilient to transient failures)
- Automatic skill discovery from `.claude/skills/`
- Beads issue tracking
- Multi-agent orchestration with control flow nodes

## Usage

```
/reactree-dev [your feature request]
```

## Examples

```
/reactree-dev add JWT authentication with refresh tokens
/reactree-dev implement payment processing with Stripe
/reactree-dev build admin dashboard for user management
/reactree-dev add real-time notifications with Action Cable
```

## What Happens

When you run this command, the **workflow-orchestrator** agent:

1. **Phase 0: Setup** - Discovers skills + **initializes working memory**
2. **Creates Beads Issue** - Tracks entire feature (if beads installed)
3. **Phase 2: Inspection** - Analyzes codebase + **writes patterns to memory**
4. **Phase 3: Planning** - Creates plan with **dependency analysis for parallel execution**
5. **Phase 4: Implementation** - Executes using **control flow nodes** (Parallel/Sequence/Fallback)
6. **Phase 5: Review** - Final validation by Chief Reviewer
7. **Phase 6: Completion** - **Records episode to episodic memory** + closes beads issue

**Key Differences from rails-enterprise-dev**:
- ✨ **30-50% faster** through parallel execution of independent phases
- ✨ **No redundant analysis** - working memory caches all verified facts
- ✨ **Learning from success** - episodic memory improves future executions
- ✨ **Resilient workflows** - fallback patterns handle transient failures

## Workflow Activation

Invoking the workflow-orchestrator agent:

```
{{TASK_REQUEST}}

Please activate the ReAcTree Rails Development workflow for the request above.

Follow this process:
1. Discover available skills in .claude/skills/
2. **Initialize working memory system** (.claude/reactree-memory.jsonl)
3. Create beads issue for tracking (if beads available)
4. Execute Inspect → Plan → Implement → Review workflow with:
   - **Working memory** (share verified facts across agents)
   - **Parallel execution** (run independent phases concurrently)
   - **Fallback patterns** (resilience to failures)
5. Coordinate specialist agents with memory-first approach
6. Apply quality gates at checkpoints
7. **Record successful episode** to episodic memory (.claude/reactree-episodes.jsonl)
8. Provide progress updates throughout
9. Deliver final summary with beads issue ID

Start by discovering skills and initializing both memory systems.
```

The workflow orchestrator will manage all phases automatically with intelligent memory and parallel execution.

## Memory Files

The plugin creates two memory files in your project:

- `.claude/reactree-memory.jsonl` - **Working memory** (shared knowledge across agents)
- `.claude/reactree-episodes.jsonl` - **Episodic memory** (successful execution history)

These files enable:
- Faster workflows (cached patterns)
- Consistent decisions (all agents use same verified facts)
- Continuous improvement (learn from past successes)

## Configuration

The plugin uses `.claude/reactree-rails-dev.local.md` for configuration:

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
