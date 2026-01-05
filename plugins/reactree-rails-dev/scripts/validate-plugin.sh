#!/bin/bash
# Plugin validation script for reactree-rails-dev
# Validates plugin structure, manifests, frontmatter, and configuration
#
# Usage: bash scripts/validate-plugin.sh
# Exit codes: 0 = success, 1 = validation errors found

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

echo "🔍 ReAcTree Rails Dev Plugin Validation"
echo "========================================"
echo ""

#==============================================================================
# 1. Validate plugin.json syntax and required fields
#==============================================================================

echo "📦 Validating plugin.json..."

if [ ! -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
  echo -e "${RED}❌ Missing: .claude-plugin/plugin.json${NC}"
  ((errors++))
else
  # Test JSON syntax
  if ! cat "$PLUGIN_ROOT/.claude-plugin/plugin.json" | python3 -m json.tool > /dev/null 2>&1; then
    echo -e "${RED}❌ Invalid JSON syntax in plugin.json${NC}"
    ((errors++))
  else
    echo -e "${GREEN}✅ Valid JSON syntax${NC}"

    # Check required fields
    for field in name version description author license; do
      if ! grep -q "\"$field\"" "$PLUGIN_ROOT/.claude-plugin/plugin.json"; then
        echo -e "${RED}❌ Missing required field: $field${NC}"
        ((errors++))
      fi
    done

    # Check optional but recommended fields
    for field in keywords repository; do
      if ! grep -q "\"$field\"" "$PLUGIN_ROOT/.claude-plugin/plugin.json"; then
        echo -e "${YELLOW}⚠️  Missing recommended field: $field${NC}"
        ((warnings++))
      fi
    done

    echo -e "${GREEN}✅ All required fields present${NC}"
  fi
fi

echo ""

#==============================================================================
# 2. Validate agent frontmatter
#==============================================================================

echo "🤖 Validating agent frontmatter..."

agent_count=0
agents_missing_name=0
agents_missing_model=0
agents_missing_color=0
agents_missing_tools=0
agents_missing_skills=0

if [ -d "$PLUGIN_ROOT/agents" ]; then
  for agent in "$PLUGIN_ROOT/agents"/*.md; do
    [ -f "$agent" ] || continue
    ((agent_count++))

    agent_name=$(basename "$agent")

    # Extract first 30 lines (frontmatter area)
    frontmatter=$(head -30 "$agent")

    # Check required fields
    if ! echo "$frontmatter" | grep -q "^name:"; then
      echo -e "${RED}❌ $agent_name: Missing 'name:' field${NC}"
      ((agents_missing_name++))
      ((errors++))
    fi

    if ! echo "$frontmatter" | grep -q "^model:"; then
      echo -e "${RED}❌ $agent_name: Missing 'model:' field${NC}"
      ((agents_missing_model++))
      ((errors++))
    fi

    if ! echo "$frontmatter" | grep -q "^color:"; then
      echo -e "${YELLOW}⚠️  $agent_name: Missing 'color:' field${NC}"
      ((agents_missing_color++))
      ((warnings++))
    fi

    if ! echo "$frontmatter" | grep -q "^tools:"; then
      echo -e "${RED}❌ $agent_name: Missing 'tools:' field${NC}"
      ((agents_missing_tools++))
      ((errors++))
    fi

    if ! echo "$frontmatter" | grep -q "^skills:"; then
      echo -e "${YELLOW}⚠️  $agent_name: Missing 'skills:' field${NC}"
      ((agents_missing_skills++))
      ((warnings++))
    fi
  done

  if [ $agents_missing_name -eq 0 ] && [ $agents_missing_model -eq 0 ] && \
     [ $agents_missing_tools -eq 0 ] && [ $agents_missing_skills -eq 0 ]; then
    echo -e "${GREEN}✅ All $agent_count agents have complete frontmatter${NC}"
  else
    echo -e "${YELLOW}⚠️  Found $agent_count agents, some missing fields${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No agents/ directory found${NC}"
  ((warnings++))
fi

echo ""

#==============================================================================
# 3. Validate skill frontmatter
#==============================================================================

echo "📚 Validating skill frontmatter..."

skill_count=0
skills_missing_name=0
skills_missing_description=0

if [ -d "$PLUGIN_ROOT/skills" ]; then
  for skill_dir in "$PLUGIN_ROOT/skills"/*/; do
    [ -d "$skill_dir" ] || continue

    skill_file="${skill_dir}SKILL.md"

    if [ ! -f "$skill_file" ]; then
      echo -e "${RED}❌ Missing SKILL.md in $(basename "$skill_dir")${NC}"
      ((errors++))
      continue
    fi

    ((skill_count++))
    skill_name=$(basename "$skill_dir")

    # Extract first 15 lines (frontmatter area)
    frontmatter=$(head -15 "$skill_file")

    if ! echo "$frontmatter" | grep -q "^name:"; then
      echo -e "${YELLOW}⚠️  $skill_name: Missing 'name:' field${NC}"
      ((skills_missing_name++))
      ((warnings++))
    fi

    if ! echo "$frontmatter" | grep -q "^description:"; then
      echo -e "${YELLOW}⚠️  $skill_name: Missing 'description:' field${NC}"
      ((skills_missing_description++))
      ((warnings++))
    fi
  done

  if [ $skills_missing_name -eq 0 ] && [ $skills_missing_description -eq 0 ]; then
    echo -e "${GREEN}✅ All $skill_count skills have proper frontmatter${NC}"
  else
    echo -e "${YELLOW}⚠️  Found $skill_count skills, some missing fields${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No skills/ directory found${NC}"
  ((warnings++))
fi

echo ""

#==============================================================================
# 4. Validate hook scripts are executable
#==============================================================================

echo "🪝 Validating hook scripts..."

hook_count=0
non_executable=0

if [ -d "$PLUGIN_ROOT/hooks/scripts" ]; then
  for script in "$PLUGIN_ROOT/hooks/scripts"/*.sh; do
    [ -f "$script" ] || continue
    ((hook_count++))

    if [ ! -x "$script" ]; then
      echo -e "${YELLOW}⚠️  Script not executable: $(basename "$script")${NC}"
      ((non_executable++))
      ((warnings++))
    fi
  done

  if [ $non_executable -eq 0 ]; then
    echo -e "${GREEN}✅ All $hook_count hook scripts are executable${NC}"
  else
    echo -e "${YELLOW}⚠️  $non_executable/$hook_count scripts not executable${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No hooks/scripts/ directory found${NC}"
  ((warnings++))
fi

echo ""

#==============================================================================
# 5. Validate hooks.json syntax
#==============================================================================

echo "⚙️  Validating hooks.json..."

if [ -f "$PLUGIN_ROOT/hooks/hooks.json" ]; then
  if ! cat "$PLUGIN_ROOT/hooks/hooks.json" | python3 -m json.tool > /dev/null 2>&1; then
    echo -e "${RED}❌ Invalid JSON syntax in hooks.json${NC}"
    ((errors++))
  else
    echo -e "${GREEN}✅ Valid hooks.json syntax${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No hooks/hooks.json found${NC}"
  ((warnings++))
fi

echo ""

#==============================================================================
# 6. Check version consistency
#==============================================================================

echo "🔢 Checking version consistency..."

plugin_version=$(grep '"version"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" | sed 's/.*"version": *"\([^"]*\)".*/\1/')

if [ -f "$PLUGIN_ROOT/hooks/scripts/discover-skills.sh" ]; then
  script_version=$(grep 'PLUGIN_VERSION=' "$PLUGIN_ROOT/hooks/scripts/discover-skills.sh" | head -1 | sed 's/.*PLUGIN_VERSION="\([^"]*\)".*/\1/')

  if [ "$plugin_version" != "$script_version" ]; then
    echo -e "${RED}❌ Version mismatch: plugin.json ($plugin_version) vs discover-skills.sh ($script_version)${NC}"
    ((errors++))
  else
    echo -e "${GREEN}✅ Version consistent across files: $plugin_version${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  Could not verify version in discover-skills.sh${NC}"
  ((warnings++))
fi

echo ""

#==============================================================================
# 7. Directory structure validation
#==============================================================================

echo "📁 Validating directory structure..."

required_dirs=(".claude-plugin" "agents" "commands" "skills" "hooks")
missing_dirs=0

for dir in "${required_dirs[@]}"; do
  if [ ! -d "$PLUGIN_ROOT/$dir" ]; then
    echo -e "${RED}❌ Missing required directory: $dir/${NC}"
    ((missing_dirs++))
    ((errors++))
  fi
done

if [ $missing_dirs -eq 0 ]; then
  echo -e "${GREEN}✅ All required directories present${NC}"
fi

echo ""

#==============================================================================
# Summary
#==============================================================================

echo "========================================"
echo "📊 Validation Summary"
echo "========================================"
echo ""

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
  echo -e "${GREEN}✅ Perfect! No errors or warnings found.${NC}"
  echo ""
  echo "Plugin structure is valid and ready for distribution."
  exit 0
elif [ $errors -eq 0 ]; then
  echo -e "${YELLOW}⚠️  $warnings warning(s) found (non-critical)${NC}"
  echo -e "${GREEN}✅ 0 errors${NC}"
  echo ""
  echo "Plugin is valid but could be improved."
  exit 0
else
  echo -e "${RED}❌ $errors error(s) found${NC}"
  echo -e "${YELLOW}⚠️  $warnings warning(s) found${NC}"
  echo ""
  echo "Please fix the errors before distributing the plugin."
  exit 1
fi
