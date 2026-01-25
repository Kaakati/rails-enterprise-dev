#!/bin/bash
# Smart Intent Detection for ReAcTree Rails Development
# Analyzes user prompts and suggests appropriate workflows or utility agents
#
# v2.12.0: Enhanced with Claude CLI for intelligent intent analysis
# - Uses Claude CLI for nuanced understanding when available
# - Falls back to pattern matching when Claude unavailable or times out
# - Hybrid fast path for obvious intents (skip Claude for clear patterns)
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
CONFIG_FILE=".claude/reactree-rails-dev.local.md"

#==============================================================================
# 1. CHECK IF SMART DETECTION ENABLED
#==============================================================================

SMART_DETECTION_ENABLED="true"
DETECTION_MODE="suggest"
ANNOYANCE_THRESHOLD="medium"
USE_CLAUDE_ANALYSIS="true"  # New: Enable Claude CLI analysis

if [ -f "$CONFIG_FILE" ]; then
  SMART_DETECTION_ENABLED=$(sed -n '/^---$/,/^---$/{ /^smart_detection_enabled:/p }' "$CONFIG_FILE" 2>/dev/null | sed 's/smart_detection_enabled: *//' | tr -d ' ')
  DETECTION_MODE=$(sed -n '/^---$/,/^---$/{ /^detection_mode:/p }' "$CONFIG_FILE" 2>/dev/null | sed 's/detection_mode: *//' | tr -d ' ')
  ANNOYANCE_THRESHOLD=$(sed -n '/^---$/,/^---$/{ /^annoyance_threshold:/p }' "$CONFIG_FILE" 2>/dev/null | sed 's/annoyance_threshold: *//' | tr -d ' ')
  USE_CLAUDE_ANALYSIS=$(sed -n '/^---$/,/^---$/{ /^use_claude_analysis:/p }' "$CONFIG_FILE" 2>/dev/null | sed 's/use_claude_analysis: *//' | tr -d ' ')

  SMART_DETECTION_ENABLED=${SMART_DETECTION_ENABLED:-true}
  DETECTION_MODE=${DETECTION_MODE:-suggest}
  ANNOYANCE_THRESHOLD=${ANNOYANCE_THRESHOLD:-medium}
  USE_CLAUDE_ANALYSIS=${USE_CLAUDE_ANALYSIS:-true}
fi

if [ "$SMART_DETECTION_ENABLED" = "false" ] || [ "$DETECTION_MODE" = "disabled" ]; then
  exit 0
fi

#==============================================================================
# 2. SOURCE DEPENDENCIES
#==============================================================================

# Source intent patterns if available
if [ -f "$SCRIPT_DIR/shared/intent-patterns.sh" ]; then
  source "$SCRIPT_DIR/shared/intent-patterns.sh" 2>/dev/null || true
fi

# Source Claude analyzer library
CLAUDE_ANALYZER_AVAILABLE=false
if [ -f "$SCRIPT_DIR/lib/claude-analyzer.sh" ] && [ "$USE_CLAUDE_ANALYSIS" = "true" ]; then
  source "$SCRIPT_DIR/lib/claude-analyzer.sh" 2>/dev/null && CLAUDE_ANALYZER_AVAILABLE=true
fi

#==============================================================================
# 3. CHECK FOR EXPLICIT COMMAND INVOCATION (skip detection)
#==============================================================================

if echo "$user_prompt" | grep -qiE '^/reactree|^/rails-dev|^/rails-feature|^/rails-debug|^/rails-refactor'; then
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

is_rails_related() {
  if echo "$prompt_lower" | grep -qiE 'model|controller|view|migration|activerecord|activejob|actioncable|turbo|stimulus|hotwire|sidekiq|rspec|rails|ruby|gem|bundle|rake'; then
    return 0
  fi

  if echo "$prompt_lower" | grep -qiE 'app/models|app/controllers|app/services|app/components|app/views|config/routes|db/migrate|spec/'; then
    return 0
  fi

  if [ -f "Gemfile" ] && grep -q "rails" "Gemfile" 2>/dev/null; then
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
# 6. HYBRID FAST PATH - Skip Claude for obvious intents
#==============================================================================

# Check for very clear utility agent patterns that don't need Claude
detect_obvious_utility() {
  # FILE FINDER - very obvious patterns
  if echo "$prompt_lower" | grep -qiE '^find (all )?.*files?$|^where is .* file$|^list .* directory$'; then
    echo "file-finder"
    return 0
  fi

  # CODE LINE FINDER - definition/usage patterns
  if echo "$prompt_lower" | grep -qiE '^where is .* (defined|method|class)$|^find (definition|usages|references)'; then
    echo "code-line-finder"
    return 0
  fi

  # GIT DIFF - change patterns
  if echo "$prompt_lower" | grep -qiE '^(show|what) (are the )?changes|^git diff|^git blame|^show diff'; then
    echo "git-diff-analyzer"
    return 0
  fi

  # LOG ANALYZER - log patterns
  if echo "$prompt_lower" | grep -qiE '^show .* log$|^check .* log$|development\.log|production\.log|^show errors'; then
    echo "log-analyzer"
    return 0
  fi

  echo ""
  return 1
}

# Check for very clear workflow patterns
detect_obvious_workflow() {
  # User stories are always features
  if echo "$prompt_lower" | grep -qiE '^as a .*,? i want|^user story:|acceptance criteria:'; then
    echo "feature|5|false"
    return 0
  fi

  # Stack traces are always debug
  if echo "$prompt_lower" | grep -qE '\.rb:[0-9]+|backtrace|NoMethodError|ArgumentError|TypeError|ActiveRecord.*Error'; then
    echo "debug|6|false"
    return 0
  fi

  # Explicit refactor requests
  if echo "$prompt_lower" | grep -qiE '^refactor |^extract |^rename .* to |^move .* to '; then
    echo "refactor|5|false"
    return 0
  fi

  echo ""
  return 1
}

#==============================================================================
# 7. CLAUDE CLI ANALYSIS
#==============================================================================

analyze_with_claude_cli() {
  # Check if Claude analyzer is available
  if [ "$CLAUDE_ANALYZER_AVAILABLE" != "true" ]; then
    return 1
  fi

  # Check if Claude CLI is available
  if ! command -v claude &>/dev/null; then
    return 1
  fi

  # Perform analysis
  local result
  result=$(perform_intent_analysis "$user_prompt" 2>/dev/null)

  # Check for errors
  if echo "$result" | jq -e '.error' &>/dev/null; then
    return 1
  fi

  # Extract intent and confidence
  local intent
  local confidence
  intent=$(echo "$result" | jq -r '.primary_intent // "general"' 2>/dev/null)
  confidence=$(echo "$result" | jq -r '.confidence // 0' 2>/dev/null)

  # Skip if low confidence or question intent
  if [ "$intent" = "question" ] || [ "$intent" = "general" ]; then
    return 1
  fi

  # Convert confidence to integer for comparison
  local conf_int
  conf_int=$(echo "$confidence * 100" | bc 2>/dev/null | cut -d'.' -f1 || echo "0")

  if [ "${conf_int:-0}" -lt 60 ]; then
    return 1
  fi

  # Process based on intent type
  local agents
  local tdd_mode

  agents=$(echo "$result" | jq -r '.recommended_agents[0].name // ""' 2>/dev/null)
  tdd_mode=$(echo "$result" | jq -r '.tdd_mode // false' 2>/dev/null)

  case "$intent" in
    "utility")
      if [ -n "$agents" ]; then
        generate_agent_suggestion "$agents"
        return 0
      fi
      ;;
    "feature")
      generate_workflow_suggestion "feature" "$tdd_mode"
      return 0
      ;;
    "debug")
      generate_workflow_suggestion "debug" "false"
      return 0
      ;;
    "refactor")
      generate_workflow_suggestion "refactor" "false"
      return 0
      ;;
  esac

  return 1
}

#==============================================================================
# 8. PATTERN-BASED DETECTION (Fallback)
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
  elif echo "$prompt_lower" | grep -qiE 'find .* models?|find .* controllers?|find .* services?|find .* components?|find .* views?|find .* specs?'; then
    agent="file-finder"
    score=4
  fi

  # CODE LINE FINDER patterns (higher priority if matches)
  if echo "$prompt_lower" | grep -qiE 'where is .* defined|find definition|go to definition'; then
    agent="code-line-finder"
    score=6
  elif echo "$prompt_lower" | grep -qiE 'where is .* method|find .* method|locate .* method'; then
    agent="code-line-finder"
    score=6
  elif echo "$prompt_lower" | grep -qiE 'find .* usages|find all (calls|references|uses)|who calls|what calls|where is .* used|where is .* called'; then
    agent="code-line-finder"
    score=5
  elif echo "$prompt_lower" | grep -qiE 'find .* class|find .* module|find .* constant'; then
    agent="code-line-finder"
    score=4
  fi

  # GIT DIFF patterns
  if echo "$prompt_lower" | grep -qiE 'what changed|show changes|show diff|git diff|diff from|diff between|compare .* to'; then
    agent="git-diff-analyzer"
    score=6
  elif echo "$prompt_lower" | grep -qiE 'who changed|who modified|git blame|last modified|commit history|recent commits|when was .* changed'; then
    agent="git-diff-analyzer"
    score=5
  elif echo "$prompt_lower" | grep -qiE 'difference between .* and|changes in .* branch|what.s new in|changes since'; then
    agent="git-diff-analyzer"
    score=4
  fi

  # LOG ANALYZER patterns
  if echo "$prompt_lower" | grep -qiE 'show .* log|check .* log|read .* log|view .* log|development.log|production.log|server log|rails log'; then
    agent="log-analyzer"
    score=6
  elif echo "$prompt_lower" | grep -qiE 'errors? in .* log|log errors?|recent errors?|exceptions? in log|failures? in log'; then
    agent="log-analyzer"
    score=5
  elif echo "$prompt_lower" | grep -qiE 'slow queries?|sql .* log|performance .* log'; then
    agent="log-analyzer"
    score=4
  fi

  echo "${agent}|${score}"
}

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

  # DEBUG DETECTION
  if echo "$prompt_lower" | grep -qiE 'fix|debug|troubleshoot|diagnose|investigate|resolve|repair'; then
    debug_score=$((debug_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'error|bug|issue|problem|broken|not working|failing|fails'; then
    debug_score=$((debug_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'nomethoderror|argumenterror|typeerror|syntaxerror|activerec.*error|validationerror|routingerror'; then
    debug_score=$((debug_score + 5))
  fi
  if echo "$prompt_lower" | grep -qE '(line [0-9]+|\.rb:[0-9]+|backtrace|stack trace|exception)'; then
    debug_score=$((debug_score + 5))
  fi

  # REFACTOR DETECTION
  if echo "$prompt_lower" | grep -qiE 'refactor|restructure|reorganize|cleanup|clean up|improve|optimize'; then
    refactor_score=$((refactor_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'code smell|duplication|dry|extract|inline|rename|move'; then
    refactor_score=$((refactor_score + 2))
  fi
  if echo "$prompt_lower" | grep -qiE 'code smell|technical debt|decouple|separation of concerns'; then
    refactor_score=$((refactor_score + 5))
  fi

  # TDD DETECTION
  if echo "$prompt_lower" | grep -qiE 'test.first|tdd|test.driven|write tests? first|red.green.refactor'; then
    tdd_score=$((tdd_score + 3))
  fi
  if echo "$prompt_lower" | grep -qiE 'with tests?|ensure coverage|comprehensive tests?|full coverage'; then
    tdd_score=$((tdd_score + 2))
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

  if [ $max_score -lt 4 ]; then
    echo "none|0|false"
    return
  fi

  echo "${intent}|${max_score}|${tdd_mode}"
}

#==============================================================================
# 9. GENERATE OUTPUT
#==============================================================================

generate_agent_suggestion() {
  local agent="$1"

  case "$agent" in
    "file-finder")
      cat <<'JSONEOF'
{
  "systemMessage": "📁 **File Search Intent Detected - Routing to Specialist**\n\n**ACTION REQUIRED**: Invoke the **file-finder** agent immediately using the Task tool.\n\n**Agent Details:**\n- subagent_type: `reactree-rails-dev:file-finder`\n- Capabilities: Fast file discovery by glob pattern, name, or content\n\n**Invocation Pattern:**\n```\nTask tool with:\n  subagent_type: reactree-rails-dev:file-finder\n  description: Find files matching user request\n  prompt: [user's original request]\n```\n\n⚡ **Do NOT respond with text explanations** - invoke the agent immediately to handle this file search request.",
  "suppressOutput": false
}
JSONEOF
      ;;
    "code-line-finder")
      cat <<'JSONEOF'
{
  "systemMessage": "🔍 **Code Location Intent Detected - Routing to Specialist**\n\n**ACTION REQUIRED**: Invoke the **code-line-finder** agent immediately using the Task tool.\n\n**Agent Details:**\n- subagent_type: `reactree-rails-dev:code-line-finder`\n- Capabilities: LSP-powered symbol lookup, find definitions with line numbers, find all usages/references\n\n**Invocation Pattern:**\n```\nTask tool with:\n  subagent_type: reactree-rails-dev:code-line-finder\n  description: Find code location\n  prompt: [user's original request]\n```\n\n⚡ **Do NOT respond with text explanations** - invoke the agent immediately to handle this code location request.",
  "suppressOutput": false
}
JSONEOF
      ;;
    "git-diff-analyzer")
      cat <<'JSONEOF'
{
  "systemMessage": "📊 **Git Analysis Intent Detected - Routing to Specialist**\n\n**ACTION REQUIRED**: Invoke the **git-diff-analyzer** agent immediately using the Task tool.\n\n**Agent Details:**\n- subagent_type: `reactree-rails-dev:git-diff-analyzer`\n- Capabilities: Analyze diffs (staged/unstaged), compare branches/commits, git blame and history\n\n**Invocation Pattern:**\n```\nTask tool with:\n  subagent_type: reactree-rails-dev:git-diff-analyzer\n  description: Analyze git changes\n  prompt: [user's original request]\n```\n\n⚡ **Do NOT respond with text explanations** - invoke the agent immediately to handle this git analysis request.",
  "suppressOutput": false
}
JSONEOF
      ;;
    "log-analyzer")
      cat <<'JSONEOF'
{
  "systemMessage": "📋 **Log Analysis Intent Detected - Routing to Specialist**\n\n**ACTION REQUIRED**: Invoke the **log-analyzer** agent immediately using the Task tool.\n\n**Agent Details:**\n- subagent_type: `reactree-rails-dev:log-analyzer`\n- Capabilities: Parse development.log/production.log, find errors and stack traces, identify slow queries\n\n**Invocation Pattern:**\n```\nTask tool with:\n  subagent_type: reactree-rails-dev:log-analyzer\n  description: Analyze Rails logs\n  prompt: [user's original request]\n```\n\n⚡ **Do NOT respond with text explanations** - invoke the agent immediately to handle this log analysis request.",
  "suppressOutput": false
}
JSONEOF
      ;;
  esac
}

generate_workflow_suggestion() {
  local intent="$1"
  local tdd_mode="$2"

  case "$intent" in
    "feature")
      if [ "$tdd_mode" = "true" ]; then
        cat <<'JSONEOF'
{
  "systemMessage": "🧪 **TDD Feature Development Intent Detected - Routing to Workflow**\n\n**ACTION REQUIRED**: Invoke the ReAcTree feature workflow immediately using the Skill tool.\n\n**Recommended Workflow:**\n- skill: `reactree-rails-dev:reactree-feature`\n- Or: `reactree-rails-dev:reactree-dev` with test-first approach\n\n**Invocation Pattern:**\n```\nSkill tool with:\n  skill: reactree-rails-dev:reactree-feature\n```\n\n**Benefits:** 85%+ test coverage, test-driven design, 30-50% faster via parallel execution.\n\n⚡ **Do NOT respond with text explanations** - invoke the skill immediately to start the TDD workflow.",
  "suppressOutput": false
}
JSONEOF
      else
        cat <<'JSONEOF'
{
  "systemMessage": "🚀 **Rails Feature Development Intent Detected - Routing to Workflow**\n\n**ACTION REQUIRED**: Invoke the ReAcTree development workflow immediately using the Skill tool.\n\n**Recommended Workflows:**\n- skill: `reactree-rails-dev:reactree-dev` - Full 6-phase workflow with parallel execution\n- skill: `reactree-rails-dev:reactree-feature` - Feature-driven with user stories\n\n**Invocation Pattern:**\n```\nSkill tool with:\n  skill: reactree-rails-dev:reactree-dev\n```\n\n**Benefits:** 30-50% faster, working memory caching, automatic skill discovery.\n\n⚡ **Do NOT respond with text explanations** - invoke the skill immediately to start the development workflow.",
  "suppressOutput": false
}
JSONEOF
      fi
      ;;
    "debug")
      cat <<'JSONEOF'
{
  "systemMessage": "🔍 **Debugging Task Intent Detected - Routing to Workflow**\n\n**ACTION REQUIRED**: Invoke the ReAcTree debug workflow immediately using the Skill tool.\n\n**Recommended Workflow:**\n- skill: `reactree-rails-dev:reactree-debug`\n\n**Invocation Pattern:**\n```\nSkill tool with:\n  skill: reactree-rails-dev:reactree-debug\n```\n\n**Benefits:** Root cause analysis, memory-assisted debugging, automatic regression test creation.\n\n⚡ **Do NOT respond with text explanations** - invoke the skill immediately to start the debugging workflow.",
  "suppressOutput": false
}
JSONEOF
      ;;
    "refactor")
      cat <<'JSONEOF'
{
  "systemMessage": "♻️ **Refactoring Task Intent Detected - Routing to Workflow**\n\n**ACTION REQUIRED**: Invoke the ReAcTree refactor workflow immediately using the Skill tool.\n\n**Recommended Workflow:**\n- skill: `reactree-rails-dev:reactree-refactor`\n\n**Invocation Pattern:**\n```\nSkill tool with:\n  skill: reactree-rails-dev:reactree-refactor\n```\n\n**Benefits:** Safe refactoring with test preservation, automatic reference tracking, working memory ensures consistency.\n\n⚡ **Do NOT respond with text explanations** - invoke the skill immediately to start the refactoring workflow.",
  "suppressOutput": false
}
JSONEOF
      ;;
  esac
}

#==============================================================================
# 10. MAIN DETECTION FLOW
#==============================================================================

# STEP 1: Try hybrid fast path for obvious intents
obvious_agent=$(detect_obvious_utility)
if [ -n "$obvious_agent" ]; then
  generate_agent_suggestion "$obvious_agent"
  exit 0
fi

obvious_workflow=$(detect_obvious_workflow)
if [ -n "$obvious_workflow" ]; then
  intent=$(echo "$obvious_workflow" | cut -d'|' -f1)
  tdd=$(echo "$obvious_workflow" | cut -d'|' -f3)
  generate_workflow_suggestion "$intent" "$tdd"
  exit 0
fi

# STEP 2: Try Claude CLI analysis (if enabled and available)
if [ "$USE_CLAUDE_ANALYSIS" = "true" ] && [ "$CLAUDE_ANALYZER_AVAILABLE" = "true" ]; then
  if analyze_with_claude_cli; then
    exit 0
  fi
  # Claude analysis failed or returned low confidence, fall through to pattern matching
fi

# STEP 3: Fall back to pattern-based utility agent detection
agent_result=$(detect_utility_agent)
agent=$(echo "$agent_result" | cut -d'|' -f1)
agent_score=$(echo "$agent_result" | cut -d'|' -f2)

if [ -n "$agent" ] && [ "$agent_score" -ge 4 ]; then
  generate_agent_suggestion "$agent"
  exit 0
fi

# STEP 4: Check if Rails-related for workflow suggestions
if ! is_rails_related; then
  exit 0
fi

# STEP 5: Pattern-based workflow intent detection
workflow_result=$(detect_workflow_intent)
intent=$(echo "$workflow_result" | cut -d'|' -f1)
score=$(echo "$workflow_result" | cut -d'|' -f2)
tdd_mode=$(echo "$workflow_result" | cut -d'|' -f3)

if [ "$intent" != "none" ] && [ "$score" -ge 4 ]; then
  generate_workflow_suggestion "$intent" "$tdd_mode"
  exit 0
fi

exit 0
