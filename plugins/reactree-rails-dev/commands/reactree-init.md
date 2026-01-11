---
name: reactree-init
description: |
  Initialize ReAcTree plugin in the current Rails project. Creates configuration,
  validates prerequisites, sets up working memory, and optionally copies bundled
  skills. Run this first when using the plugin in a new project.
allowed-tools: ["Bash", "Read", "Write", "Glob", "AskUserQuestion"]
---

# ReAcTree Plugin Initialization

You are initializing the ReAcTree plugin for this Rails project. Follow these steps systematically and provide clear feedback at each stage.

## Phase 1: Validate Plugin Installation

First, determine the plugin's actual location using `${CLAUDE_PLUGIN_ROOT}`:

```bash
# CLAUDE_PLUGIN_ROOT is set by Claude Code to the plugin's actual location
# This works regardless of how the plugin was installed (local, global, marketplace)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

# Fallback to local path if not set (for manual testing)
if [ -z "$PLUGIN_ROOT" ]; then
  if [ -d ".claude/plugins/reactree-rails-dev" ]; then
    PLUGIN_ROOT=".claude/plugins/reactree-rails-dev"
  else
    echo "ERROR: CLAUDE_PLUGIN_ROOT not set and no local plugin found"
    echo "Plugin location could not be determined"
    exit 1
  fi
fi

echo "Plugin located at: $PLUGIN_ROOT"

# Check plugin directory exists
ls -la "$PLUGIN_ROOT/" 2>/dev/null

# Check hooks.json exists
cat "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null | head -5

# Check scripts are executable
ls -la "$PLUGIN_ROOT/hooks/scripts/"*.sh 2>/dev/null
```

**Expected**: Plugin directory with hooks.json and executable scripts.

**If CLAUDE_PLUGIN_ROOT is empty**: The command will check for a local installation at `.claude/plugins/reactree-rails-dev/`.

**If neither exists**: Report error - plugin not installed correctly.

## Phase 2: Check Skills Directory

Check if the project has skills:

```bash
# Check skills directory
ls -la .claude/skills/ 2>/dev/null

# Count skill directories (subtract 1 for the directory itself)
skill_count=$(find .claude/skills -maxdepth 1 -type d 2>/dev/null | wc -l)
echo "Found $((skill_count - 1)) skills"
```

### Case A: Skills Directory Exists WITH Skills

If `.claude/skills/` exists and has skills, use AskUserQuestion to ask:

```
Found X existing skills in .claude/skills/

The plugin includes 18 bundled skills (may be newer versions).
Would you like to update/replace them?

Options:
  [1] Replace all with bundled skills (Recommended)
      - Overwrites existing skills with latest versions from plugin
      - activerecord-patterns, service-object-patterns, hotwire-patterns, etc.

  [2] Keep existing skills
      - Don't modify .claude/skills/
      - Continue with current skills

  [3] Merge (add missing only)
      - Keep existing skills
      - Add any new skills not already present
```

### Case B: Skills Directory Empty or Missing

If `.claude/skills/` is empty or missing, use AskUserQuestion to offer:

```
No skills found in .claude/skills/

The plugin includes 18 bundled skills for Rails development.
Would you like to copy them to your project?

Options:
  [1] Copy all bundled skills (Recommended)
      - activerecord-patterns, service-object-patterns, hotwire-patterns
      - rspec-testing-patterns, rails-conventions, rails-error-prevention
      - viewcomponents-specialist, sidekiq-async-patterns, and 10 more

  [2] Copy only core skills (3 skills)
      - rails-conventions, rails-error-prevention, codebase-inspection

  [3] Skip - I'll add skills manually later
```

### Copy/Replace Skills Based on User Choice

**Important**: Use `$PLUGIN_ROOT` variable from Phase 1 (set via `${CLAUDE_PLUGIN_ROOT}`).

**Replace all / Copy all bundled skills**:
```bash
mkdir -p .claude/skills
# Remove existing to ensure clean state
rm -rf .claude/skills/*
cp -r "$PLUGIN_ROOT/skills/"* .claude/skills/
echo "Copied 18 skills to .claude/skills/"
```

**Copy only core skills**:
```bash
mkdir -p .claude/skills
cp -r "$PLUGIN_ROOT/skills/rails-conventions" .claude/skills/
cp -r "$PLUGIN_ROOT/skills/rails-error-prevention" .claude/skills/
cp -r "$PLUGIN_ROOT/skills/codebase-inspection" .claude/skills/
echo "Copied 3 core skills to .claude/skills/"
```

**Merge (add missing only)**:
```bash
mkdir -p .claude/skills
for skill_dir in "$PLUGIN_ROOT/skills/"*/; do
  skill_name=$(basename "$skill_dir")
  if [ ! -d ".claude/skills/$skill_name" ]; then
    cp -r "$skill_dir" ".claude/skills/"
    echo "Added missing skill: $skill_name"
  fi
done
```

## Phase 2.6: Rules System Setup

Check if the project has rules and offer interactive setup:

```bash
# Check rules directory
ls -la .claude/rules/ 2>/dev/null

# Count rule files
rule_count=$(find .claude/rules -maxdepth 2 -name '*.md' -type f 2>/dev/null | wc -l)
echo "Found $rule_count existing rule files"
```

### Case A: Rules Directory Exists WITH Rules

If `.claude/rules/` exists and has rules, use AskUserQuestion to ask:

```
Found X existing rule files in .claude/rules/

The plugin includes 15 bundled rules (may be newer versions).
Would you like to update/replace them?

Options:
  [1] Replace all with bundled rules (Recommended)
      - Overwrites existing rules with latest versions from plugin
      - rails/models.md, rails/controllers.md, frontend/components.md, etc.

  [2] Keep existing rules
      - Don't modify .claude/rules/
      - Continue with current rules

  [3] Merge (add missing only)
      - Keep existing rules
      - Add any new rules not already present
```

### Case B: Rules Directory Empty or Missing

If `.claude/rules/` is empty or missing, use AskUserQuestion to offer:

```
No rules found in .claude/rules/

The plugin includes 15 bundled rules for path-specific guidance.
Would you like to copy them to your project?

Options:
  [1] Copy all bundled rules (Recommended)
      - Rails rules: models, controllers, services, channels, jobs, mailers
      - Frontend rules: components, stimulus
      - Testing rules: model-specs, request-specs, system-specs
      - Database rules: migrations
      - Quality gates: security, performance, accessibility

  [2] Copy only core rules (3 rules)
      - rails/models.md, rails/controllers.md, frontend/components.md

  [3] Skip - I'll add rules manually later
```

### Copy/Replace Rules Based on User Choice

**Important**: Use `$PLUGIN_ROOT` variable from Phase 1 (set via `${CLAUDE_PLUGIN_ROOT}`).

**Replace all / Copy all bundled rules**:
```bash
echo "=== Copying All Bundled Rules ==="
mkdir -p .claude/rules
# Remove existing to ensure clean state
rm -rf .claude/rules/*
cp -r "$PLUGIN_ROOT/rules/"* .claude/rules/

# Count copied rules
rule_count=$(find .claude/rules -name '*.md' -type f | wc -l)
echo "Copied $rule_count rule files to .claude/rules/"
```

**Copy only core rules**:
```bash
echo "=== Copying Core Rules ==="
mkdir -p .claude/rules/rails
mkdir -p .claude/rules/frontend

cp "$PLUGIN_ROOT/rules/rails/models.md" .claude/rules/rails/
cp "$PLUGIN_ROOT/rules/rails/controllers.md" .claude/rules/rails/
cp "$PLUGIN_ROOT/rules/frontend/components.md" .claude/rules/frontend/

echo "Copied 3 core rules to .claude/rules/"
```

**Merge (add missing only)**:
```bash
echo "=== Merging Rules ==="
mkdir -p .claude/rules

# Copy each directory structure, only adding missing files
for category_dir in "$PLUGIN_ROOT/rules/"*/; do
  category_name=$(basename "$category_dir")
  mkdir -p ".claude/rules/$category_name"

  for rule_file in "$category_dir"*.md; do
    rule_name=$(basename "$rule_file")
    dest_file=".claude/rules/$category_name/$rule_name"

    if [ ! -f "$dest_file" ]; then
      cp "$rule_file" "$dest_file"
      echo "Added missing rule: $category_name/$rule_name"
    fi
  done
done

rule_count=$(find .claude/rules -name '*.md' -type f | wc -l)
echo "Total rules after merge: $rule_count"
```

**Display Rules Documentation**:

```bash
echo ""
echo "Rules System:"
echo "  - Path-specific rules automatically load based on file being edited"
echo ""
echo "  Rails Rules:"
echo "    • app/models/**/*.rb → rules/rails/models.md"
echo "    • app/controllers/**/*.rb → rules/rails/controllers.md"
echo "    • app/services/**/*.rb → rules/rails/services.md"
echo "    • app/channels/**/*.rb → rules/rails/channels.md"
echo "    • app/jobs/**/*.rb → rules/rails/jobs.md"
echo "    • app/mailers/**/*.rb → rules/rails/mailers.md"
echo ""
echo "  Frontend Rules:"
echo "    • app/components/**/*.rb → rules/frontend/components.md"
echo "    • app/javascript/**/*_controller.js → rules/frontend/stimulus.md"
echo ""
echo "  Testing Rules:"
echo "    • spec/models/**/*_spec.rb → rules/testing/model-specs.md"
echo "    • spec/requests/**/*_spec.rb → rules/testing/request-specs.md"
echo "    • spec/system/**/*_spec.rb → rules/testing/system-specs.md"
echo ""
echo "  Database Rules:"
echo "    • db/migrate/**/*.rb → rules/database/migrations.md"
echo ""
echo "  Quality Gates (apply to all files):"
echo "    • **/*.rb, **/*.erb → rules/quality-gates/security.md"
echo "    • **/*.rb, **/*.erb → rules/quality-gates/performance.md"
echo "    • **/*.erb → rules/quality-gates/accessibility.md"
echo ""
echo "Benefits:"
echo "  ✅ Only relevant rules load (60-70% reduction in context overhead)"
echo "  ✅ Hyper-targeted guidance for the specific file type"
echo "  ✅ Customizable per project (.claude/rules/ can be modified)"
echo "  ✅ Works alongside existing skills system"
echo ""
```

## Phase 2.5: Ruby Analysis Tools Setup

Automatically install missing Ruby analysis tools for enhanced context compilation and Guardian validation:

```bash
echo "=== Ruby Analysis Tools Setup ==="
echo ""

# Track what gets installed
GEMS_INSTALLED=""

# Install Solargraph if missing (Ruby LSP)
if ! gem list solargraph -i &>/dev/null; then
  echo "Installing solargraph (Ruby LSP)..."
  gem install solargraph && GEMS_INSTALLED="$GEMS_INSTALLED solargraph"
fi

# Install Sorbet if missing (Type Checker)
if ! gem list sorbet -i &>/dev/null; then
  echo "Installing sorbet + sorbet-runtime (Type Checker)..."
  gem install sorbet sorbet-runtime && GEMS_INSTALLED="$GEMS_INSTALLED sorbet"
fi

# Install parser gem if missing (AST Analysis)
if ! gem list parser -i &>/dev/null; then
  echo "Installing parser (AST Analysis)..."
  gem install parser && GEMS_INSTALLED="$GEMS_INSTALLED parser"
fi

if [ -z "$GEMS_INSTALLED" ]; then
  echo "All required gems already installed"
else
  echo ""
  echo "Installed:$GEMS_INSTALLED"
fi
```

**Create .solargraph.yml configuration:**

```bash
# Configure Solargraph for project if no config exists
if [ ! -f ".solargraph.yml" ]; then
  echo "Creating .solargraph.yml..."
  cat > .solargraph.yml <<'SOLARGRAPH'
include:
  - "**/*.rb"
exclude:
  - spec/**/*
  - test/**/*
  - vendor/**/*
  - node_modules/**/*
reporters:
  - rubocop
  - require_not_found
max_files: 5000
SOLARGRAPH
  echo "Created .solargraph.yml"
else
  echo ".solargraph.yml already exists"
fi
```

**Configure cclsp MCP server:**

```bash
# Create .mcp.json for cclsp MCP server (correct location for Claude Code)
if [ ! -f ".mcp.json" ]; then
  cat > .mcp.json <<'MCP'
{
  "mcpServers": {
    "cclsp": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "cclsp"]
    }
  }
}
MCP
  echo "Created .mcp.json with cclsp MCP server"
else
  # Check if cclsp is already configured
  if grep -q '"cclsp"' .mcp.json 2>/dev/null; then
    echo "cclsp already configured in .mcp.json"
  else
    echo ""
    echo "WARNING: .mcp.json exists but cclsp not configured"
    echo "Add manually with: claude mcp add --transport stdio cclsp -- npx -y cclsp"
  fi
fi
```

**Display final tool status:**

```bash
echo ""
echo "Tool availability for Phase 3.5 (Context Compilation):"
echo ""

if gem list solargraph -i &>/dev/null; then
  echo "  Solargraph: Available"
  echo "    - LSP diagnostics via cclsp"
  echo "    - Interface extraction"
  echo "    - Method signature lookup"
else
  echo "  Solargraph: Not available"
fi

if gem list sorbet -i &>/dev/null || command -v srb &>/dev/null; then
  echo "  Sorbet: Available"
  echo "    - Static type checking"
  echo "    - Guardian validation"
else
  echo "  Sorbet: Not available"
fi

if gem list parser -i &>/dev/null; then
  echo "  parser: Available"
  echo "    - AST analysis"
else
  echo "  parser: Not available (using ripper fallback)"
fi

echo ""
```

## Phase 3: Generate Configuration File

Create or update `.claude/reactree-rails-dev.local.md`:

```markdown
---
smart_detection_enabled: true
detection_mode: suggest
annoyance_threshold: medium
---

# ReAcTree Configuration

This file was generated by `/reactree-init`.

## Settings

- **smart_detection_enabled**: Enable auto-triggering based on prompt analysis
- **detection_mode**: `suggest` (show suggestions) | `inject` (auto-activate) | `disabled`
- **annoyance_threshold**: `low` (minimal triggers) | `medium` | `high` (frequent triggers)

## Available Skills

<!-- Auto-populated by skill discovery -->
```

Then scan and categorize skills:

```bash
# Scan skills and categorize
for skill_dir in .claude/skills/*/; do
  skill_name=$(basename "$skill_dir")
  echo "Found skill: $skill_name"
done
```

Categorize skills into:
- **Core**: rails-conventions, rails-error-prevention, codebase-inspection, rails-context-verification
- **Data**: activerecord-patterns
- **Service**: service-object-patterns, sidekiq-async-patterns, api-development-patterns
- **UI**: hotwire-patterns, viewcomponents-specialist, tailadmin-patterns
- **Testing**: rspec-testing-patterns
- **Domain**: localization, requirements-writing, ruby-oop-patterns
- **Plugin**: reactree-patterns, smart-detection, skill-discovery, workflow-orchestration, beads-integration

## Phase 4: Initialize Memory Files

Create memory files if they don't exist:

```bash
# Working memory
if [ ! -f .claude/reactree-memory.jsonl ]; then
  touch .claude/reactree-memory.jsonl
  echo '{"initialized": true, "timestamp": "'$(date -Iseconds)'"}' >> .claude/reactree-memory.jsonl
fi

# Episodic memory
if [ ! -f .claude/reactree-episodes.jsonl ]; then
  touch .claude/reactree-episodes.jsonl
fi

# Feedback state
if [ ! -f .claude/reactree-feedback.jsonl ]; then
  touch .claude/reactree-feedback.jsonl
fi

# Control flow state
if [ ! -f .claude/reactree-state.jsonl ]; then
  touch .claude/reactree-state.jsonl
fi
```

## Phase 5: Status Report

After completing all phases, output a comprehensive status report:

```
🚀 ReAcTree Plugin Initialized!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Prerequisites:
  ✅ Plugin located at: $PLUGIN_ROOT
  ✅ Hooks configured (SessionStart, UserPromptSubmit)
  ✅ Scripts executable

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Skills Discovered (X total):
  📦 Core: [list skills]
  💾 Data: [list skills]
  ⚙️ Service: [list skills]
  🎨 UI: [list skills]
  🧪 Testing: [list skills]
  🌐 Domain: [list skills]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration:
  ✅ Config file: .claude/reactree-rails-dev.local.md
  📊 Smart Detection: ENABLED (suggest mode)
  🎚️ Annoyance Threshold: medium

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MCP Servers:
  ✅ cclsp: Configured in .mcp.json
  📝 Note: First use requires approval (project-scoped MCP servers)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ruby Analysis Tools:
  [Shows Solargraph/Sorbet/parser status from Phase 2.5]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Rules System:
  ✅ Rules directory: .claude/rules/
  📁 Rule categories: rails, frontend, testing, database, quality-gates
  📄 Total rules: [count from Phase 2.6]
  💡 Path-specific rules automatically load based on file type

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Memory Initialized:
  ✅ Working memory: .claude/reactree-memory.jsonl
  ✅ Episodic memory: .claude/reactree-episodes.jsonl
  ✅ Feedback state: .claude/reactree-feedback.jsonl
  ✅ Control flow state: .claude/reactree-state.jsonl

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Available Commands:
  /reactree-dev      - Full development workflow with parallel execution
  /reactree-feature  - Feature-driven development with user stories
  /reactree-debug    - Systematic debugging workflow
  /reactree-refactor - Safe refactoring with test preservation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Auto-Triggering Examples:
  "Add user authentication"     → suggests /reactree-dev
  "Fix the payment bug"         → suggests /reactree-debug
  "Refactor the user service"   → suggests /reactree-refactor
  "Find payment controller"     → routes to file-finder agent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready to use! Try one of the commands above or just describe what you want to build.
```

## Error Handling

If any phase fails, provide clear error messages:

### Plugin Location Not Detected
```
❌ Plugin Location Not Detected

The CLAUDE_PLUGIN_ROOT environment variable is not set and no local
plugin installation was found at .claude/plugins/reactree-rails-dev/

This usually means:
  1. The plugin is not properly installed
  2. The plugin was installed but Claude Code isn't setting the root path

To install locally:
  mkdir -p .claude/plugins
  cp -r /path/to/reactree-rails-dev .claude/plugins/

Or install via Claude Code marketplace:
  /install-plugin reactree-rails-dev
```

### Hooks Not Configured
```
⚠️ Hooks Configuration Issue

hooks.json not found or invalid at:
  $PLUGIN_ROOT/hooks/hooks.json

This may prevent auto-triggering from working.
The plugin will still work with manual /reactree-* commands.
```

### Scripts Not Executable
```
⚠️ Scripts Need Execute Permission

Run these commands to fix:
  chmod +x "$PLUGIN_ROOT/hooks/scripts/"*.sh
```

## Idempotent Design

This command is safe to run multiple times:
- Existing config file is preserved (not overwritten)
- Memory files are created only if missing
- Skills are only copied if directory is empty
- Status report always shows current state
