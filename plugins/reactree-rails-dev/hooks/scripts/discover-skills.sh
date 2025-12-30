#!/bin/bash
# Discover skills and initialize ReAcTree memory systems
# Runs on SessionStart hook
#
# NOTE: We intentionally DO NOT use set -e here because:
# 1. Hooks should fail gracefully, not crash
# 2. Missing files/directories are expected in some cases
# 3. We want to provide helpful messages, not silent failures

SKILLS_DIR=".claude/skills"
PLUGIN_SKILLS_DIR="${CLAUDE_PLUGIN_ROOT}/skills"
CONFIG_FILE=".claude/reactree-rails-dev.local.md"
MEMORY_FILE=".claude/reactree-memory.jsonl"
LOG_FILE=".claude/reactree-init.log"
PLUGIN_VERSION="2.4.0"

#==============================================================================
# 0. LOGGING HELPER
#==============================================================================

log_message() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Ensure .claude directory exists
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

  echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}

#==============================================================================
# 1. SKILL DISCOVERY
#==============================================================================

log_message "INFO" "SessionStart hook triggered for project: $(basename "$(pwd)")"

# Check if skills directory exists
if [ ! -d "$SKILLS_DIR" ]; then
  log_message "WARN" "Skills directory not found at $SKILLS_DIR"
  log_message "INFO" "Run /reactree-init to set up the plugin for this project"

  # Create minimal config to indicate plugin needs initialization
  mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
  if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" <<EOF
---
initialized: false
needs_setup: true
smart_detection_enabled: false
---

# ReAcTree Plugin - Needs Initialization

Run \`/reactree-init\` to complete setup.

This will:
1. Set up the skills directory
2. Configure smart detection
3. Initialize memory systems
EOF
    log_message "INFO" "Created placeholder config - awaiting /reactree-init"
  fi

  exit 0
fi

log_message "INFO" "Found skills directory at $SKILLS_DIR"

# Initialize skill categories
declare -A SKILLS
SKILLS[core]=""
SKILLS[data]=""
SKILLS[service]=""
SKILLS[async]=""
SKILLS[ui]=""
SKILLS[i18n]=""
SKILLS[testing]=""
SKILLS[infrastructure]=""
SKILLS[requirements]=""
SKILLS[domain]=""

# Scan skills directory
for skill_dir in "$SKILLS_DIR"/*; do
  if [ ! -d "$skill_dir" ]; then
    continue
  fi

  skill_name=$(basename "$skill_dir")
  category="domain"

  # Categorize based on naming patterns
  case "$skill_name" in
    *convention*|*error-prevention*|*codebase-inspection*)
      category="core" ;;
    *activerecord*|*model*|*database*|*schema*)
      category="data" ;;
    *service*|*api*)
      category="service" ;;
    *sidekiq*|*async*|*job*|*queue*)
      category="async" ;;
    *component*|*view*|*hotwire*|*turbo*|*stimulus*|*tailadmin*|*ui*|*frontend*)
      category="ui" ;;
    *i18n*|*localization*|*translation*)
      category="i18n" ;;
    *rspec*|*test*|*spec*)
      category="testing" ;;
    *devops*|*deploy*|*infrastructure*)
      category="infrastructure" ;;
    *requirement*|*documentation*)
      category="requirements" ;;
  esac

  if [ -n "${SKILLS[$category]}" ]; then
    SKILLS[$category]="${SKILLS[$category]}, $skill_name"
  else
    SKILLS[$category]="$skill_name"
  fi
done

#==============================================================================
# 2. CREATE/UPDATE CONFIGURATION FILE
#==============================================================================

mkdir -p "$(dirname "$CONFIG_FILE")"

cat > "$CONFIG_FILE" <<EOF
---
enabled: true
feature_id: null
workflow_phase: idle

# Smart Detection Configuration
smart_detection_enabled: true
detection_mode: suggest
annoyance_threshold: medium

# Quality control
quality_gates_enabled: true
test_coverage_threshold: 85

# Memory settings
working_memory_enabled: true
episodic_memory_enabled: true

# Skill inventory (auto-populated)
available_skills:
  core: [${SKILLS[core]}]
  data: [${SKILLS[data]}]
  service: [${SKILLS[service]}]
  async: [${SKILLS[async]}]
  ui: [${SKILLS[ui]}]
  i18n: [${SKILLS[i18n]}]
  testing: [${SKILLS[testing]}]
  infrastructure: [${SKILLS[infrastructure]}]
  requirements: [${SKILLS[requirements]}]
  domain: [${SKILLS[domain]}]

# Automation
auto_commit: false
auto_create_pr: false
---

# ReAcTree Rails Development Configuration

**Project**: $(basename "$(pwd)")
**Skills Discovered**: $(date)
**Plugin Version**: $PLUGIN_VERSION

## Smart Detection

Smart detection analyzes your prompts and suggests appropriate workflows:

- **Feature requests** -> /reactree-dev or /reactree-feature
- **Debugging tasks** -> /reactree-debug
- **Refactoring tasks** -> /reactree-dev with refactor focus
- **TDD requests** -> /reactree-feature with test-first mode

### Utility Agents

The plugin also routes to specialized utility agents:

- **file-finder** - Find files by pattern or name
- **code-line-finder** - Find method definitions and usages
- **git-diff-analyzer** - Analyze changes and git history
- **log-analyzer** - Parse Rails server logs

### Configuration Options

- \`smart_detection_enabled\`: Enable/disable smart detection (default: true)
- \`detection_mode\`:
  - \`suggest\` - Show suggestion message (default)
  - \`inject\` - Automatically inject workflow context
  - \`disabled\` - Turn off smart detection
- \`annoyance_threshold\`:
  - \`low\` - Only trigger for very explicit requests
  - \`medium\` - Skip simple questions (default)
  - \`high\` - Trigger for most Rails-related prompts

## Memory Systems

- Working memory: \`.claude/reactree-memory.jsonl\`
- Episodic memory: \`.claude/reactree-episodes.jsonl\`
- Feedback queue: \`.claude/reactree-feedback.jsonl\`

Plugin active and ready.
EOF

#==============================================================================
# 3. INITIALIZE WORKING MEMORY (if enabled and not exists)
#==============================================================================

if [ ! -f "$MEMORY_FILE" ]; then
  touch "$MEMORY_FILE"

  # Build skills list for JSON
  all_skills=""
  for category in core data service async ui i18n testing infrastructure requirements domain; do
    if [ -n "${SKILLS[$category]}" ]; then
      if [ -n "$all_skills" ]; then
        all_skills="$all_skills, "
      fi
      all_skills="$all_skills${SKILLS[$category]}"
    fi
  done

  cat >> "$MEMORY_FILE" <<EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","agent":"system","knowledge_type":"initialization","key":"session.start","value":{"project":"$(basename "$(pwd)")","plugin_version":"$PLUGIN_VERSION","smart_detection":"enabled"},"confidence":"verified"}
EOF
fi

log_message "INFO" "Initialization complete - plugin version $PLUGIN_VERSION"
exit 0
