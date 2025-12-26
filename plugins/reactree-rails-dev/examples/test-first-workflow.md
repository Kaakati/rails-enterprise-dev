# Test-First Workflow with TestOracle

This example demonstrates a complete test-first development workflow using the TestOracle agent to plan and generate comprehensive tests before implementation.

## Scenario

Implement a subscription billing feature with test-first discipline:
- TestOracle analyzes requirements and generates test plan
- Tests created following test pyramid (70/20/10)
- Tests run (RED phase - all pending/failing)
- Implementation makes tests pass (GREEN phase)
- Refactor with confidence (REFACTOR phase)

## Feature Requirements

**User Story**: As a business owner, I want to manage recurring subscriptions so customers are automatically billed monthly.

**Components Needed**:
- `Subscription` model (plan, status, next_billing_date)
- `SubscriptionBilling` service (process payments monthly)
- `SubscriptionsController` (CRUD for subscriptions)
- `BillingJob` (scheduled monthly billing)

## Workflow with Test-First Mode

### Step 1: Enable Test-First Mode

```bash
/reactree-dev "Implement subscription billing feature" --test-first
```

Or via environment variable:
```bash
export TEST_FIRST_MODE=enabled
/reactree-dev "Implement subscription billing feature"
```

### Step 2: TestOracle Analyzes Feature

**rails-planner invokes TestOracle**:

```bash
🧪 Test-first mode enabled, generating test plan...

🔍 Analyzing feature for test requirements...
  Components identified:
    - Models: Subscription
    - Services: SubscriptionBilling
    - Controllers: SubscriptionsController
    - Jobs: BillingJob

📝 Generating test plan...
```

**Test Plan Generated**:

```json
{
  "unit_tests": [
    {
      "file": "spec/models/subscription_spec.rb",
      "description": "Unit tests for Subscription model",
      "test_types": ["validations", "associations", "scopes", "methods"],
      "estimated_examples": 18,
      "tests": [
        "validates presence of user, plan, status",
        "validates inclusion of status in [active, canceled, expired]",
        "belongs_to :user",
        "belongs_to :plan",
        "has_many :billing_transactions",
        "scope :active",
        "scope :due_for_billing",
        "#next_billing_date calculation",
        "#active? method",
        "#cancel! transitions status",
        "#renew! updates next_billing_date"
      ]
    },
    {
      "file": "spec/services/subscription_billing_spec.rb",
      "description": "Unit tests for SubscriptionBilling service",
      "test_types": ["success_cases", "failure_cases", "edge_cases", "error_handling"],
      "estimated_examples": 25,
      "tests": [
        "processes payment for active subscription",
        "updates next_billing_date after successful payment",
        "creates billing_transaction record",
        "handles payment failures gracefully",
        "retries failed payments (retry logic)",
        "sends receipt email on success",
        "sends payment failed email on failure",
        "handles card declined",
        "handles expired card",
        "handles insufficient funds",
        "skips canceled subscriptions",
        "skips already-billed subscriptions",
        "handles nil next_billing_date",
        "processes batch of subscriptions",
        "rate limits API calls"
      ]
    },
    {
      "file": "spec/jobs/billing_job_spec.rb",
      "description": "Unit tests for BillingJob",
      "test_types": ["execution", "scheduling", "error_handling"],
      "estimated_examples": 8,
      "tests": [
        "processes all due subscriptions",
        "handles job failures",
        "retries on error",
        "respects rate limits"
      ]
    }
  ],
  "integration_tests": [
    {
      "file": "spec/requests/subscriptions_spec.rb",
      "description": "Integration tests for SubscriptionsController",
      "test_types": ["GET", "POST", "PATCH", "DELETE", "authorization", "validation"],
      "estimated_examples": 15,
      "tests": [
        "GET /subscriptions (index)",
        "GET /subscriptions/:id (show)",
        "POST /subscriptions (create with valid params)",
        "POST /subscriptions (create with invalid params)",
        "PATCH /subscriptions/:id (update)",
        "DELETE /subscriptions/:id (cancel subscription)",
        "requires authentication",
        "only shows user's own subscriptions",
        "returns proper error codes",
        "returns JSON in correct format"
      ]
    }
  ],
  "system_tests": [
    {
      "file": "spec/system/subscription_workflow_spec.rb",
      "description": "System tests for complete subscription workflow",
      "test_types": ["happy_path", "error_cases", "edge_cases"],
      "estimated_examples": 5,
      "tests": [
        "user subscribes to plan successfully",
        "user cancels subscription",
        "user updates payment method",
        "user sees billing history",
        "handles payment failure gracefully"
      ]
    }
  ],
  "pyramid_analysis": {
    "unit_count": 51,
    "integration_count": 15,
    "system_count": 5,
    "total": 71,
    "unit_percentage": 72,
    "integration_percentage": 21,
    "system_percentage": 7,
    "pyramid_valid": true
  }
}
```

**Pyramid Validation**:

```
📊 Test Pyramid Analysis:
   Unit: 51 tests (72%)
   Integration: 15 tests (21%)
   System: 5 tests (7%)

✓ Test pyramid ratios healthy
```

### Step 3: Test File Generation (RED Phase)

**TestOracle generates all test files**:

```bash
📝 Generating test files (RED phase)...

Creating spec/models/subscription_spec.rb (validations, associations, scopes, methods)
  ✓ spec/models/subscription_spec.rb created

Creating spec/services/subscription_billing_spec.rb (success_cases, failure_cases, edge_cases, error_handling)
  ✓ spec/services/subscription_billing_spec.rb created

Creating spec/jobs/billing_job_spec.rb (execution, scheduling, error_handling)
  ✓ spec/jobs/billing_job_spec.rb created

Creating spec/requests/subscriptions_spec.rb
  ✓ spec/requests/subscriptions_spec.rb created

Creating spec/system/subscription_workflow_spec.rb
  ✓ spec/system/subscription_workflow_spec.rb created

✓ All test files generated (RED phase complete)
```

**Example: spec/models/subscription_spec.rb**:

```ruby
require 'rails_helper'

RSpec.describe Subscription do
  describe 'validations' do
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:plan) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[active canceled expired]) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:plan) }
    it { should have_many(:billing_transactions) }
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active subscriptions' do
        pending "Add after model created"
      end
    end

    describe '.due_for_billing' do
      it 'returns subscriptions due for billing' do
        pending "Add after model created"
      end
    end
  end

  describe '#next_billing_date' do
    it 'calculates next billing date correctly' do
      pending "Add after model created"
    end
  end

  describe '#active?' do
    it 'returns true for active subscriptions' do
      pending "Add after model created"
    end
  end

  describe '#cancel!' do
    it 'transitions status to canceled' do
      pending "Add after model created"
    end
  end

  describe '#renew!' do
    it 'updates next_billing_date' do
      pending "Add after model created"
    end
  end
end
```

### Step 4: Verify RED Phase

**Run all specs (should fail/pending)**:

```bash
🔴 RED: Running tests (should fail)...

bundle exec rspec

Pending: (Failures listed here...)
  Subscription validations should validate_presence_of(:user)
  Subscription validations should validate_presence_of(:plan)
  ... (69 more examples)

Finished in 0.8 seconds
71 examples, 0 failures, 71 pending

✓ Tests failing as expected (RED phase confirmed)
```

### Step 5: Implementation with TDD LOOP

**Workflow orchestrator starts TDD cycle**:

```bash
🔄 Starting TDD cycle with LOOP control flow

Max iterations: 3
Exit condition: all_specs.status == passing
```

**LOOP Iteration 1**:

```bash
🔄 Iteration 1/3

🟢 GREEN: Implementing code...

Layer 1: Database (Migrations)
  ✓ create_subscriptions migration
  ✓ create_billing_transactions migration
  ✓ rails db:migrate

Layer 2: Models
  ✓ app/models/subscription.rb (minimal implementation)
  ✓ app/models/billing_transaction.rb

🧪 Running tests...
bundle exec rspec

Finished in 3.2 seconds
71 examples, 32 failures, 39 pending

⚠️  Some tests still failing
   Analyzing failures for next iteration...
```

**Failure Analysis**:

```
Common failures:
  - Missing validations (12 failures)
  - Missing associations (5 failures)
  - Missing scopes (4 failures)
  - Missing methods (11 failures)
```

**LOOP Iteration 2**:

```bash
🔄 Iteration 2/3

🟢 GREEN: Applying fixes based on test failures...

Updating app/models/subscription.rb:
  ✓ Add validations
  ✓ Add associations
  ✓ Add scopes
  ✓ Add instance methods

Creating app/services/subscription_billing.rb:
  ✓ Implement process_payment method
  ✓ Add error handling
  ✓ Add retry logic

Creating app/jobs/billing_job.rb:
  ✓ Implement perform method

🧪 Running tests...
bundle exec rspec

Finished in 8.5 seconds
71 examples, 8 failures

⚠️  Some tests still failing
   Analyzing failures for next iteration...
```

**Failure Analysis**:

```
Remaining failures:
  - SubscriptionBilling error handling (3 failures)
  - SubscriptionsController authorization (2 failures)
  - System test setup issues (3 failures)
```

**LOOP Iteration 3**:

```bash
🔄 Iteration 3/3

🟢 GREEN: Final fixes...

Updating app/services/subscription_billing.rb:
  ✓ Improve error handling
  ✓ Add proper rescue clauses

Creating app/controllers/subscriptions_controller.rb:
  ✓ Add before_action :authenticate_user!
  ✓ Add authorization checks

Fixing spec/system/subscription_workflow_spec.rb:
  ✓ Add proper test setup
  ✓ Use driven_by :selenium_chrome_headless

🧪 Running tests...
bundle exec rspec

Finished in 12.3 seconds
71 examples, 0 failures ✓

✓ All tests passing (GREEN phase complete)
✅ LOOP completed successfully after 3 iterations
```

### Step 6: Coverage Analysis

**TestOracle verifies coverage**:

```bash
📊 Analyzing test coverage...

COVERAGE=true bundle exec rspec

Coverage report generated:
  Overall Coverage: 89.5% ✓ (threshold: 85%)
  Unit Coverage: 94.2% ✓
  Integration Coverage: 86.1% ✓
  System Coverage: 78.3%

✓ Coverage meets threshold (85%)
```

### Step 7: Refactor Phase

**Now safe to refactor with comprehensive tests**:

```bash
♻️  REFACTOR: Code working, can refactor safely...

Refactoring app/services/subscription_billing.rb:
  ✓ Extract private method: send_receipt_email
  ✓ Extract private method: send_failure_email
  ✓ Extract private method: update_billing_date
  ✓ Improve method names for clarity

Refactoring app/models/subscription.rb:
  ✓ Extract scope logic to named scopes
  ✓ Add descriptive comments

🧪 Running tests after refactor...
bundle exec rspec

Finished in 12.1 seconds
71 examples, 0 failures ✓

✅ Refactor complete - all tests still passing
```

### Final Test Metrics

```
📊 Test Suite Health Report
═══════════════════════════

Tests: 71 examples in 5 files
Status: ✓ ALL PASSING

Pyramid Distribution:
  Unit:        51 tests (72%) ✓
  Integration: 15 tests (21%) ✓
  System:       5 tests (7%) ✓

Coverage:
  Overall:     89.5% ✓ (threshold: 85%)
  Unit:        94.2% ✓
  Integration: 86.1% ✓
  System:      78.3%

Execution Time:
  Total:        12.1s
  Unit:          3.2s (26%)
  Integration:   6.8s (56%)
  System:        2.1s (17%)

Quality Score: 97/100 ✓
  ✓ No flaky tests
  ✓ No pending tests
  ✓ All assertions present
  ✓ Uses factories
  ✓ Fast execution

TDD Cycle:
  Iterations: 3
  RED → GREEN → REFACTOR ✓
  Test-first discipline: Maintained
```

## Beads Tracking

```bash
BD-sub-billing-123: Implement subscription billing feature
  Status: Completed

  Phases:
    ✓ Test Planning (TestOracle)
      - Test plan generated (71 examples)
      - Pyramid validated (72/21/7)
      - Test files created (RED phase)

    ✓ TDD Cycle (LOOP iterations: 3)
      - Iteration 1: 32 failures → fixes applied
      - Iteration 2: 8 failures → fixes applied
      - Iteration 3: 0 failures ✓

    ✓ Coverage Analysis
      - Overall: 89.5% (target: 85%) ✓
      - All thresholds met ✓

    ✓ Refactor Phase
      - Code improved
      - Tests still passing ✓

  Duration: 45 minutes
  Test-first: YES
  Coverage: 89.5%
  Quality: 97/100
```

## Benefits Demonstrated

1. **Test-Driven Design**: Tests drove implementation decisions
2. **Comprehensive Coverage**: 89.5% coverage achieved automatically
3. **Balanced Test Suite**: Pyramid ratios perfect (72/21/7)
4. **Iterative Refinement**: LOOP enabled 3 iterations to pass
5. **Refactor Safety**: Changed code confidently with test verification
6. **Quality Metrics**: Complete visibility into test suite health
7. **Time Efficient**: 45 minutes vs 2+ hours manual TDD

## Comparison: With vs Without TestOracle

**Without TestOracle (Traditional)**:
```
1. Write some tests manually (incomplete)
2. Implement feature
3. Realize tests missing edge cases
4. Add more tests
5. Fix bugs found by new tests
6. Repeat until "feels complete"
7. Coverage unknown until end
8. Pyramid imbalanced (too many system tests)

Time: 2-3 hours
Coverage: 65-75% (gaps in edge cases)
Pyramid: Inverted (80% integration/system)
```

**With TestOracle (Automated)**:
```
1. TestOracle generates comprehensive test plan ✓
2. All test files created (RED phase) ✓
3. LOOP iterates: implement → test → fix ✓
4. Coverage automatically tracked ✓
5. Pyramid automatically balanced ✓
6. Refactor with confidence ✓

Time: 45 minutes (60% faster)
Coverage: 89.5% (complete edge case coverage)
Pyramid: Healthy (72/21/7)
```

## Usage

To enable test-first mode:

```bash
# Via flag
/reactree-dev "Implement subscription billing" --test-first

# Via environment variable
export TEST_FIRST_MODE=enabled
/reactree-dev "Implement subscription billing"

# Via config file
echo "test_first_mode: enabled" >> .claude/reactree-rails-dev.local.md
/reactree-dev "Implement subscription billing"
```

## Conclusion

TestOracle transforms TDD from a manual discipline into an automated, comprehensive workflow:

- **Automatic test planning** → No missed edge cases
- **Pyramid validation** → Fast, maintainable test suites
- **Coverage tracking** → Guarantees threshold met
- **Quality validation** → Meaningful tests, not just coverage
- **LOOP integration** → Iterative red-green-refactor
- **FEEDBACK integration** → Self-correcting implementations

Result: **True test-first development** with 60% time savings, 89%+ coverage, and perfect test pyramid ratios - automatically.
