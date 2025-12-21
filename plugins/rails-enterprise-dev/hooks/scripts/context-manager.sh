#!/bin/bash
# Context management for AI/LLM optimization
# Tracks token usage, enables progressive loading, summarizes phases

set -e

ACTION=${1:-"track"}  # track | summarize | check
STATE_FILE=".claude/rails-enterprise-dev.local.md"

# Token estimation (rough approximation: 1 token ≈ 0.75 words)
estimate_tokens() {
  local file=$1

  if [ ! -f "$file" ]; then
    echo 0
    return
  fi

  WORD_COUNT=$(wc -w < "$file" 2>/dev/null || echo 0)
  echo $(awk "BEGIN {print int($WORD_COUNT * 1.3)}")
}

# Track current token usage
track_usage() {
  echo "📊 Context Usage Analysis"
  echo ""

  # Estimate tokens in various sources
  STATE_TOKENS=$(estimate_tokens "$STATE_FILE")
  SKILLS_TOTAL=0

  if [ -d ".claude/skills" ]; then
    for skill in .claude/skills/*/SKILL.md; do
      if [ -f "$skill" ]; then
        SKILL_TOKENS=$(estimate_tokens "$skill")
        SKILLS_TOTAL=$((SKILLS_TOTAL + SKILL_TOKENS))
      fi
    done
  fi

  # Analysis results
  ANALYSIS_TOKENS=0
  if [ -f ".claude/static-analysis.json" ]; then
    ANALYSIS_TOKENS=$(estimate_tokens ".claude/static-analysis.json")
  fi

  # Inspection reports
  INSPECTION_TOKENS=0
  if [ -f ".claude/inspection-report.md" ]; then
    INSPECTION_TOKENS=$(estimate_tokens ".claude/inspection-report.md")
  fi

  TOTAL_TOKENS=$((STATE_TOKENS + SKILLS_TOTAL + ANALYSIS_TOKENS + INSPECTION_TOKENS))

  echo "  State file: ${STATE_TOKENS} tokens"
  echo "  Skills: ${SKILLS_TOTAL} tokens"
  echo "  Analysis: ${ANALYSIS_TOKENS} tokens"
  echo "  Inspection: ${INSPECTION_TOKENS} tokens"
  echo "  ────────────────────────────"
  echo "  Total: ${TOTAL_TOKENS} tokens"
  echo ""

  # Budget check (assuming 100k token context)
  BUDGET=100000
  PERCENTAGE=$((TOTAL_TOKENS * 100 / BUDGET))

  if [ $PERCENTAGE -gt 80 ]; then
    echo "⚠️  Context usage at ${PERCENTAGE}% - consider summarization"
  elif [ $PERCENTAGE -gt 60 ]; then
    echo "ℹ️  Context usage at ${PERCENTAGE}% - approaching limit"
  else
    echo "✓ Context usage at ${PERCENTAGE}% - healthy"
  fi

  # Update state file with usage
  if [ -f "$STATE_FILE" ]; then
    if grep -q "^token_usage:" "$STATE_FILE"; then
      sed -i.bak "s/^token_usage:.*/token_usage: $TOTAL_TOKENS/" "$STATE_FILE"
    else
      echo "token_usage: $TOTAL_TOKENS" >> "$STATE_FILE"
    fi

    if grep -q "^token_budget:" "$STATE_FILE"; then
      sed -i.bak "s/^token_budget:.*/token_budget: $BUDGET/" "$STATE_FILE"
    else
      echo "token_budget: $BUDGET" >> "$STATE_FILE"
    fi

    rm -f "${STATE_FILE}.bak"
  fi
}

# Summarize completed phase to reduce context
summarize_phase() {
  local phase=$1

  echo "📝 Summarizing phase: $phase"

  # Look for phase output/report
  PHASE_FILE=".claude/phase-${phase}.md"

  if [ ! -f "$PHASE_FILE" ]; then
    echo "⚠️  No phase file found: $PHASE_FILE"
    return 1
  fi

  # Create summary (keep key points, archive details)
  SUMMARY_FILE=".claude/phase-${phase}-summary.md"

  cat > "$SUMMARY_FILE" <<EOF
# ${phase} Phase Summary

**Status**: Completed
**Date**: $(date +%Y-%m-%d)

## Key Outcomes:
- [Summarize main deliverables]

## Files Created/Modified:
$(grep "Created:" "$PHASE_FILE" 2>/dev/null || echo "- No files tracked")

## Issues Encountered:
$(grep "Error:" "$PHASE_FILE" 2>/dev/null || echo "- None")

## Next Phase Dependencies:
- [What next phase needs from this phase]

---
*Full details archived in ${PHASE_FILE}*
EOF

  # Move full report to archive
  mkdir -p .claude/archive
  mv "$PHASE_FILE" ".claude/archive/phase-${phase}-$(date +%Y%m%d).md"

  echo "✓ Summary created: $SUMMARY_FILE"
  echo "✓ Full report archived"

  # Recalculate token usage
  track_usage
}

# Check if progressive loading enabled
check_strategy() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "No state file found"
    return
  fi

  STRATEGY=$(grep "^context_strategy:" "$STATE_FILE" | cut -d' ' -f2-)

  echo "Context Strategy: ${STRATEGY:-full}"

  if [ "$STRATEGY" = "progressive" ]; then
    echo "✓ Progressive loading enabled (saves ~60% context)"
    echo ""
    echo "How it works:"
    echo "  1. Skills loaded on-demand per phase"
    echo "  2. Completed phases summarized"
    echo "  3. Only essential context kept active"
  else
    echo "ℹ️  Using full context (all skills loaded)"
    echo ""
    echo "To enable progressive loading:"
    echo "  1. Edit $STATE_FILE"
    echo "  2. Set: context_strategy: progressive"
  fi
}

# Recommend optimization
recommend_optimization() {
  TOTAL_TOKENS=$(estimate_tokens "$STATE_FILE")

  if [ -d ".claude/skills" ]; then
    SKILL_COUNT=$(find .claude/skills -name "SKILL.md" | wc -l)
  else
    SKILL_COUNT=0
  fi

  echo ""
  echo "🎯 Optimization Recommendations"
  echo ""

  if [ $SKILL_COUNT -gt 10 ]; then
    echo "1. Enable progressive skill loading"
    echo "   - You have $SKILL_COUNT skills (~$((SKILL_COUNT * 1000)) tokens)"
    echo "   - Load only relevant skills per phase"
    echo "   - Potential savings: ~60%"
    echo ""
  fi

  if [ -f ".claude/inspection-report.md" ]; then
    INSPECTION_SIZE=$(wc -w < ".claude/inspection-report.md")
    if [ $INSPECTION_SIZE -gt 5000 ]; then
      echo "2. Summarize inspection report"
      echo "   - Current size: $INSPECTION_SIZE words"
      echo "   - Keep only essential patterns"
      echo "   - Potential savings: ~40%"
      echo ""
    fi
  fi

  COMPLETED_PHASES=$(grep -l "Status.*Complete" .claude/phase-*.md 2>/dev/null | wc -l || echo 0)
  if [ $COMPLETED_PHASES -gt 0 ]; then
    echo "3. Archive completed phases"
    echo "   - $COMPLETED_PHASES phases can be summarized"
    echo "   - Keep summaries, archive details"
    echo "   - Run: ./context-manager.sh summarize <phase>"
    echo ""
  fi
}

# Main execution
case "$ACTION" in
  track)
    track_usage
    recommend_optimization
    ;;

  summarize)
    PHASE=$2
    if [ -z "$PHASE" ]; then
      echo "Usage: $0 summarize <phase-name>"
      exit 1
    fi
    summarize_phase "$PHASE"
    ;;

  check)
    check_strategy
    ;;

  optimize)
    echo "🔧 Running automatic optimization..."
    echo ""

    # Enable progressive loading
    if [ -f "$STATE_FILE" ]; then
      if ! grep -q "^context_strategy:" "$STATE_FILE"; then
        echo "context_strategy: progressive" >> "$STATE_FILE"
        echo "✓ Enabled progressive loading"
      fi
    fi

    # Summarize old completed phases
    for phase_file in .claude/phase-*.md; do
      if [ -f "$phase_file" ] && grep -q "Status.*Complete" "$phase_file"; then
        PHASE_NAME=$(basename "$phase_file" .md | sed 's/phase-//')
        summarize_phase "$PHASE_NAME"
      fi
    done

    echo ""
    echo "✓ Optimization complete"
    track_usage
    ;;

  *)
    echo "Usage: $0 {track|summarize|check|optimize}"
    echo ""
    echo "Commands:"
    echo "  track      - Show current token usage"
    echo "  summarize  - Summarize a completed phase"
    echo "  check      - Check context strategy"
    echo "  optimize   - Run automatic optimization"
    exit 1
    ;;
esac
