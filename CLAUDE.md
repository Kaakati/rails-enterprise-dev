# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code Plugin** repository for enterprise Rails development workflows. It provides a multi-agent orchestration system with automatic skill discovery, beads task tracking, and quality gates for Rails projects.

**Key Characteristics**:
- Plugin-based architecture (not a Rails application)
- Markdown-based configuration files
- Shell scripts for automation hooks
- Generic and portable across any Rails project

## Repository Structure

```
rails-enterprise-dev/
├── plugins/rails-enterprise-dev/     # The actual plugin
│   ├── .claude-plugin/
│   │   └── plugin.json              # Plugin manifest
│   ├── agents/                      # Multi-agent workflow coordinators
│   │   ├── workflow-orchestrator.md # Main workflow coordinator
│   │   ├── codebase-inspector.md    # Pattern analysis
│   │   ├── rails-planner.md         # Implementation planning
│   │   └── implementation-executor.md # Phase execution
│   ├── commands/                    # Slash commands
│   │   ├── rails-dev.md            # Main development workflow
│   │   ├── rails-feature.md        # Feature-driven variant
│   │   ├── rails-debug.md          # Debugging workflow
│   │   └── rails-refactor.md       # Refactoring workflow
│   ├── skills/                      # Plugin meta-skills
│   │   ├── skill-discovery/        # How skill discovery works
│   │   ├── workflow-orchestration/ # Agent coordination patterns
│   │   └── beads-integration/      # Task tracking integration
│   └── hooks/                       # Automation hooks
│       ├── hooks.json              # Hook configuration
│       └── scripts/                # Shell automation scripts
├── README.md                        # User documentation
└── CUSTOMIZATION.md                 # Customization guide
```

## Architecture Principles

### 1. Plugin-Based Extension System

This is a **Claude Code plugin**, not a standalone application. It extends Claude Code with Rails-specific workflows:

- **Agents** (`.md` files in `agents/`) define specialized AI assistants
- **Commands** (`.md` files in `commands/`) define slash commands like `/rails-dev`
- **Skills** (`.md` files in `skills/`) provide reusable knowledge modules
- **Hooks** (`hooks.json` + shell scripts) automate workflow events

### 2. Skill Discovery Pattern

The plugin **discovers skills** from the target Rails project's `.claude/skills/` directory:

- Core Skills: `rails-conventions`, `rails-error-prevention`, `codebase-inspection`
- Implementation Skills: `activerecord-patterns`, `service-object-patterns`, `hotwire-patterns`, etc.
- Domain Skills: Project-specific skills (e.g., `manifest-project-context`, `ecommerce-domain`)

Skills are **project-specific**, not plugin-specific. The plugin adapts to whatever skills exist in the target project.

### 3. Multi-Agent Orchestration

Workflow coordination using specialist agents:

1. **workflow-orchestrator** - Manages entire 6-phase workflow
2. **codebase-inspector** - Analyzes existing patterns
3. **rails-planner** - Creates implementation plans
4. **implementation-executor** - Coordinates code generation

These orchestrator agents **delegate** to project-specific specialist agents (Data Lead, Backend Lead, UI Specialist, RSpec Specialist, etc.).

### 4. Beads Integration

Uses the beads issue tracker (`bd` CLI) for task management:
- Creates feature epics with `/rails-dev`
- Tracks subtasks for each implementation phase
- Maintains dependencies between phases
- Provides progress visibility

### 5. Quality Gates

Validates each implementation phase before proceeding:
- Database: Migrations run, rollback works
- Models: Load successfully, specs pass
- Services: Pattern correct, tests pass
- Components: Methods exposed, renders without errors
- Tests: All pass, coverage > threshold

## File Format Standards

### Agent Files (`agents/*.md`)

Markdown files with YAML frontmatter:

```markdown
---
name: agent-name
description: What this agent does
model: inherit  # or sonnet/haiku/opus
color: blue     # UI color indicator
tools: ["*"]    # Tools allowed (* = all)
---

Agent system prompt content...
```

### Command Files (`commands/*.md`)

Markdown files with YAML frontmatter:

```markdown
---
name: command-name
description: Command description
allowed-tools: ["*"]
---

Command documentation and activation instructions...
```

### Skill Files (`skills/*/SKILL.md`)

Markdown files with YAML frontmatter:

```markdown
---
name: Skill Name
description: Skill description
version: 1.0.0
---

Skill content (patterns, conventions, examples)...
```

### Hook Configuration (`hooks/hooks.json`)

JSON configuration for automation hooks:

```json
{
  "PreToolUse": ["script-name"],
  "PostToolUse": ["script-name"],
  "SessionStart": ["script-name"]
}
```

## Key Conventions

### Naming Conventions

**Skill Categorization** (auto-detected by skill discovery):
- Data layer: `activerecord-*`, `*-model*`, `*-database*`, `*-schema*`
- Service layer: `*service*`, `api-*`
- UI layer: `*component*`, `*view*`, `*-ui-*`, `hotwire-*`, `turbo-*`, `stimulus-*`, `frontend-*`
- Domain: Any skill not matching above patterns

**File Naming**:
- Agents: `kebab-case.md` in `agents/`
- Commands: `kebab-case.md` in `commands/`
- Skills: `kebab-case/SKILL.md` (directory + SKILL.md file)
- Hooks: `kebab-case.sh` in `hooks/scripts/`

### Markdown Conventions

- Use GitHub-flavored markdown
- Include code blocks with language tags
- Use YAML frontmatter for metadata
- Write clear descriptions and examples

### Shell Script Conventions

Hook scripts follow standard bash practices:
- Exit code 0: Success
- Exit code 1: Failure
- Exit code 2: Warning/validation failure
- Include `#!/bin/bash` shebang
- Use defensive scripting (`set -e`, etc.)

## Testing & Validation

Since this is a plugin repository (not a Rails app), there's no traditional test suite. Validation happens through:

1. **Plugin Loading**: Verify plugin.json is valid JSON
2. **Markdown Parsing**: Ensure YAML frontmatter is valid
3. **Hook Execution**: Test shell scripts execute without errors
4. **Integration Testing**: Install in a Rails project and test workflows

### Manual Testing Workflow

```bash
# 1. Test plugin.json validity
cat plugins/rails-enterprise-dev/.claude-plugin/plugin.json | json_pp

# 2. Validate YAML frontmatter in agents
head -20 plugins/rails-enterprise-dev/agents/workflow-orchestrator.md

# 3. Test shell scripts
bash plugins/rails-enterprise-dev/hooks/scripts/discover-skills.sh

# 4. Integration test in actual Rails project
# Copy plugin to .claude/plugins/ in Rails project
# Run /rails-dev command
```

## Common Development Tasks

### Adding a New Agent

1. Create agent file: `plugins/rails-enterprise-dev/agents/new-agent.md`
2. Add YAML frontmatter with name, description, model, color, tools
3. Write agent system prompt
4. Reference agent in workflow-orchestrator or command files

### Adding a New Command

1. Create command file: `plugins/rails-enterprise-dev/commands/new-command.md`
2. Add YAML frontmatter with name, description, allowed-tools
3. Write command documentation and activation instructions
4. Test by invoking `/new-command` in Claude Code

### Adding a New Skill

1. Create skill directory: `plugins/rails-enterprise-dev/skills/new-skill/`
2. Create SKILL.md: `plugins/rails-enterprise-dev/skills/new-skill/SKILL.md`
3. Add YAML frontmatter with name, description, version
4. Write skill content (patterns, conventions, examples)

### Adding a New Hook

1. Create shell script: `plugins/rails-enterprise-dev/hooks/scripts/new-hook.sh`
2. Make executable: `chmod +x plugins/rails-enterprise-dev/hooks/scripts/new-hook.sh`
3. Add to hooks.json in appropriate event (PreToolUse, PostToolUse, etc.)
4. Test execution manually

## Important Notes

### This Repository vs. Target Rails Projects

**This Repository**:
- Plugin definition and orchestration logic
- Generic workflow patterns
- No project-specific code
- No Rails application code

**Target Rails Projects** (where plugin is used):
- Has `.claude/plugins/rails-enterprise-dev/` (copied from this repo)
- Has `.claude/skills/` with project-specific skills
- Has `.claude/agents/` with project specialist agents
- Has actual Rails application code

### Plugin Installation

Users install by copying `plugins/rails-enterprise-dev/` to their project's `.claude/plugins/` directory:

```bash
# In user's Rails project
cp -r /path/to/this/repo/plugins/rails-enterprise-dev .claude/plugins/
```

Or via Claude Code's plugin marketplace (future).

### Skill Discovery vs. Plugin Skills

- **Plugin skills** (`plugins/rails-enterprise-dev/skills/`): Meta-skills about how the plugin works
- **Project skills** (user's `.claude/skills/`): Project-specific patterns the plugin discovers

The plugin's `skill-discovery` skill documents how discovery works, but the discovered skills come from the target project.

## Documentation Structure

- **README.md**: User-facing documentation for plugin usage
- **CUSTOMIZATION.md**: Guide for customizing the plugin for specific projects
- **This file (CLAUDE.md)**: Internal guidance for working on the plugin itself

## Version Control

This repository uses git for version control. The `.gitignore` only ignores `.DS_Store` files.

**Note**: User projects using this plugin should add `.claude/*.local.md` to their gitignore, but this repository doesn't need that since it's the plugin source, not a project using the plugin.
- bump the plugin version everytime you want to push to git
- bump the plugin version everytime you want to push to git