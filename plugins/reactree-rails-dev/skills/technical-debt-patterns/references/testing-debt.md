# Testing Debt Reference

Comprehensive guide to detecting and addressing testing deficiencies in Rails applications.

## Coverage Gaps

### Measuring Coverage

**SimpleCov Setup**:
```ruby
# spec/spec_helper.rb (at the very top!)
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Jobs', 'app/jobs'

  minimum_coverage 80
  refuse_coverage_drop
end
```

**Running with Coverage**:
```bash
# Generate coverage report
COVERAGE=true bundle exec rspec

# View report
open coverage/index.html
```

### Identifying Low Coverage Areas

```bash
# Parse SimpleCov output
cat coverage/.last_run.json | jq '.result.covered_percent'

# Find files with low coverage (from HTML report)
grep -A2 "covered_percent" coverage/.resultset.json | \
  grep -E '"[0-9]+\.[0-9]+"' | sort -t'"' -k2 -n | head -20
```

### Coverage Thresholds

| Level | Coverage | Risk |
|-------|----------|------|
| Critical | < 50% | High - bugs likely undetected |
| High | 50-70% | Moderate - gaps in edge cases |
| Medium | 70-85% | Acceptable for most projects |
| Good | 85-95% | Well-tested |
| Excellent | > 95% | May have diminishing returns |

### Branch vs. Line Coverage

```ruby
# Line coverage: covers the line
def process(value)
  value > 0 ? positive_path : negative_path  # Covered if called once
end

# Branch coverage: covers each branch
# Test 1: process(1)  -> positive_path covered
# Test 2: process(-1) -> negative_path covered
# Both tests needed for full branch coverage
```

---

## Missing Test Scenarios

### Detection Patterns

**Models without specs**:
```bash
# Find models without corresponding spec files
for model in app/models/*.rb; do
  spec="spec/models/$(basename $model .rb)_spec.rb"
  if [ ! -f "$spec" ]; then
    echo "Missing: $spec"
  fi
done
```

**Controllers without request specs**:
```bash
# Find controllers without request specs
for ctrl in app/controllers/*.rb; do
  name=$(basename $ctrl _controller.rb)
  spec="spec/requests/${name}_spec.rb"
  if [ ! -f "$spec" ]; then
    echo "Missing: $spec"
  fi
done
```

**Services without specs**:
```bash
# Find services without specs
for service in app/services/**/*.rb; do
  spec="spec/services/$(echo $service | sed 's/app\/services\///' | sed 's/\.rb/_spec.rb/')"
  if [ ! -f "$spec" ]; then
    echo "Missing: $spec"
  fi
done
```

### Common Missing Scenarios

| Area | Often Missing | Example |
|------|---------------|---------|
| Models | Edge cases in validations | Empty string vs nil |
| Controllers | Error handling paths | 404, 422, 500 responses |
| Services | Failure scenarios | External API timeout |
| Jobs | Retry behavior | Job fails then succeeds |
| Mailers | Attachment handling | Large attachment |

### Test Pyramid Ratios

Ideal distribution:
```
           /\
          /  \  E2E/System (10%)
         /----\
        /      \  Integration (20%)
       /--------\
      /          \  Unit (70%)
     --------------
```

**Checking Ratio**:
```bash
# Count test types
echo "Unit tests:"
find spec/models spec/services spec/lib -name "*_spec.rb" | wc -l

echo "Integration tests:"
find spec/requests spec/controllers -name "*_spec.rb" | wc -l

echo "System tests:"
find spec/system spec/features -name "*_spec.rb" | wc -l
```

---

## Flaky Tests

### Detection

**Track failures over time**:
```bash
# Run tests multiple times
for i in {1..10}; do
  bundle exec rspec --format failures > "failures_$i.txt" 2>&1
done

# Find inconsistent failures
sort failures_*.txt | uniq -c | sort -rn | head -20
```

**RSpec retry gem**:
```ruby
# Gemfile
gem 'rspec-retry'

# spec/spec_helper.rb
require 'rspec/retry'

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.default_retry_count = 3

  # Tag flaky tests
  config.around :each, :flaky do |ex|
    ex.run_with_retry retry: 3
  end
end
```

### Common Causes

| Cause | Symptom | Fix |
|-------|---------|-----|
| Time-dependent | Fails at midnight | Use `travel_to` |
| Order-dependent | Fails in random order | Fix data pollution |
| External services | Timeout failures | Use VCR/WebMock |
| Database state | Intermittent failures | Use transactions/truncation |
| Async behavior | Race conditions | Use `have_enqueued_job` |

### Time-Dependent Tests

```ruby
# BAD - Flaky around midnight
it 'shows today' do
  expect(Report.today.date).to eq(Date.today)
end

# GOOD - Frozen time
it 'shows today' do
  travel_to Time.zone.local(2024, 1, 15, 12, 0, 0) do
    expect(Report.today.date).to eq(Date.new(2024, 1, 15))
  end
end
```

### Order-Dependent Tests

```ruby
# BAD - Leaks state
describe User do
  it 'creates user' do
    User.create!(name: 'Test')
    expect(User.count).to eq(1)  # Fails if other tests created users
  end
end

# GOOD - Clean assertions
describe User do
  it 'creates user' do
    expect { User.create!(name: 'Test') }.to change(User, :count).by(1)
  end
end
```

---

## Slow Tests

### Detection

```bash
# RSpec profiling
bundle exec rspec --profile 10

# Output:
# Top 10 slowest examples:
#   User#full_name returns full name
#     0.5 seconds ./spec/models/user_spec.rb:15
```

### Common Causes

| Cause | Detection | Fix |
|-------|-----------|-----|
| Database writes | Many INSERT statements | Use `build_stubbed` |
| External calls | Network delays | Mock external services |
| File I/O | Disk operations | Use StringIO |
| Heavy setup | Long `before` blocks | Use `let_it_be` or shared contexts |
| Sleep calls | Explicit waits | Remove or mock time |

### Optimization Strategies

**Use `build_stubbed` over `create`**:
```ruby
# SLOW - Hits database
let(:user) { create(:user) }

# FAST - In-memory
let(:user) { build_stubbed(:user) }
```

**Use `let_it_be` (test-prof gem)**:
```ruby
# SLOW - Creates user for each example
let(:user) { create(:user) }

# FAST - Creates once, reuses
let_it_be(:user) { create(:user) }
```

**Batch database operations**:
```ruby
# SLOW - Multiple queries
before do
  create(:user)
  create(:user)
  create(:user)
end

# FASTER - Batch insert
before do
  User.insert_all([
    { name: 'User 1' },
    { name: 'User 2' },
    { name: 'User 3' }
  ])
end
```

---

## Test Quality Issues

### Missing Assertions

```ruby
# BAD - No assertions (false positive)
it 'processes order' do
  order = create(:order)
  OrderProcessor.new(order).process
end

# GOOD - Explicit assertions
it 'processes order' do
  order = create(:order, status: 'pending')

  OrderProcessor.new(order).process

  expect(order.reload.status).to eq('completed')
  expect(order.processed_at).to be_present
end
```

### Over-Mocking

```ruby
# BAD - Mocks too much, doesn't test real behavior
it 'charges customer' do
  customer = double('customer', charge: true)
  expect(customer).to receive(:charge).with(100)

  PaymentService.new(customer).charge(100)
end

# GOOD - Test real behavior with integration
it 'charges customer' do
  customer = create(:customer, balance: 0)

  PaymentService.new(customer).charge(100)

  expect(customer.reload.balance).to eq(-100)
end
```

### Testing Implementation Details

```ruby
# BAD - Tests implementation
it 'calls private method' do
  service = PaymentService.new
  expect(service).to receive(:calculate_fee).and_return(10)
  service.process
end

# GOOD - Tests behavior
it 'includes fee in total' do
  service = PaymentService.new(amount: 100)

  result = service.process

  expect(result.total).to eq(110)  # 100 + 10 fee
end
```

---

## Severity Scoring

| Issue | Impact | Severity |
|-------|--------|----------|
| Coverage < 50% on core logic | Bugs in production | Critical |
| No tests for payment processing | Financial risk | Critical |
| Flaky tests in CI | Blocked deploys | High |
| Slow test suite (>15 min) | Developer productivity | High |
| Missing edge case tests | Unhandled errors | Medium |
| Test pyramid inverted | Slow feedback | Medium |
| Minor coverage gaps | Technical debt | Low |

---

## Test Debt Remediation

### Quick Wins

1. **Add missing model specs** for validations
2. **Mock external services** to fix flaky tests
3. **Use `travel_to`** for time-dependent tests
4. **Replace `create` with `build_stubbed`** where possible

### Systematic Approach

```bash
# 1. Identify gaps
COVERAGE=true bundle exec rspec
open coverage/index.html

# 2. Prioritize by risk
# - Core business logic first
# - User-facing features second
# - Admin/internal features third

# 3. Track progress
bd create --type epic --title "Improve Test Coverage to 85%"
bd create --type task --title "Add Order model specs" --deps EPIC-ID
bd create --type task --title "Add PaymentService specs" --deps EPIC-ID
```

### CI Enforcement

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: COVERAGE=true bundle exec rspec

- name: Check coverage threshold
  run: |
    COVERAGE=$(cat coverage/.last_run.json | jq '.result.covered_percent')
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 80% threshold"
      exit 1
    fi
```
