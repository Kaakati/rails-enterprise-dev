# Deprecation Tracking Reference

Comprehensive guide to tracking and managing deprecations in Rails applications.

## Rails Deprecation Warnings

### Detection

**From Logs**:
```bash
# Find deprecation warnings in development log
grep -i "DEPRECATION" log/development.log | sort | uniq -c | sort -rn

# Find deprecation warnings in test output
RAILS_ENV=test rails test 2>&1 | grep -i "DEPRECATION"

# Count unique deprecations
grep -i "DEPRECATION" log/development.log | \
  sed 's/\(DEPRECATION WARNING:.*\) (called.*/\1/' | \
  sort | uniq -c | sort -rn
```

**Real-time Detection**:
```ruby
# config/environments/development.rb
config.active_support.deprecation = :log

# Or raise immediately during development
config.active_support.deprecation = :raise

# Custom reporter
ActiveSupport::Deprecation.behavior = ->(message, callstack, deprecation_horizon, gem_name) {
  # Log to custom location or external service
  Rails.logger.warn("DEPRECATION: #{message}")
  # Or send to error tracking
  Sentry.capture_message(message, level: :warning, extra: { callstack: callstack.first(5) })
}
```

### Common Rails 7.x Deprecations

| Deprecation | Replacement | Version |
|-------------|-------------|---------|
| `before_action :method, if: -> { condition }` | Keep using, but check for changes | 7.1 |
| `ActiveRecord::Base.default_scope` | Use explicit scopes | 7.0 |
| `update_attributes` | `update` | 6.0 |
| `ActiveRecord::Base.configurations` hash access | Use `ActiveRecord::Base.configurations.configs_for` | 6.1 |
| `Rails.application.config.active_record.legacy_connection_handling` | Remove (deprecated in 7.0) | 7.0 |

### Tracking Deprecations

```ruby
# lib/deprecation_tracker.rb
class DeprecationTracker
  TRACKED_FILE = Rails.root.join('tmp', 'deprecations.json')

  class << self
    def track(message, callstack)
      deprecations = load_tracked
      key = message.gsub(/\s+/, ' ').strip[0..100]

      deprecations[key] ||= { count: 0, first_seen: Time.current, locations: [] }
      deprecations[key][:count] += 1
      deprecations[key][:last_seen] = Time.current
      deprecations[key][:locations] |= [callstack.first(3)]

      save_tracked(deprecations)
    end

    def report
      load_tracked.sort_by { |_, v| -v[:count] }
    end

    private

    def load_tracked
      return {} unless File.exist?(TRACKED_FILE)
      JSON.parse(File.read(TRACKED_FILE))
    rescue JSON::ParserError
      {}
    end

    def save_tracked(data)
      File.write(TRACKED_FILE, JSON.pretty_generate(data))
    end
  end
end

# config/initializers/deprecation_tracking.rb
if Rails.env.development? || Rails.env.test?
  ActiveSupport::Deprecation.behavior = ->(message, callstack, _, _) {
    DeprecationTracker.track(message, callstack)
    Rails.logger.warn(message)
  }
end
```

---

## Ruby Version Deprecations

### Detection

```bash
# Check current Ruby version
ruby --version

# Run with warnings enabled
RUBYOPT="-W:deprecated" rails server

# Or in specific script
ruby -W:deprecated script.rb
```

### Common Ruby 3.x Deprecations

| Deprecation | Version | Action |
|-------------|---------|--------|
| Keyword args with hash | 3.0 | Use explicit hash or double-splat |
| `URI.escape`/`URI.unescape` | 2.7 | Use `CGI.escape`/`CGI.unescape` |
| `Object#=~` | 3.2 | Use explicit matching |
| `Struct.new(:foo)` returning nil for missing | 3.2 | Raises instead |

### Keyword Argument Changes (Ruby 3.0)

**Deprecated**:
```ruby
def foo(key: 'default')
  puts key
end

# This warns in 2.7, errors in 3.0
foo({ key: 'value' })  # Passing hash as keyword args
```

**Fixed**:
```ruby
# Explicit double-splat
foo(**{ key: 'value' })

# Or explicit keywords
foo(key: 'value')
```

---

## Gem Deprecations and CVEs

### bundler-audit

```bash
# Install
gem install bundler-audit

# Check for CVEs
bundle-audit check

# Update vulnerability database
bundle-audit update

# Check and update in one command
bundle-audit check --update

# Output format for CI
bundle-audit check --format json
```

### Example Output

```
Name: actionpack
Version: 6.0.0
CVE: CVE-2020-8164
Criticality: High
URL: https://nvd.nist.gov/vuln/detail/CVE-2020-8164
Title: Possible Strong Parameters Bypass in ActionPack
Solution: upgrade to ~> 5.2.4.3, >= 6.0.3.1
```

### Tracking Outdated Gems

```bash
# List outdated gems
bundle outdated

# Only show strict version mismatches
bundle outdated --strict

# Output in parseable format
bundle outdated --parseable

# Check specific groups
bundle outdated --group development
```

### Automated CVE Checking

```yaml
# .github/workflows/security.yml
name: Security Check

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Run bundler-audit
        run: |
          gem install bundler-audit
          bundle-audit check --update
```

---

## Deprecation Severity Classification

### Severity Levels

| Level | Description | SLA |
|-------|-------------|-----|
| Critical | Security CVE, breaking in next minor | 1 sprint |
| High | Removed in next major version | 2 sprints |
| Medium | Soft deprecation, works but warned | Quarterly |
| Low | Cosmetic, no functional impact | Opportunistic |

### Prioritization Matrix

```
                    Impact
                High        Low
            ┌───────────┬───────────┐
      Soon  │  Critical │   High    │
Removal     ├───────────┼───────────┤
      Later │   Medium  │    Low    │
            └───────────┴───────────┘
```

---

## Migration Strategies

### Gradual Deprecation Removal

```ruby
# 1. Identify all deprecations
rake deprecations:report

# 2. Create tracking issue
# bd create --title "Address Rails 7.1 deprecations" --type task

# 3. Categorize and prioritize
# - Security-related: immediate
# - Will break in next upgrade: high priority
# - Soft warnings: lower priority

# 4. Fix in batches
# Group by type/area, fix related deprecations together

# 5. Verify in CI
# Ensure deprecation count doesn't increase
```

### Deprecation Budget

Set a maximum number of allowed deprecations:

```ruby
# spec/support/deprecation_budget.rb
RSpec.configure do |config|
  config.after(:suite) do
    if File.exist?(Rails.root.join('tmp', 'deprecations.json'))
      deprecations = JSON.parse(File.read(Rails.root.join('tmp', 'deprecations.json')))
      total = deprecations.values.sum { |v| v['count'] }

      max_allowed = ENV.fetch('DEPRECATION_BUDGET', 50).to_i

      if total > max_allowed
        warn "\n\nDEPRECATION BUDGET EXCEEDED!"
        warn "Found #{total} deprecations, max allowed: #{max_allowed}"
        warn "Run `rake deprecations:report` for details"
        exit 1 if ENV['STRICT_DEPRECATIONS']
      end
    end
  end
end
```

---

## Reporting and Monitoring

### Deprecation Report Rake Task

```ruby
# lib/tasks/deprecations.rake
namespace :deprecations do
  desc "Generate deprecation report"
  task report: :environment do
    file = Rails.root.join('tmp', 'deprecations.json')

    unless File.exist?(file)
      puts "No deprecations tracked. Run tests first."
      exit
    end

    data = JSON.parse(File.read(file))

    puts "=" * 60
    puts "DEPRECATION REPORT"
    puts "=" * 60
    puts ""

    data.sort_by { |_, v| -v['count'] }.each do |message, info|
      puts "#{info['count']}x #{message[0..80]}"
      puts "   First seen: #{info['first_seen']}"
      puts "   Locations: #{info['locations'].first(2).join(', ')}"
      puts ""
    end

    total = data.values.sum { |v| v['count'] }
    puts "=" * 60
    puts "TOTAL: #{total} deprecations across #{data.size} unique messages"
  end

  desc "Clear tracked deprecations"
  task clear: :environment do
    file = Rails.root.join('tmp', 'deprecations.json')
    File.delete(file) if File.exist?(file)
    puts "Deprecation tracking cleared"
  end
end
```

### Integration with Beads

```bash
# Create deprecation tracking epic
bd create --type epic \
  --title "Rails 8.0 Upgrade: Address Deprecations" \
  --description "Track and fix all deprecation warnings before Rails 8.0 upgrade"

# Create individual tasks for each category
bd create --type task \
  --title "Fix ActiveRecord deprecations" \
  --deps "EPIC-ID" \
  --priority 2

bd create --type task \
  --title "Update bundler-audit CVEs" \
  --deps "EPIC-ID" \
  --priority 1
```
