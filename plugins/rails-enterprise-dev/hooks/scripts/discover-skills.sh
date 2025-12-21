#!/bin/bash
# Discover available skills in project and categorize them
set -e

SKILLS_DIR=".claude/skills"
STATE_FILE=".claude/rails-enterprise-dev.local.md"

# Exit if skills directory doesn't exist
if [ ! -d "$SKILLS_DIR" ]; then
  exit 0
fi

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
  category="domain"  # Default to domain

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

  # Add to category
  if [ -n "${SKILLS[$category]}" ]; then
    SKILLS[$category]="${SKILLS[$category]}, $skill_name"
  else
    SKILLS[$category]="$skill_name"
  fi
done

# Create/update state file with skill inventory
cat > "$STATE_FILE" <<EOF
---
enabled: true
feature_id: null
workflow_phase: idle

# Quality control
quality_gates_enabled: true
test_coverage_threshold: 90

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

# Rails Enterprise Development Configuration

**Project**: $(basename "$(pwd)")
**Skills Discovered**: $(date)

Plugin active and ready.
EOF

# Output success (silent to avoid cluttering)
exit 0
