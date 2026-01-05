# Changelog

All notable changes to the ReAcTree Rails Dev plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.8.5] - 2025-01-05

### Fixed
- Version consistency in discover-skills.sh (updated from 2.5.0 to 2.8.5)
- Missing `skills` field in 4 agent frontmatter definitions:
  - ux-engineer: Added accessibility-patterns, user-experience-design, hotwire-patterns, tailadmin-patterns
  - git-diff-analyzer: Added rails-conventions, code-quality-gates
  - code-line-finder: Added codebase-inspection, rails-context-verification
  - file-finder: Added codebase-inspection

### Added
- CHANGELOG.md following Keep a Changelog format with complete version history
- Plugin validation script (scripts/validate-plugin.sh) for automated structure validation
- Enhanced plugin.json metadata:
  - `repository` field pointing to GitHub repository
  - `keywords` array with 10 relevant tags (rails, reactree, multi-agent, orchestration, type-safety, quality-gates, lsp, guardian, tdd, enterprise)

### Changed
- Improved plugin discoverability through enhanced metadata

## [2.8.4] - 2024-12-XX

### Fixed
- Fix workflow-orchestrator directory detection
- Improve file generation specialist agent delegation
- Enhance sub-agent delegation logic in workflow-orchestrator

## [2.8.3] - 2024-12-XX

### Added
- Create specialist agents for file generation tasks
- Improve delegation patterns for better task distribution

## [2.8.2] - 2024-12-XX

### Fixed
- Fix workflow-orchestrator sub-agent delegation logic
- Improve agent selection and coordination

## [2.8.1] - 2024-12-XX

### Changed
- Bump reactree-rails-dev version for consistency
- Minor documentation updates

## [2.8.0] - 2024-11-XX

### Added - Guardian Validation Cycle
- **🛡️ Guardian Validation Cycle**: Automatic type safety validation after Phase 4 implementation
- Iterative fix-validate cycle (max 3 iterations) with Sorbet
- Blocks progression if type errors remain unresolved
- Auto-logs violations to `.claude/guardian-fixes.log`
- Graceful degradation if Sorbet not available

### Added - Code Quality Gates
- **🔍 Comprehensive Quality Gates**: Solargraph, Sorbet, and Rubocop integration
- LSP diagnostics via cclsp MCP (undefined methods, constants)
- Static type checking with gradual adoption (`# typed: false/true/strict`)
- Style enforcement with auto-fix suggestions
- Blocking validation: Exit 1 prevents progress until violations fixed
- Phase 4 integration: Validates after each implementation layer

### Added - Requirements Translation
- **📋 Requirements Translation**: User story extraction with "As a... I want... So that..." format
- Automatic acceptance criteria parsing: Given/When/Then BDD format
- Component detection from prompts
- Beads task breakdown: Auto-creates epic and subtasks
- Smart routing: Routes to appropriate workflow based on intent

### Added - Real-time Validation Hooks
- **🔗 Real-time Validation Hooks**: PreToolUse and PostToolUse validation
- PreToolUse: Syntax validation **before** edits (prevents breaking changes)
- PostToolUse: Immediate feedback **after** writes (syntax, rubocop, sorbet)
- File-specific: Only validates Ruby files (`*.rb`)
- Non-blocking: Post-write validation informs but doesn't block

### Added - New Skills
- `code-quality-gates`: Comprehensive guide to Solargraph, Sorbet, and Rubocop
- `requirements-engineering`: User story format detection and task breakdown strategies

### Added - Workflow Enhancements
- **Phase 4.7: Guardian Validation Cycle**: New phase after Phase 4 implementation
- Enhanced Phase 4 Quality Gates with validate-implementation.sh
- Exit codes control workflow progression

### Added - Configuration
- `.claude/reactree-rails-dev.local.md` configuration support
- Validation levels: blocking, warning, advisory
- Guardian max iterations configuration
- Test coverage threshold settings

## [2.1.0] - 2024-10-XX

### Added - Smart Detection
- **Smart detection via UserPromptSubmit hook**: Analyzes prompts and suggests workflows
- Intent analysis and routing patterns
- Skill discovery and config initialization

### Added - Utility Agents
- `file-finder` (haiku): Fast file discovery by pattern/name
- `code-line-finder` (haiku): Find definitions/usages with LSP
- `git-diff-analyzer` (sonnet): Analyze diffs/history/blame
- `log-analyzer` (haiku): Parse Rails server logs

### Added - Configuration
- `smart_detection_enabled`: Enable/disable smart detection
- `detection_mode`: suggest | inject | disabled
- `annoyance_threshold`: low | medium | high

## [2.0.0] - 2024-09-XX

### Added - FEEDBACK Edges
- **FEEDBACK edges**: Backwards communication for self-correcting workflows
- 4 feedback types: FIX_REQUEST, CONTEXT_REQUEST, DEPENDENCY_MISSING, ARCHITECTURE_ISSUE
- `feedback-coordinator` agent routes feedback and manages fix-verify cycles
- Loop prevention: max 2 rounds per pair, max depth 3, cycle detection
- Automatic parent re-execution and child verification
- Complete audit trail in `.claude/reactree-feedback.jsonl`

### Added - TestOracle Agent
- **TestOracle agent**: Comprehensive test planning before implementation
- Test pyramid validation (70% unit, 20% integration, 10% system)
- Coverage analysis with 85% threshold enforcement
- Test quality validation (no pending, assertions, uses factories)
- Red-green-refactor orchestration using LOOP control flow
- Test-first mode via --test-first flag or TEST_FIRST_MODE=enabled
- 60% time savings vs manual TDD (45 min vs 2-3 hours)

### Added - Control Flow Enhancements
- **control-flow-manager agent**: LOOP and CONDITIONAL execution
- State persistence in `.claude/reactree-state.jsonl`
- Condition evaluation with caching to avoid redundant operations
- Support for observation checks, test results, file existence, custom expressions

### Added - New Agents
- `feedback-coordinator` (~430 lines): FEEDBACK edge routing and cycles
- `test-oracle` (~550 lines): Test planning and pyramid validation
- `control-flow-manager`: LOOP/CONDITIONAL execution

### Added - Examples
- `tdd-feedback-workflow.md`: Self-correcting TDD with FEEDBACK edges
- `test-first-workflow.md`: Complete subscription billing with TestOracle (71 tests, 89.5% coverage)
- `deployment-conditional-workflow.md`: Intelligent deployment with nested CONDITIONAL nodes

### Changed
- Enhanced `reactree-patterns` skill with 1,489 lines of new patterns
- 5 FEEDBACK patterns (test-driven, dependency discovery, architecture, context, multi-round)
- 6 test strategy patterns (pyramid, red-green-refactor, coverage, quality, feedback, metrics)

## [1.0.0] - 2024-08-XX

### Added - Initial Release
- **ReAcTree hierarchical agent orchestration** for Rails development
- **Multi-agent system** with 13 specialist agents
- **6-phase workflow**: Inspection, Planning, Database, Models, Services, Views, Tests
- **Parallel execution** of independent phases (30-50% faster)
- **Working memory** eliminates redundant codebase analysis
- **Episodic memory** learns from successful executions
- **Fallback patterns** handle transient failures gracefully

### Added - Core Agents
- `workflow-orchestrator`: Master coordinator for 6-phase workflow
- `codebase-inspector`: Pattern analysis and Rails conventions discovery
- `rails-planner`: Implementation planning with task breakdown
- `implementation-executor`: Phase execution and coordination
- `data-lead`: Database schema and migration specialist
- `backend-lead`: Service layer and controller implementation
- `ui-specialist`: ViewComponent and Turbo implementation
- `rspec-specialist`: Comprehensive test coverage
- `context-compiler`: LSP-powered context extraction

### Added - Skills Library
- 25 comprehensive Rails skills covering data, service, UI, and infrastructure layers
- ActiveRecord patterns, service objects, Hotwire, RSpec testing
- Rails conventions, error prevention, accessibility patterns

### Added - Commands
- `/reactree-dev`: Primary Rails development workflow
- `/reactree-feature`: Feature-driven development variant
- `/reactree-debug`: Systematic debugging workflow
- `/reactree-refactor`: Safe refactoring with test preservation
- `/reactree-init`: Plugin initialization and setup

### Added - Hooks
- `SessionStart`: Skill discovery and memory initialization
- Hook configuration in `hooks/hooks.json`
- Shell scripts for automation and validation

---

## Version History Summary

| Version | Release Date | Key Features |
|---------|--------------|--------------|
| **2.8.0** | 2024-11-XX | Guardian validation, quality gates, requirements translation |
| **2.1.0** | 2024-10-XX | Smart detection, utility agents |
| **2.0.0** | 2024-09-XX | FEEDBACK edges, TestOracle, control flow |
| **1.0.0** | 2024-08-XX | Initial release with hierarchical agents |

---

## Migration Guide

### Upgrading from 2.8.3 to 2.8.4+
- No breaking changes
- Skills field automatically added to agents (non-breaking)
- Plugin metadata enhanced for better discoverability

### Upgrading from 2.1.x to 2.8.0
- Create `.claude/reactree-rails-dev.local.md` for Guardian configuration
- Install Sorbet gem for type checking: `bundle add sorbet sorbet-runtime`
- Configure validation level (blocking/warning/advisory)
- Review new quality gates and adjust as needed

### Upgrading from 2.0.x to 2.1.0
- No breaking changes
- Smart detection enabled by default (can disable via config)
- New utility agents available for faster code navigation

### Upgrading from 1.x to 2.0
- FEEDBACK edges require episodic memory enabled
- TestOracle requires RSpec configured
- Control flow nodes need state persistence directory

---

## License

MIT License - see LICENSE file for details

## Author

**Mohamad Kaakati**
Email: hello@kaakati.me
GitHub: https://github.com/kaakati/rails-enterprise-dev
