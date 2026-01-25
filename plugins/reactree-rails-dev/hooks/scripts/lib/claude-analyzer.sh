#!/bin/bash
# Claude CLI Analyzer for Intent Detection
# Wraps Claude CLI for intelligent prompt analysis with timeout protection
#
# Features:
# - Uses Claude CLI -p flag for non-interactive analysis
# - JSON output format for programmatic parsing
# - 3-second timeout protection
# - Graceful fallback on errors

# Get script directory for sourcing dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#==============================================================================
# CONFIGURATION
#==============================================================================

CLAUDE_TIMEOUT=10  # seconds
CLAUDE_MODEL="haiku"  # Fast model for intent detection

#==============================================================================
# CLAUDE CLI DETECTION
#==============================================================================

is_claude_available() {
  command -v claude &>/dev/null
}

#==============================================================================
# INTENT ANALYSIS PROMPT
#==============================================================================

get_analysis_prompt() {
  local user_prompt="$1"
  local manifests="$2"

  cat <<'PROMPT_EOF'
You are an intent classifier for a Rails development assistant. Analyze the user's request and recommend the best agents/skills to handle it.

CLASSIFICATION RULES:
1. Utility intents (quick, specific lookups) → route to utility agents
2. Feature development (new functionality) → route to workflow-orchestrator or feature workflows
3. Debugging (errors, bugs, issues) → route to debug workflow
4. Refactoring (code improvement) → route to refactor workflow
5. Simple questions (conceptual, documentation) → no recommendation (let default handle)

UTILITY AGENTS (for quick, specific tasks):
- file-finder: File discovery by pattern/name/content
- code-line-finder: Find method/class definitions, usages, references
- git-diff-analyzer: Git changes, blame, history, branch comparison
- log-analyzer: Parse Rails logs, find errors, slow queries

WORKFLOW SKILLS (for complex multi-step tasks):
- reactree-dev: Full 6-phase Rails development workflow
- reactree-feature: Feature-driven development with user stories
- reactree-debug: Systematic debugging with root cause analysis
- reactree-refactor: Safe refactoring with test preservation

AVAILABLE RESOURCES:
PROMPT_EOF

  echo "$manifests"

  cat <<PROMPT_EOF

USER REQUEST:
"$user_prompt"

Respond with ONLY valid JSON in this exact format:
{
  "primary_intent": "utility|feature|debug|refactor|question|general",
  "confidence": 0.0-1.0,
  "recommended_agents": [
    {"name": "agent-name", "reason": "brief reason", "priority": 1}
  ],
  "recommended_skills": ["skill-name"],
  "tdd_mode": false,
  "system_message": "Brief message to show user about recommended action"
}

If confidence < 0.6 or it's a simple question, return:
{"primary_intent": "question", "confidence": 0.0, "recommended_agents": [], "recommended_skills": [], "tdd_mode": false, "system_message": ""}
PROMPT_EOF
}

#==============================================================================
# CLAUDE CLI ANALYSIS
#==============================================================================

analyze_with_claude() {
  local user_prompt="$1"
  local manifests="$2"

  # Check if Claude is available
  if ! is_claude_available; then
    echo '{"error": "claude_not_available"}'
    return 1
  fi

  # Build the analysis prompt
  local full_prompt
  full_prompt=$(get_analysis_prompt "$user_prompt" "$manifests")

  # Call Claude CLI with timeout
  local result
  local exit_code

  # Use timeout command (gtimeout on macOS if available, timeout on Linux)
  local timeout_cmd="timeout"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v gtimeout &>/dev/null; then
      timeout_cmd="gtimeout"
    else
      # Fallback: use background process with sleep
      timeout_cmd=""
    fi
  fi

  if [ -n "$timeout_cmd" ]; then
    result=$($timeout_cmd "${CLAUDE_TIMEOUT}s" claude -p "$full_prompt" --output-format json 2>/dev/null)
    exit_code=$?
  else
    # macOS fallback without gtimeout
    result=$(
      claude -p "$full_prompt" --output-format json 2>/dev/null &
      local pid=$!
      (
        sleep "$CLAUDE_TIMEOUT"
        kill $pid 2>/dev/null
      ) &
      local watchdog=$!
      wait $pid 2>/dev/null
      local exit_code=$?
      kill $watchdog 2>/dev/null
      exit $exit_code
    )
    exit_code=$?
  fi

  # Handle timeout or error
  if [ $exit_code -ne 0 ]; then
    echo '{"error": "timeout_or_error", "exit_code": '$exit_code'}'
    return 1
  fi

  # Extract JSON from result (Claude may wrap it in additional structure)
  # Look for the JSON object with primary_intent
  local json_result
  json_result=$(echo "$result" | grep -o '{[^}]*"primary_intent"[^}]*}' | head -1)

  if [ -z "$json_result" ]; then
    # Try to extract from result field if Claude wrapped it
    json_result=$(echo "$result" | jq -r '.result // .' 2>/dev/null | grep -o '{[^}]*"primary_intent"[^}]*}' | head -1)
  fi

  if [ -z "$json_result" ]; then
    echo '{"error": "invalid_response", "raw": "'"$(echo "$result" | head -c 200)"'"}'
    return 1
  fi

  # Validate JSON structure
  if ! echo "$json_result" | jq -e '.primary_intent' &>/dev/null; then
    echo '{"error": "missing_fields"}'
    return 1
  fi

  echo "$json_result"
  return 0
}

#==============================================================================
# RESULT PARSING
#==============================================================================

parse_claude_result() {
  local result="$1"

  # Check for errors
  if echo "$result" | jq -e '.error' &>/dev/null; then
    return 1
  fi

  # Extract fields
  local intent
  local confidence
  local agents
  local skills
  local tdd_mode
  local message

  intent=$(echo "$result" | jq -r '.primary_intent // "general"')
  confidence=$(echo "$result" | jq -r '.confidence // 0')
  agents=$(echo "$result" | jq -c '.recommended_agents // []')
  skills=$(echo "$result" | jq -c '.recommended_skills // []')
  tdd_mode=$(echo "$result" | jq -r '.tdd_mode // false')
  message=$(echo "$result" | jq -r '.system_message // ""')

  # Return as structured output
  cat <<EOF
{
  "intent": "$intent",
  "confidence": $confidence,
  "agents": $agents,
  "skills": $skills,
  "tdd_mode": $tdd_mode,
  "message": "$message"
}
EOF
}

#==============================================================================
# HIGH-LEVEL INTERFACE
#==============================================================================

# Main analysis function that integrates manifest generation and Claude analysis
# Returns structured JSON with intent classification and recommendations
#
# Usage: perform_intent_analysis "user prompt"
# Returns: JSON object with intent, agents, skills, and system message
perform_intent_analysis() {
  local user_prompt="$1"

  # Source manifest generator
  source "$SCRIPT_DIR/manifest-generator.sh"

  # Get manifests (uses cache if valid)
  local manifests
  manifests=$(main 2>/dev/null) || {
    echo '{"error": "manifest_generation_failed"}'
    return 1
  }

  # Perform Claude analysis
  local result
  result=$(analyze_with_claude "$user_prompt" "$manifests")

  # Return result
  echo "$result"
}

#==============================================================================
# SELF-TEST
#==============================================================================

self_test() {
  echo "Testing Claude Analyzer..."
  echo ""

  # Test Claude availability
  echo -n "Claude CLI available: "
  if is_claude_available; then
    echo "YES"
  else
    echo "NO (will use fallback)"
  fi
  echo ""

  # Test manifest generation
  echo "Testing manifest generation..."
  source "$SCRIPT_DIR/manifest-generator.sh"
  local manifest
  manifest=$(main --refresh 2>/dev/null)
  local agent_count
  local skill_count
  agent_count=$(echo "$manifest" | jq '.agents | length' 2>/dev/null || echo 0)
  skill_count=$(echo "$manifest" | jq '.skills | length' 2>/dev/null || echo 0)
  echo "  Agents: $agent_count"
  echo "  Skills: $skill_count"
  echo ""

  # Test analysis (only if Claude available)
  if is_claude_available; then
    echo "Testing intent analysis..."
    local test_prompt="find all user model files"
    local result
    result=$(perform_intent_analysis "$test_prompt")
    echo "  Input: '$test_prompt'"
    echo "  Result: $result"
  fi

  echo ""
  echo "Self-test complete."
}

# Run self-test if executed directly with --test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ "${1:-}" == "--test" ]]; then
    self_test
  else
    echo "Usage: source this file or run with --test"
    echo "  source claude-analyzer.sh"
    echo "  ./claude-analyzer.sh --test"
  fi
fi
