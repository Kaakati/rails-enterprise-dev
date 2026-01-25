#!/bin/bash
# Manifest Generator for Claude Intent Detection
# Generates JSON manifests from agents/ and skills/ directories for Claude context
#
# Features:
# - Extracts name and description from YAML frontmatter
# - Caches manifests with 5-minute TTL
# - Outputs compact JSON for minimal token usage

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Cache configuration
CACHE_DIR="${HOME}/.cache/reactree-rails-dev"
CACHE_FILE="${CACHE_DIR}/intent-manifests.json"
CACHE_TTL=300  # 5 minutes in seconds

#==============================================================================
# CACHE MANAGEMENT
#==============================================================================

is_cache_valid() {
  if [ ! -f "$CACHE_FILE" ]; then
    return 1
  fi

  local cache_mtime
  local current_time

  # Get cache modification time (cross-platform)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  else
    cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  fi

  current_time=$(date +%s)
  local age=$((current_time - cache_mtime))

  if [ "$age" -lt "$CACHE_TTL" ]; then
    return 0
  fi
  return 1
}

get_cached_manifest() {
  if is_cache_valid; then
    cat "$CACHE_FILE"
    return 0
  fi
  return 1
}

save_to_cache() {
  local manifest="$1"
  mkdir -p "$CACHE_DIR"
  echo "$manifest" > "$CACHE_FILE"
}

invalidate_cache() {
  rm -f "$CACHE_FILE" 2>/dev/null || true
}

#==============================================================================
# YAML FRONTMATTER EXTRACTION
#==============================================================================

extract_frontmatter_field() {
  local file="$1"
  local field="$2"

  # Extract field from YAML frontmatter (between first two ---)
  # Handle multiline descriptions with |
  awk -v field="$field" '
    BEGIN { in_frontmatter = 0; in_field = 0; result = "" }
    /^---$/ {
      if (in_frontmatter == 0) {
        in_frontmatter = 1
        next
      } else {
        exit
      }
    }
    in_frontmatter == 1 {
      # Check if this line starts the field we want
      if ($0 ~ "^" field ":") {
        in_field = 1
        # Check for inline value or pipe/quoted
        sub("^" field ": *", "")
        if ($0 == "|" || $0 == ">") {
          # Multiline - collect following indented lines
          next
        } else {
          # Inline value - clean quotes
          gsub(/^["'\''"]|["'\''"]$/, "")
          result = $0
          in_field = 0
        }
        next
      }
      # Handle multiline content (indented continuation)
      if (in_field == 1 && /^[[:space:]]/) {
        # Part of multiline value
        sub(/^[[:space:]]+/, "")
        if (result != "") result = result " "
        result = result $0
        next
      }
      # Different field - stop collecting
      if (in_field == 1 && /^[a-zA-Z]/) {
        in_field = 0
      }
    }
    END { print result }
  ' "$file" | head -c 500  # Limit description length for token efficiency
}

#==============================================================================
# AGENT MANIFEST GENERATION
#==============================================================================

generate_agent_manifest() {
  local agents_dir="${PLUGIN_DIR}/agents"
  local first=true

  echo "["

  if [ -d "$agents_dir" ]; then
    for agent_file in "$agents_dir"/*.md; do
      [ -f "$agent_file" ] || continue

      local name
      local description

      name=$(extract_frontmatter_field "$agent_file" "name")
      description=$(extract_frontmatter_field "$agent_file" "description")

      # Skip if name is empty
      [ -z "$name" ] && continue

      # Escape JSON special characters
      description=$(echo "$description" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ' | sed 's/  */ /g')

      # Truncate description for token efficiency
      description=$(echo "$description" | head -c 200)

      if [ "$first" = true ]; then
        first=false
      else
        echo ","
      fi

      cat <<EOF
  {"name": "$name", "type": "agent", "description": "$description"}
EOF
    done
  fi

  echo "]"
}

#==============================================================================
# SKILL MANIFEST GENERATION
#==============================================================================

generate_skill_manifest() {
  local skills_dir="${PLUGIN_DIR}/skills"
  local first=true

  echo "["

  if [ -d "$skills_dir" ]; then
    for skill_dir in "$skills_dir"/*/; do
      [ -d "$skill_dir" ] || continue

      local skill_file="${skill_dir}SKILL.md"
      [ -f "$skill_file" ] || continue

      local name
      local description

      name=$(extract_frontmatter_field "$skill_file" "name")
      description=$(extract_frontmatter_field "$skill_file" "description")

      # Skip if name is empty
      [ -z "$name" ] && continue

      # Escape JSON special characters
      description=$(echo "$description" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ' | sed 's/  */ /g')

      # Truncate description for token efficiency
      description=$(echo "$description" | head -c 200)

      if [ "$first" = true ]; then
        first=false
      else
        echo ","
      fi

      cat <<EOF
  {"name": "$name", "type": "skill", "description": "$description"}
EOF
    done
  fi

  echo "]"
}

#==============================================================================
# COMBINED MANIFEST
#==============================================================================

generate_combined_manifest() {
  local agents
  local skills

  agents=$(generate_agent_manifest)
  skills=$(generate_skill_manifest)

  cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "agents": $agents,
  "skills": $skills
}
EOF
}

#==============================================================================
# MAIN
#==============================================================================

main() {
  local force_refresh=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --refresh|-r)
        force_refresh=true
        shift
        ;;
      --help|-h)
        echo "Usage: manifest-generator.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --refresh, -r    Force regeneration, ignore cache"
        echo "  --help, -h       Show this help message"
        exit 0
        ;;
      *)
        shift
        ;;
    esac
  done

  # Try cache first (unless forced refresh)
  if [ "$force_refresh" = false ]; then
    local cached
    cached=$(get_cached_manifest 2>/dev/null) && {
      echo "$cached"
      exit 0
    }
  fi

  # Generate fresh manifest
  local manifest
  manifest=$(generate_combined_manifest)

  # Save to cache
  save_to_cache "$manifest"

  # Output
  echo "$manifest"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
