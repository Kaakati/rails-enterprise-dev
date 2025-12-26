# TDD Workflow with LOOP Control Flow

This example demonstrates using the LOOP control flow node for Test-Driven Development with the ReAcTree plugin.

## Scenario

Implement a `PaymentService` for Stripe payment processing using TDD methodology:
- Write failing tests first
- Implement code to pass tests
- Iterate until all tests pass
- Max 3 iterations

## Workflow Definition

```json
{
  "workflow_name": "TDD Payment Service Implementation",
  "workflow_type": "feature_development",
  "root_node": {
    "type": "SEQUENCE",
    "children": [
      {
        "type": "ACTION",
        "skill": "write_test_spec",
        "description": "Write comprehensive test spec for PaymentService",
        "agent": "RSpec Specialist",
        "output": "spec/services/payment_service_spec.rb"
      },
      {
        "type": "LOOP",
        "node_id": "tdd-payment-service",
        "description": "Iterative test-fix cycle",
        "max_iterations": 3,
        "timeout_seconds": 600,
        "exit_on": "condition_true",
        "condition": {
          "type": "test_result",
          "key": "payment_service_spec.status",
          "operator": "equals",
          "value": "passing"
        },
        "children": [
          {
            "type": "ACTION",
            "skill": "rspec_run",
            "description": "Run RSpec tests for PaymentService",
            "target": "spec/services/payment_service_spec.rb",
            "agent": "RSpec Specialist"
          },
          {
            "type": "CONDITIONAL",
            "node_id": "check-test-status",
            "description": "Check if tests are passing or failing",
            "condition": {
              "type": "test_result",
              "key": "payment_service_spec.status",
              "operator": "equals",
              "value": "failing"
            },
            "true_branch": {
              "type": "ACTION",
              "skill": "implement_service",
              "description": "Implement/fix PaymentService code",
              "context": "Fix failing specs based on error messages",
              "agent": "Backend Lead",
              "output": "app/services/payment_service.rb"
            },
            "false_branch": {
              "type": "ACTION",
              "skill": "log_success",
              "description": "Log successful TDD cycle completion"
            }
          }
        ]
      },
      {
        "type": "ACTION",
        "skill": "verify_implementation",
        "description": "Final verification of payment service",
        "agent": "Chief Reviewer"
      }
    ]
  }
}
```

## Execution Flow

### Iteration 1

**Step 1: Write Test Spec**
```ruby
# spec/services/payment_service_spec.rb
RSpec.describe PaymentService do
  describe '.call' do
    context 'with valid payment details' do
      it 'processes payment successfully' do
        result = PaymentService.call(amount: 1000, token: 'tok_visa')
        expect(result).to be_success
        expect(result.charge_id).to be_present
      end

      it 'returns charge details' do
        result = PaymentService.call(amount: 1000, token: 'tok_visa')
        expect(result.amount).to eq(1000)
        expect(result.currency).to eq('usd')
      end
    end

    context 'with invalid payment details' do
      it 'returns failure with error message' do
        result = PaymentService.call(amount: -100, token: 'tok_visa')
        expect(result).to be_failure
        expect(result.error).to include('Amount must be positive')
      end

      it 'handles Stripe errors gracefully' do
        allow(Stripe::Charge).to receive(:create).and_raise(Stripe::CardError.new('Card declined', nil, nil))
        result = PaymentService.call(amount: 1000, token: 'tok_declined')
        expect(result).to be_failure
        expect(result.error).to include('Card declined')
      end
    end
  end
end
```

**Step 2: Run Tests (LOOP Iteration 1)**
```bash
🔄 Starting LOOP node: tdd-payment-service
   Max iterations: 3
   Timeout: 600s

🔄 Iteration 1/3
   Executing: Run RSpec tests
   ✓ Tests ran
```

**Output:**
```
Failures:

  1) PaymentService.call with valid payment details processes payment successfully
     Failure/Error: PaymentService.call(amount: 1000, token: 'tok_visa')

     NameError:
       uninitialized constant PaymentService
     # ./spec/services/payment_service_spec.rb:5

  2) PaymentService.call with valid payment details returns charge details
     [Same error...]

  3) PaymentService.call with invalid payment details returns failure with error message
     [Same error...]

  4) PaymentService.call with invalid payment details handles Stripe errors gracefully
     [Same error...]

Finished in 0.05 seconds
4 examples, 4 failures
```

**Step 3: Check Condition**
```
Condition: payment_service_spec.status == 'passing'? false
```

**Step 4: Execute True Branch (Fix Code)**
```bash
   Condition not met, executing true branch
   Executing: Implement PaymentService
   ✓ PaymentService created
```

**Implementation:**
```ruby
# app/services/payment_service.rb
class PaymentService
  include Callable

  Result = Struct.new(:success, :charge_id, :amount, :currency, :error, keyword_init: true) do
    def success?
      success
    end

    def failure?
      !success
    end
  end

  def initialize(amount:, token:)
    @amount = amount
    @token = token
  end

  def call
    return invalid_amount_error if amount <= 0

    charge = create_stripe_charge
    success_result(charge)
  rescue Stripe::CardError => e
    stripe_error_result(e)
  end

  private

  attr_reader :amount, :token

  def create_stripe_charge
    Stripe::Charge.create(
      amount: amount,
      currency: 'usd',
      source: token,
      description: 'Payment processed via PaymentService'
    )
  end

  def success_result(charge)
    Result.new(
      success: true,
      charge_id: charge.id,
      amount: charge.amount,
      currency: charge.currency
    )
  end

  def invalid_amount_error
    Result.new(
      success: false,
      error: 'Amount must be positive'
    )
  end

  def stripe_error_result(error)
    Result.new(
      success: false,
      error: error.message
    )
  end
end
```

### Iteration 2

**Step 1: Run Tests Again**
```bash
🔄 Iteration 2/3
   Executing: Run RSpec tests
   ✓ Tests ran
```

**Output:**
```
Finished in 0.52 seconds
4 examples, 0 failures
```

**Step 2: Check Condition**
```
Condition: payment_service_spec.status == 'passing'? true
✓ Exit condition met (condition = true)
```

**Result:**
```bash
✅ LOOP completed successfully after 2 iterations
```

### State Log

```jsonl
{"type":"loop_start","node_id":"tdd-payment-service","timestamp":"2025-01-21T10:00:00Z","max_iterations":3}
{"type":"loop_iteration","node_id":"tdd-payment-service","iteration":1,"condition_met":false,"elapsed":15,"test_result":"4 examples, 4 failures"}
{"type":"loop_iteration","node_id":"tdd-payment-service","iteration":2,"condition_met":true,"elapsed":28,"test_result":"4 examples, 0 failures"}
{"type":"loop_complete","node_id":"tdd-payment-service","iterations":2,"status":"success"}
```

## Working Memory Updates

During the workflow, these facts are stored in working memory:

```jsonl
{"timestamp":"2025-01-21T10:00:15Z","agent":"RSpec Specialist","knowledge_type":"test_result","key":"payment_service_spec.status","value":"failing","confidence":"verified"}
{"timestamp":"2025-01-21T10:00:20Z","agent":"Backend Lead","knowledge_type":"implementation","key":"payment_service.pattern","value":"Callable concern with Result struct","confidence":"verified"}
{"timestamp":"2025-01-21T10:00:28Z","agent":"RSpec Specialist","knowledge_type":"test_result","key":"payment_service_spec.status","value":"passing","confidence":"verified"}
{"timestamp":"2025-01-21T10:00:28Z","agent":"control-flow-manager","knowledge_type":"loop_status","key":"tdd-payment-service.complete","value":true,"confidence":"verified"}
```

## Beads Tracking

```bash
# Created beads issue
BD-abc7: Implement PaymentService with TDD

# Subtasks
BD-abc8: Write PaymentService test spec (completed)
BD-abc9: Iterate TDD cycle (in_progress → completed after 2 iterations)
BD-abc10: Final verification (pending)

# Final status
✅ BD-abc7 closed: PaymentService implementation complete with passing tests
```

## Benefits Demonstrated

1. **Iterative Refinement**: LOOP enabled red-green cycle without manual intervention
2. **Condition-Based Exit**: Automatically stopped when tests passed (2/3 iterations)
3. **State Persistence**: Full execution log for audit and debugging
4. **Memory Integration**: Test results stored and queryable
5. **Max Iteration Safety**: Would have stopped at 3 even if tests still failing
6. **Timeout Protection**: 600s timeout prevents infinite loops

## Alternative Scenarios

### Scenario: Max Iterations Reached

If tests still failing after 3 iterations:

```bash
🔄 Iteration 3/3
   Executing: Run RSpec tests
   ✓ Tests ran (4 examples, 1 failure)
   Condition: payment_service_spec.status == 'passing'? false
   Executing: Fix code
   ✓ Fixes applied

⚠️  LOOP exited: Max iterations (3) reached
```

**State:**
```jsonl
{"type":"loop_max_iterations","node_id":"tdd-payment-service","iterations":3,"status":"max_iterations"}
```

**Action:**
```bash
bd update BD-abc9 --status blocked
bd comment BD-abc9 "TDD cycle incomplete: Tests still failing after 3 iterations. Manual review needed."
```

### Scenario: Timeout Exceeded

If iteration takes too long:

```bash
🔄 Iteration 2/3
   Executing: Run RSpec tests
   ⏱️  Timeout exceeded (605s > 600s)
   Exiting loop with timeout status
```

**State:**
```jsonl
{"type":"loop_timeout","node_id":"tdd-payment-service","iteration":2,"elapsed":605}
```

## Usage

To execute this TDD workflow:

```bash
/reactree-dev "Implement PaymentService for Stripe with TDD"
```

Or explicitly specify LOOP control flow:

```bash
/reactree-feature "Payment processing service" --tdd --max-iterations 3
```

## Conclusion

This example demonstrates how LOOP control flow:
- Enables true TDD red-green-refactor cycles
- Provides safety with max iterations and timeouts
- Tracks all iterations for debugging and audit
- Integrates with beads for progress tracking
- Uses working memory for condition evaluation

The workflow completed in 2 iterations (30 seconds) vs. traditional approach requiring 3+ manual cycles.
