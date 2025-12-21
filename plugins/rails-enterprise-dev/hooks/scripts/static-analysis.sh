#!/bin/bash
# Static analysis integration for enhanced code quality
# Supports: Rubocop, Brakeman, bundler-audit, Flog, Rails Best Practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Running static analysis..."

# Check which tools are available
RUBOCOP_AVAILABLE=false
BRAKEMAN_AVAILABLE=false
BUNDLER_AUDIT_AVAILABLE=false
FLOG_AVAILABLE=false
RBP_AVAILABLE=false

command -v rubocop &> /dev/null && RUBOCOP_AVAILABLE=true
command -v brakeman &> /dev/null && BRAKEMAN_AVAILABLE=true
command -v bundle-audit &> /dev/null && BUNDLER_AUDIT_AVAILABLE=true
command -v flog &> /dev/null && FLOG_AVAILABLE=true
command -v rails_best_practices &> /dev/null && RBP_AVAILABLE=true

ANALYSIS_DIR="/tmp/claude-analysis"
mkdir -p "$ANALYSIS_DIR"

EXIT_CODE=0

# 1. Security scan with Brakeman
if [ "$BRAKEMAN_AVAILABLE" = true ]; then
  echo ""
  echo "🔒 Security Analysis (Brakeman)..."
  brakeman -o "$ANALYSIS_DIR/brakeman.json" -f json --no-pager -q 2>/dev/null || true

  if [ -f "$ANALYSIS_DIR/brakeman.json" ]; then
    CRITICAL_COUNT=$(cat "$ANALYSIS_DIR/brakeman.json" | jq '.warnings | map(select(.confidence == "High")) | length' 2>/dev/null || echo 0)

    if [ "$CRITICAL_COUNT" -gt 0 ]; then
      echo -e "${RED}✗ Found $CRITICAL_COUNT high-confidence security issues${NC}"
      cat "$ANALYSIS_DIR/brakeman.json" | jq -r '.warnings[] | select(.confidence == "High") | "  - \(.warning_type): \(.message | .[0:100])"' | head -5
      EXIT_CODE=1
    else
      echo -e "${GREEN}✓ No critical security issues${NC}"
    fi
  fi
else
  echo -e "${YELLOW}⚠️  Brakeman not installed (gem install brakeman)${NC}"
fi

# 2. Gem vulnerability check
if [ "$BUNDLER_AUDIT_AVAILABLE" = true ]; then
  echo ""
  echo "📦 Gem Vulnerability Check..."
  bundle-audit check > "$ANALYSIS_DIR/bundler-audit.txt" 2>&1 || true

  if grep -q "Vulnerabilities found" "$ANALYSIS_DIR/bundler-audit.txt"; then
    echo -e "${RED}✗ Gem vulnerabilities detected${NC}"
    grep "CVE" "$ANALYSIS_DIR/bundler-audit.txt" | head -5
    EXIT_CODE=1
  else
    echo -e "${GREEN}✓ No gem vulnerabilities${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  bundler-audit not installed (gem install bundler-audit)${NC}"
fi

# 3. Code style with Rubocop
if [ "$RUBOCOP_AVAILABLE" = true ]; then
  echo ""
  echo "🎨 Code Style Analysis (Rubocop)..."
  rubocop --format json --out "$ANALYSIS_DIR/rubocop.json" 2>/dev/null || true

  if [ -f "$ANALYSIS_DIR/rubocop.json" ]; then
    OFFENSE_COUNT=$(cat "$ANALYSIS_DIR/rubocop.json" | jq '.summary.offense_count' 2>/dev/null || echo 0)

    if [ "$OFFENSE_COUNT" -gt 0 ]; then
      echo -e "${YELLOW}⚠️  Found $OFFENSE_COUNT style offenses${NC}"

      # Show top categories
      echo "  Top offense categories:"
      cat "$ANALYSIS_DIR/rubocop.json" | jq -r '.files[].offenses[].cop_name' | \
        sort | uniq -c | sort -rn | head -5 | \
        awk '{print "    - " $2 ": " $1 " occurrences"}'

      # Don't fail on style issues, just warn
    else
      echo -e "${GREEN}✓ No style offenses${NC}"
    fi
  fi
else
  echo -e "${YELLOW}⚠️  Rubocop not installed (gem install rubocop)${NC}"
fi

# 4. Complexity analysis with Flog
if [ "$FLOG_AVAILABLE" = true ]; then
  echo ""
  echo "📊 Complexity Analysis (Flog)..."
  flog app/services app/models 2>/dev/null > "$ANALYSIS_DIR/flog.txt" || true

  if [ -f "$ANALYSIS_DIR/flog.txt" ]; then
    echo "  Most complex methods:"
    head -10 "$ANALYSIS_DIR/flog.txt" | tail -5
  fi
else
  echo -e "${YELLOW}⚠️  Flog not installed (gem install flog)${NC}"
fi

# 5. Rails best practices
if [ "$RBP_AVAILABLE" = true ]; then
  echo ""
  echo "📖 Rails Best Practices..."
  rails_best_practices > "$ANALYSIS_DIR/rbp.txt" 2>&1 || true

  if [ -f "$ANALYSIS_DIR/rbp.txt" ]; then
    ISSUE_COUNT=$(grep -c "^app/" "$ANALYSIS_DIR/rbp.txt" 2>/dev/null || echo 0)

    if [ "$ISSUE_COUNT" -gt 0 ]; then
      echo -e "${YELLOW}⚠️  Found $ISSUE_COUNT best practice issues${NC}"
      head -10 "$ANALYSIS_DIR/rbp.txt"
    else
      echo -e "${GREEN}✓ Following Rails best practices${NC}"
    fi
  fi
fi

# Generate summary JSON
cat > "$ANALYSIS_DIR/summary.json" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "security": {
    "brakeman_critical": ${CRITICAL_COUNT:-0},
    "gem_vulnerabilities": "$(grep -c "CVE" "$ANALYSIS_DIR/bundler-audit.txt" 2>/dev/null || echo 0)"
  },
  "quality": {
    "rubocop_offenses": ${OFFENSE_COUNT:-0},
    "complexity_high": "$(grep -c ":" "$ANALYSIS_DIR/flog.txt" 2>/dev/null | head -1 || echo 0)"
  },
  "tools_available": {
    "rubocop": $RUBOCOP_AVAILABLE,
    "brakeman": $BRAKEMAN_AVAILABLE,
    "bundler_audit": $BUNDLER_AUDIT_AVAILABLE,
    "flog": $FLOG_AVAILABLE,
    "rails_best_practices": $RBP_AVAILABLE
  }
}
EOF

# Copy summary to project directory
mkdir -p .claude
cp "$ANALYSIS_DIR/summary.json" .claude/static-analysis.json

echo ""
echo "📄 Analysis complete. Results saved to .claude/static-analysis.json"

exit $EXIT_CODE
