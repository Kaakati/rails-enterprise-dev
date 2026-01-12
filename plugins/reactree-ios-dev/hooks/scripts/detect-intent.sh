#!/bin/bash
# Smart Intent Detection for ReAcTree iOS/tvOS Development
# Analyzes user prompts and suggests appropriate workflows or utility agents
#
# NOTE: We intentionally DO NOT use set -e here because:
# 1. Hooks should fail gracefully, not crash
# 2. Missing config files are expected on first run
# 3. jq parsing errors should not kill the hook
# 4. We want silent exit, not error propagation

# Get script directory for sourcing patterns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read hook input (JSON from stdin)
input=$(cat 2>/dev/null || echo '{}')

# Extract user prompt with error handling
user_prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null || echo "")

# Quick exit if empty prompt or jq failed
if [ -z "$user_prompt" ]; then
  exit 0
fi

# Configuration file location
CONFIG_FILE=".claude/reactree-ios-dev.local.md"

#==============================================================================
# 1. CHECK IF SMART DETECTION ENABLED
#==============================================================================

SMART_DETECTION_ENABLED="true"
DETECTION_MODE="suggest"
ANNOYANCE_THRESHOLD="medium"

if [ -f "$CONFIG_FILE" ]; then
  SMART_DETECTION_ENABLED=$(sed -n '/^---$/,/^---$/{ /^smart_detection_enabled:/p }' "$CONFIG_FILE" 2>/dev/null | sed 's/smart_detection_enabled: *//' | tr -d ' ')
  DETECTION_MODE=$(sed -n '/^---$/,/^---$/{ /^detection_mode:/p }' "$CONFIG_FILE" 2>/dev/null | sed 's/detection_mode: *//' | tr -d ' ')
  ANNOYANCE_THRESHOLD=$(sed -n '/^---$/,/^---$/{ /^annoyance_threshold:/p }' "$CONFIG_FILE" 2>/dev/null | sed 's/annoyance_threshold: *//' | tr -d ' ')

  SMART_DETECTION_ENABLED=${SMART_DETECTION_ENABLED:-true}
  DETECTION_MODE=${DETECTION_MODE:-suggest}
  ANNOYANCE_THRESHOLD=${ANNOYANCE_THRESHOLD:-medium}
fi

if [ "$SMART_DETECTION_ENABLED" = "false" ] || [ "$DETECTION_MODE" = "disabled" ]; then
  exit 0
fi

#==============================================================================
# 2. SOURCE INTENT PATTERNS (if available)
#==============================================================================

if [ -f "$SCRIPT_DIR/shared/ios-patterns.sh" ]; then
  # Source with error suppression - patterns are optional enhancements
  source "$SCRIPT_DIR/shared/ios-patterns.sh" 2>/dev/null || true
fi

#==============================================================================
# 3. CHECK FOR EXPLICIT COMMAND INVOCATION (skip detection)
#==============================================================================

if echo "$user_prompt" | grep -qiE '^/ios-|^/reactree-ios'; then
  exit 0
fi

#==============================================================================
# 4. HELPER FUNCTIONS
#==============================================================================

prompt_lower=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]')

is_simple_question() {
  local word_count=$(echo "$user_prompt" | wc -w | tr -d ' ')
  if [ "$word_count" -lt 5 ]; then
    return 0
  fi

  if echo "$prompt_lower" | grep -qE '^(what|how|why|when|where|who|which|is|are|can|could|would|should|do|does|did|explain|tell me|describe|show me|help me understand)'; then
    if echo "$prompt_lower" | grep -qvE '(implement|build|create|add|fix|debug|refactor|update|change|modify)'; then
      return 0
    fi
  fi

  if echo "$prompt_lower" | grep -qE '(difference between|meaning of|example of|documentation|syntax|reference|definition)'; then
    return 0
  fi

  return 1
}

is_ios_related() {
  # Check for iOS/tvOS-specific keywords
  if echo "$prompt_lower" | grep -qiE 'swift|swiftui|uikit|xcode|cocoapods|spm|viewmodel|view model|@published|@state|@binding|@environment|navigationstack|avkit|avfoundation'; then
    return 0
  fi

  # Check for iOS/tvOS framework references
  if echo "$prompt_lower" | grep -qiE 'alamofire|combine|core data|userdefaults|keychain|urlsession|json|codable'; then
    return 0
  fi

  # Check for iOS/tvOS architecture patterns
  if echo "$prompt_lower" | grep -qiE 'mvvm|clean architecture|coordinator|repository|service layer'; then
    return 0
  fi

  # Check for iOS file paths
  if echo "$prompt_lower" | grep -qiE '\.swift|sources/|tests/|resources/|\.xcodeproj|\.xcworkspace'; then
    return 0
  fi

  # Check for platform-specific patterns
  if echo "$prompt_lower" | grep -qiE 'ios|tvos|iphone|ipad|apple tv|focus|@focusstate|remote control|top shelf'; then
    return 0
  fi

  # Check if Xcode project exists in current directory
  if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) 2>/dev/null | grep -q .; then
    return 0
  fi

  return 1
}

#==============================================================================
# 5. APPLY ANNOYANCE THRESHOLD
#==============================================================================

case "$ANNOYANCE_THRESHOLD" in
  "low")
    if ! echo "$prompt_lower" | grep -qiE '(implement|build|create|fix|debug|refactor)'; then
      exit 0
    fi
    ;;
  "medium")
    if is_simple_question; then
      exit 0
    fi
    ;;
  "high")
    ;;
esac

#==============================================================================
# 6. DETECT UTILITY AGENT INTENT (check first - more specific)
#==============================================================================

detect_utility_agent() {
  local score=0
  local agent=""

  # FILE FINDER patterns
  if echo "$prompt_lower" | grep -qiE 'find .* file|find all .* files|where is .* file|locate .* file|list .* files|show .* files|what files'; then
    agent="file-finder"
    score=5
  elif echo "$prompt_lower" | grep -qiE 'what.s in .* directory|show .* folder|list .* directory'; then
    agent="file-finder"
    score=5
  elif echo "$prompt_lower" | grep -qiE 'find .* view|find .* viewmodel|find .* service|find .* manager|find .* model|find .* component|find .* test'; then
    agent="file-finder"
    score=4
  fi

  # LOG ANALYZER patterns (Xcode-specific)
  if echo "$prompt_lower" | grep -qiE 'xcode .* log|build .* log|crash .* log|crash report|symbolicate'; then
    agent="log-analyzer"
    score=6
  elif echo "$prompt_lower" | grep -qiE 'show .* log|check .* log|read .* log|view .* log|console log'; then
    agent="log-analyzer"
    score=5
  elif echo "$prompt_lower" | grep -qiE 'build errors?|build warnings?|compilation errors?|linker errors?'; then
    agent="log-analyzer"
    score=5
  elif echo "$prompt_lower" | grep -qiE 'crash at startup|app crashes|thread .* crashed|exception type'; then
    agent="log-analyzer"
    score=4
  fi

  echo "${agent}|${score}"
}

#==============================================================================
# 7. DETECT WORKFLOW INTENT
#==============================================================================

detect_workflow_intent() {
  local feature_score=0
  local debug_score=0
  local refactor_score=0
  local tdd_score=0

  # FEATURE DETECTION
  if echo "$prompt_lower" | grep -qiE 'add|implement|build|create|develop|make|generate|set up|introduce'; then
    feature_score=$((feature_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'new feature|feature request|user can|users should|ability to'; then
    feature_score=$((feature_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE '^(as a|i want|so that|user story|feature:|acceptance criteria)'; then
    feature_score=$((feature_score + 5))
  fi
  # iOS/tvOS-specific feature patterns
  if echo "$prompt_lower" | grep -qiE 'authentication|login|sign in|biometric|face id|touch id'; then
    feature_score=$((feature_score + 1))
  fi
  if echo "$prompt_lower" | grep -qiE 'api integration|rest api|graphql|network|fetch|upload|download'; then
    feature_score=$((feature_score + 1))
  fi
  if echo "$prompt_lower" | grep -qiE 'video player|media player|avkit|streaming'; then
    feature_score=$((feature_score + 1))
  fi

  # DEBUG DETECTION
  if echo "$prompt_lower" | grep -qiE 'fix|debug|troubleshoot|diagnose|investigate|resolve|repair'; then
    debug_score=$((debug_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'error|bug|issue|problem|broken|not working|failing|fails|crash'; then
    debug_score=$((debug_score + 2))
  fi
  # iOS/tvOS-specific errors
  if echo "$prompt_lower" | grep -qiE 'exc_bad_access|sigabrt|sigsegv|fatal error|precondition failed'; then
    debug_score=$((debug_score + 5))
  fi
  if echo "$prompt_lower" | grep -qiE 'unexpectedly found nil|force unwrapping|index out of range|thread .* crashed'; then
    debug_score=$((debug_score + 5))
  fi
  if echo "$prompt_lower" | grep -qiE 'view not updating|state not working|@published not triggering|combine'; then
    debug_score=$((debug_score + 3))
  fi

  # REFACTOR DETECTION
  if echo "$prompt_lower" | grep -qiE 'refactor|restructure|reorganize|cleanup|clean up|improve|optimize'; then
    refactor_score=$((refactor_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'code smell|duplication|dry|extract|inline|rename|move'; then
    refactor_score=$((refactor_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'mvvm|clean architecture|separation of concerns|dependency injection'; then
    refactor_score=$((refactor_score + 3))
  fi
  if echo "$prompt_lower" | grep -qiE 'migrate .* to swiftui|convert uikit|modernize|update to async'; then
    refactor_score=$((refactor_score + 2))
  fi

  # TDD DETECTION
  if echo "$prompt_lower" | grep -qiE 'test.first|tdd|test.driven|write tests? first|red.green.refactor'; then
    tdd_score=$((tdd_score + 3))
  fi
  if echo "$prompt_lower" | grep -qiE 'with tests?|ensure coverage|comprehensive tests?|full coverage|80% coverage'; then
    tdd_score=$((tdd_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'xctest|unit test|integration test|ui test|snapshot test'; then
    tdd_score=$((tdd_score + 1))
  fi

  # Determine winner
  local max_score=$feature_score
  local intent="feature"

  if [ $debug_score -gt $max_score ]; then
    max_score=$debug_score
    intent="debug"
  fi

  if [ $refactor_score -gt $max_score ]; then
    max_score=$refactor_score
    intent="refactor"
  fi

  local tdd_mode="false"
  if [ $tdd_score -ge 3 ]; then
    tdd_mode="true"
  fi

  # Minimum score threshold
  if [ $max_score -lt 4 ]; then
    echo "none|0|false"
    return
  fi

  echo "${intent}|${max_score}|${tdd_mode}"
}

#==============================================================================
# 8. GENERATE OUTPUT
#==============================================================================

generate_agent_suggestion() {
  local agent="$1"

  case "$agent" in
    "file-finder")
      cat <<EOF
{
  "systemMessage": "📁 **File Search Detected**\\n\\nConsider using the **file-finder** agent for fast Swift file discovery:\\n\\n\`\`\`\\nUse file-finder agent to: $user_prompt\\n\`\`\`\\n\\n**Capabilities:**\\n- Find Swift files by glob pattern\\n- Search by name/content\\n- List project structure",
  "suppressOutput": false
}
EOF
      ;;
    "log-analyzer")
      cat <<EOF
{
  "systemMessage": "📋 **Log Analysis Detected**\\n\\nConsider using the **log-analyzer** agent for Xcode log parsing:\\n\\n\`\`\`\\nUse log-analyzer agent to: $user_prompt\\n\`\`\`\\n\\n**Capabilities:**\\n- Parse Xcode build logs\\n- Analyze crash reports and symbolication\\n- Identify build errors and warnings",
  "suppressOutput": false
}
EOF
      ;;
  esac
}

generate_workflow_suggestion() {
  local intent="$1"
  local tdd_mode="$2"

  case "$intent" in
    "feature")
      if [ "$tdd_mode" = "true" ]; then
        cat <<EOF
{
  "systemMessage": "🧪 **TDD iOS/tvOS Feature Development Detected**\\n\\nConsider using ReAcTree workflows:\\n\\n• \`/ios-feature\` - Feature with user stories + TDD\\n• \`/ios-dev --test-first\` - Full workflow with test-first mode\\n\\n**Benefits:** 80%+ test coverage, test-driven MVVM design, 30-50% faster via parallel execution.",
  "suppressOutput": false
}
EOF
      else
        cat <<EOF
{
  "systemMessage": "🚀 **iOS/tvOS Feature Development Detected**\\n\\nConsider using ReAcTree workflows:\\n\\n• \`/ios-dev\` - Full MVVM workflow with Clean Architecture\\n• \`/ios-feature\` - Feature-driven with user stories\\n\\n**Benefits:** 30-50% faster, working memory caching, automatic skill discovery, parallel execution.",
  "suppressOutput": false
}
EOF
      fi
      ;;
    "debug")
      cat <<EOF
{
  "systemMessage": "🔍 **iOS/tvOS Debugging Task Detected**\\n\\nConsider using:\\n\\n• \`/ios-debug\` - Systematic debugging workflow\\n\\n**Benefits:** Root cause analysis with Xcode logs, crash report symbolication, memory-assisted debugging, automatic regression test creation.",
  "suppressOutput": false
}
EOF
      ;;
    "refactor")
      cat <<EOF
{
  "systemMessage": "♻️ **iOS/tvOS Refactoring Task Detected**\\n\\nConsider using:\\n\\n• \`/ios-refactor\` - MVVM enforcement and architecture cleanup\\n\\n**Benefits:** Safe refactoring, test preservation, SwiftLint validation, working memory ensures consistency.",
  "suppressOutput": false
}
EOF
      ;;
  esac
}

#==============================================================================
# 9. MAIN DETECTION FLOW
#==============================================================================

# First check for utility agent intent (more specific)
agent_result=$(detect_utility_agent)
agent=$(echo "$agent_result" | cut -d'|' -f1)
agent_score=$(echo "$agent_result" | cut -d'|' -f2)

if [ -n "$agent" ] && [ "$agent_score" -ge 4 ]; then
  generate_agent_suggestion "$agent"
  exit 0
fi

# Then check if iOS/tvOS-related for workflow suggestions
if ! is_ios_related; then
  exit 0
fi

# Detect workflow intent
workflow_result=$(detect_workflow_intent)
intent=$(echo "$workflow_result" | cut -d'|' -f1)
score=$(echo "$workflow_result" | cut -d'|' -f2)
tdd_mode=$(echo "$workflow_result" | cut -d'|' -f3)

if [ "$intent" != "none" ] && [ "$score" -ge 4 ]; then
  generate_workflow_suggestion "$intent" "$tdd_mode"
  exit 0
fi

exit 0
