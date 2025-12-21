#!/bin/bash
# Metrics collection for workflow performance analysis
# Tracks phase duration, success rates, retries, and bottlenecks

set -e

ACTION=${1:-"record"}  # record | analyze | report
METRICS_FILE=".claude/workflow-metrics.jsonl"

mkdir -p .claude

# Record a phase metric
record_metric() {
  local phase=$1
  local duration=$2
  local status=$3  # success | failed | retried
  local retry_count=${4:-0}
  local files_changed=${5:-0}

  # Create JSONL entry
  cat >> "$METRICS_FILE" <<EOF
{"phase":"$phase","duration":$duration,"status":"$status","retry_count":$retry_count,"files_changed":$files_changed,"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF

  echo "✓ Metric recorded: $phase ($status, ${duration}s)"
}

# Analyze metrics
analyze_metrics() {
  if [ ! -f "$METRICS_FILE" ]; then
    echo "No metrics found. Run some workflows first."
    return
  fi

  echo "📊 Workflow Metrics Analysis"
  echo ""

  # Use jq to analyze the JSONL file
  if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not installed. Install for detailed analysis: brew install jq"
    echo ""
    echo "Basic statistics:"
    echo "  Total entries: $(wc -l < "$METRICS_FILE")"
    return
  fi

  # Phase statistics
  echo "=== Phase Performance ==="
  echo ""

  jq -s 'group_by(.phase) |
    map({
      phase: .[0].phase,
      count: length,
      avg_duration: (map(.duration) | add / length | round),
      success_rate: ((map(select(.status == "success")) | length) / length * 100 | round),
      avg_retries: (map(.retry_count) | add / length | round)
    }) |
    sort_by(.avg_duration) |
    reverse |
    .[] |
    "\(.phase):\n  Runs: \(.count)\n  Avg Duration: \(.avg_duration)s\n  Success Rate: \(.success_rate)%\n  Avg Retries: \(.avg_retries)\n"' \
    "$METRICS_FILE"

  echo ""
  echo "=== Slowest Phases ==="
  echo ""

  jq -s 'group_by(.phase) |
    map({
      phase: .[0].phase,
      avg_duration: (map(.duration) | add / length | round)
    }) |
    sort_by(.avg_duration) |
    reverse |
    limit(5; .[]) |
    "  \(.phase): \(.avg_duration)s"' \
    "$METRICS_FILE"

  echo ""
  echo "=== Most Retried Phases ==="
  echo ""

  jq -s 'map(select(.retry_count > 0)) |
    group_by(.phase) |
    map({
      phase: .[0].phase,
      total_retries: (map(.retry_count) | add),
      avg_retries: (map(.retry_count) | add / length | round)
    }) |
    sort_by(.total_retries) |
    reverse |
    limit(5; .[]) |
    "  \(.phase): \(.total_retries) total retries (avg: \(.avg_retries))"' \
    "$METRICS_FILE"

  echo ""
  echo "=== Recent Workflow Trends ==="
  echo ""

  # Last 10 workflow executions
  jq -s 'reverse |
    limit(10; .[]) |
    "\(.timestamp | split("T")[0]): \(.phase) (\(.status), \(.duration)s)"' \
    "$METRICS_FILE"

  # Overall statistics
  echo ""
  echo "=== Overall Statistics ==="
  echo ""

  TOTAL_RUNS=$(jq -s 'length' "$METRICS_FILE")
  SUCCESS_COUNT=$(jq -s 'map(select(.status == "success")) | length' "$METRICS_FILE")
  FAILURE_COUNT=$(jq -s 'map(select(.status == "failed")) | length' "$METRICS_FILE")
  TOTAL_DURATION=$(jq -s 'map(.duration) | add' "$METRICS_FILE")
  AVG_DURATION=$(jq -s 'map(.duration) | add / length | round' "$METRICS_FILE")

  echo "  Total phase executions: $TOTAL_RUNS"
  echo "  Successes: $SUCCESS_COUNT"
  echo "  Failures: $FAILURE_COUNT"
  echo "  Success rate: $(awk "BEGIN {print int($SUCCESS_COUNT * 100 / $TOTAL_RUNS)}")%"
  echo "  Total time: ${TOTAL_DURATION}s ($(awk "BEGIN {print int($TOTAL_DURATION / 60)}")min)"
  echo "  Average phase duration: ${AVG_DURATION}s"
}

# Generate HTML report
generate_report() {
  if [ ! -f "$METRICS_FILE" ]; then
    echo "No metrics to report"
    return
  fi

  REPORT_FILE=".claude/metrics-report.html"

  cat > "$REPORT_FILE" <<'EOFHTML'
<!DOCTYPE html>
<html>
<head>
  <title>Workflow Metrics Report</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
      max-width: 1200px;
      margin: 40px auto;
      padding: 20px;
      background: #f5f5f5;
    }
    .metric-card {
      background: white;
      border-radius: 8px;
      padding: 20px;
      margin: 20px 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    h1 { color: #333; }
    h2 { color: #555; margin-top: 0; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 15px 0;
    }
    th, td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th { background: #f8f8f8; font-weight: 600; }
    .success { color: #22c55e; }
    .failed { color: #ef4444; }
    .warning { color: #f59e0b; }
  </style>
</head>
<body>
  <h1>📊 Rails Enterprise Dev Workflow Metrics</h1>
  <p>Generated: <span id="timestamp"></span></p>

  <div class="metric-card">
    <h2>Overall Statistics</h2>
    <div id="overall-stats"></div>
  </div>

  <div class="metric-card">
    <h2>Phase Performance</h2>
    <table id="phase-table">
      <thead>
        <tr>
          <th>Phase</th>
          <th>Runs</th>
          <th>Avg Duration</th>
          <th>Success Rate</th>
          <th>Avg Retries</th>
        </tr>
      </thead>
      <tbody id="phase-body"></tbody>
    </table>
  </div>

  <div class="metric-card">
    <h2>Recent Executions</h2>
    <div id="recent-executions"></div>
  </div>

  <script>
    // Load and display metrics
    document.getElementById('timestamp').textContent = new Date().toLocaleString();

    // Add your metrics data here (or load from JSON)
    // This is a template - actual data would be injected server-side
  </script>
</body>
</html>
EOFHTML

  echo "✓ Report generated: $REPORT_FILE"
  echo "  Open in browser: open $REPORT_FILE"
}

# Track phase start time
start_phase() {
  local phase=$1
  local start_file=".claude/phase-${phase}.start"

  date +%s > "$start_file"
  echo "⏱️  Started: $phase"
}

# Track phase end and record metric
end_phase() {
  local phase=$1
  local status=${2:-success}
  local retry_count=${3:-0}
  local start_file=".claude/phase-${phase}.start"

  if [ ! -f "$start_file" ]; then
    echo "⚠️  No start time found for phase: $phase"
    return 1
  fi

  START_TIME=$(cat "$start_file")
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  # Count files changed (git diff)
  FILES_CHANGED=$(git diff --name-only HEAD | wc -l || echo 0)

  record_metric "$phase" "$DURATION" "$status" "$retry_count" "$FILES_CHANGED"

  rm -f "$start_file"

  echo "⏱️  Completed: $phase (${DURATION}s)"
}

# Export metrics for analysis tools
export_csv() {
  if [ ! -f "$METRICS_FILE" ]; then
    echo "No metrics to export"
    return
  fi

  CSV_FILE=".claude/metrics.csv"

  # CSV header
  echo "timestamp,phase,duration,status,retry_count,files_changed" > "$CSV_FILE"

  # Convert JSONL to CSV
  if command -v jq &> /dev/null; then
    jq -r '[.timestamp, .phase, .duration, .status, .retry_count, .files_changed] | @csv' \
      "$METRICS_FILE" >> "$CSV_FILE"

    echo "✓ Exported to: $CSV_FILE"
  else
    echo "⚠️  jq required for CSV export"
  fi
}

# Main execution
case "$ACTION" in
  record)
    PHASE=$2
    DURATION=$3
    STATUS=${4:-success}
    RETRY_COUNT=${5:-0}
    FILES_CHANGED=${6:-0}

    if [ -z "$PHASE" ] || [ -z "$DURATION" ]; then
      echo "Usage: $0 record <phase> <duration> [status] [retry_count] [files_changed]"
      exit 1
    fi

    record_metric "$PHASE" "$DURATION" "$STATUS" "$RETRY_COUNT" "$FILES_CHANGED"
    ;;

  start)
    PHASE=$2
    if [ -z "$PHASE" ]; then
      echo "Usage: $0 start <phase>"
      exit 1
    fi
    start_phase "$PHASE"
    ;;

  end)
    PHASE=$2
    STATUS=${3:-success}
    RETRY_COUNT=${4:-0}

    if [ -z "$PHASE" ]; then
      echo "Usage: $0 end <phase> [status] [retry_count]"
      exit 1
    fi

    end_phase "$PHASE" "$STATUS" "$RETRY_COUNT"
    ;;

  analyze)
    analyze_metrics
    ;;

  report)
    generate_report
    ;;

  export)
    export_csv
    ;;

  clear)
    if [ -f "$METRICS_FILE" ]; then
      mv "$METRICS_FILE" "$METRICS_FILE.backup-$(date +%Y%m%d)"
      echo "✓ Metrics cleared (backup created)"
    else
      echo "No metrics to clear"
    fi
    ;;

  *)
    echo "Usage: $0 {record|start|end|analyze|report|export|clear}"
    echo ""
    echo "Commands:"
    echo "  record <phase> <duration> [status] [retry] [files]"
    echo "         - Record a completed phase metric"
    echo "  start <phase>"
    echo "         - Start tracking a phase"
    echo "  end <phase> [status] [retry]"
    echo "         - End tracking and record metric"
    echo "  analyze"
    echo "         - Show metrics analysis"
    echo "  report"
    echo "         - Generate HTML report"
    echo "  export"
    echo "         - Export to CSV"
    echo "  clear"
    echo "         - Clear metrics (creates backup)"
    exit 1
    ;;
esac
