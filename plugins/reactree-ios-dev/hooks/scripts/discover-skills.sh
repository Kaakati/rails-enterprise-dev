#!/bin/bash
# Discover skills and initialize ReAcTree memory systems for iOS/tvOS
# Runs on SessionStart hook
#
# NOTE: We intentionally DO NOT use set -e here because:
# 1. Hooks should fail gracefully, not crash
# 2. Missing files/directories are expected in some cases
# 3. We want to provide helpful messages, not silent failures

SKILLS_DIR=".claude/skills"
PLUGIN_SKILLS_DIR="${CLAUDE_PLUGIN_ROOT}/skills"
CONFIG_FILE=".claude/reactree-ios-dev.local.md"
MEMORY_FILE=".claude/reactree-memory.jsonl"
LOG_FILE=".claude/reactree-init.log"
PLUGIN_VERSION="2.0.0"

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
  log_message "INFO" "Run /reactree-ios-init to set up the plugin for this project"

  # Create minimal config to indicate plugin needs initialization
  mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
  if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" <<EOF
---
initialized: false
needs_setup: true
smart_detection_enabled: false
---

# ReAcTree iOS/tvOS Plugin - Needs Initialization

Run \`/reactree-ios-init\` to complete setup.

This will:
1. Set up the skills directory
2. Configure smart detection
3. Initialize memory systems
EOF
    log_message "INFO" "Created placeholder config - awaiting /reactree-ios-init"
  fi

  exit 0
fi

log_message "INFO" "Found skills directory at $SKILLS_DIR"

# Initialize skill categories for iOS/tvOS
declare -A SKILLS
SKILLS[core]=""
SKILLS[networking]=""
SKILLS[ui]=""
SKILLS[data]=""
SKILLS[state]=""
SKILLS[navigation]=""
SKILLS[testing]=""
SKILLS[quality]=""
SKILLS[platform]=""
SKILLS[domain]=""

# Scan skills directory
for skill_dir in "$SKILLS_DIR"/*; do
  if [ ! -d "$skill_dir" ]; then
    continue
  fi

  skill_name=$(basename "$skill_dir")
  category="domain"

  # Categorize based on iOS/tvOS naming patterns
  case "$skill_name" in
    *swift-convention*|*mvvm-architecture*|*clean-architecture*|*error-prevention*)
      category="core" ;;
    *alamofire*|*networking*|*api*|*http*|*network*)
      category="networking" ;;
    *swiftui*|*view*|*design-system*|*atomic-design*|*component*|*ui*|*theme*|*accessibility*|*user-experience*)
      category="ui" ;;
    *model*|*codable*|*core-data*|*persistence*|*database*)
      category="data" ;;
    *state*|*observable*|*published*|*combine*|*concurrency*|*async*)
      category="state" ;;
    *navigation*|*routing*|*coordinator*|*deep-link*)
      category="navigation" ;;
    *xctest*|*test*|*spec*|*quality-gate*)
      category="testing" ;;
    *swiftlint*|*swiftgen*|*code-quality*|*performance*|*security*)
      category="quality" ;;
    *tvos*|*ios*|*platform*|*focus*|*session*|*push-notification*|*app-lifecycle*)
      category="platform" ;;
  esac

  if [ -n "${SKILLS[$category]}" ]; then
    SKILLS[$category]="${SKILLS[$category]}, $skill_name"
  else
    SKILLS[$category]="$skill_name"
  fi
done

#==============================================================================
# 2. DETECT XCODE PROJECT INFO
#==============================================================================

XCODE_PROJECT=$(find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) 2>/dev/null | head -1)
PROJECT_NAME=""
PLATFORM="iOS"
SWIFT_VERSION="Unknown"

if [ -n "$XCODE_PROJECT" ]; then
  PROJECT_NAME=$(basename "$XCODE_PROJECT" | sed 's/\.\(xcodeproj\|xcworkspace\)$//')

  # Detect platform (iOS vs tvOS)
  if find . -name "Info.plist" -type f -print0 2>/dev/null | xargs -0 grep -l "UIDeviceFamily.*3" >/dev/null 2>&1; then
    PLATFORM="tvOS"
  fi

  # Detect Swift version
  if command -v swift >/dev/null 2>&1; then
    SWIFT_VERSION=$(swift --version 2>/dev/null | head -1 | sed 's/.*Swift version \([0-9.]*\).*/\1/')
  fi
fi

#==============================================================================
# 3. CREATE/UPDATE CONFIGURATION FILE
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
test_coverage_threshold: 80

# Memory settings
working_memory_enabled: true
episodic_memory_enabled: true

# Skill inventory (auto-populated)
available_skills:
  core: [${SKILLS[core]}]
  networking: [${SKILLS[networking]}]
  ui: [${SKILLS[ui]}]
  data: [${SKILLS[data]}]
  state: [${SKILLS[state]}]
  navigation: [${SKILLS[navigation]}]
  testing: [${SKILLS[testing]}]
  quality: [${SKILLS[quality]}]
  platform: [${SKILLS[platform]}]
  domain: [${SKILLS[domain]}]

# Automation
auto_commit: false
auto_create_pr: false

# Platform info
platform: $PLATFORM
swift_version: $SWIFT_VERSION
---

# ReAcTree iOS/tvOS Development Configuration

**Project**: ${PROJECT_NAME:-$(basename "$(pwd)")}
**Skills Discovered**: $(date)
**Plugin Version**: $PLUGIN_VERSION
**Platform**: $PLATFORM
**Swift Version**: $SWIFT_VERSION

## Smart Detection

Smart detection analyzes your prompts and suggests appropriate workflows:

- **Feature requests** -> /ios-dev or /ios-feature
- **Debugging tasks** -> /ios-debug
- **Refactoring tasks** -> /ios-refactor
- **TDD requests** -> test-first mode

### Utility Agents

The plugin also routes to specialized utility agents:

- **file-finder** - Find Swift files by pattern or name
- **log-analyzer** - Parse Xcode build logs and crash reports

### Configuration Options

- \`smart_detection_enabled\`: Enable/disable smart detection (default: true)
- \`detection_mode\`:
  - \`suggest\` - Show suggestion message (default)
  - \`inject\` - Automatically inject workflow context
  - \`disabled\` - Turn off smart detection
- \`annoyance_threshold\`:
  - \`low\` - Only trigger for very explicit requests
  - \`medium\` - Skip simple questions (default)
  - \`high\` - Trigger for most iOS/tvOS-related prompts

## Memory Systems

- Working memory: \`.claude/reactree-memory.jsonl\`
- Episodic memory: \`.claude/reactree-episodes.jsonl\`
- Feedback queue: \`.claude/reactree-feedback.jsonl\`
- Control flow state: \`.claude/reactree-state.jsonl\`

Plugin active and ready.
EOF

#==============================================================================
# 4. INITIALIZE WORKING MEMORY (if enabled and not exists)
#==============================================================================

if [ ! -f "$MEMORY_FILE" ]; then
  touch "$MEMORY_FILE"

  # Build skills list for JSON
  all_skills=""
  for category in core networking ui data state navigation testing quality platform domain; do
    if [ -n "${SKILLS[$category]}" ]; then
      if [ -n "$all_skills" ]; then
        all_skills="$all_skills, "
      fi
      all_skills="$all_skills${SKILLS[$category]}"
    fi
  done

  cat >> "$MEMORY_FILE" <<EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","agent":"system","knowledge_type":"initialization","key":"session.start","value":{"project":"${PROJECT_NAME:-$(basename "$(pwd)")}","plugin_version":"$PLUGIN_VERSION","smart_detection":"enabled","platform":"$PLATFORM","swift_version":"$SWIFT_VERSION"},"confidence":"verified"}
EOF
fi

log_message "INFO" "Initialization complete - plugin version $PLUGIN_VERSION, platform $PLATFORM"
exit 0
