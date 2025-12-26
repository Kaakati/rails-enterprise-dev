# TDD Workflow with FEEDBACK Edges

This example demonstrates using FEEDBACK edges for test-driven development where tests discover missing implementations and trigger parent nodes to fix them.

## Scenario

Implement a `PaymentService` with comprehensive validations using true TDD:
- Write specs first (with feedback enabled)
- Implement minimal model
- Tests discover missing validations and associations
- Tests send FEEDBACK to model creation node
- Model node re-executes with feedback, adds missing pieces
- Tests re-run and pass

## Workflow Definition

```json
{
  "workflow_name": "TDD Payment Service with Feedback",
  "workflow_type": "feature_development",
  "root_node": {
    "type": "SEQUENCE",
    "children": [
      {
        "type": "ACTION",
        "node_id": "write-payment-specs",
        "skill": "write_comprehensive_specs",
        "description": "Write comprehensive RSpec tests for Payment model",
        "agent": "RSpec Specialist",
        "output": "spec/models/payment_spec.rb"
      },
      {
        "type": "ACTION",
        "node_id": "create-payment-model",
        "skill": "rails_generate_model",
        "description": "Generate minimal Payment model",
        "args": "Payment amount:decimal status:string user:references",
        "agent": "Data Lead",
        "output": "app/models/payment.rb",
        "feedback_enabled": true
      },
      {
        "type": "ACTION",
        "node_id": "run-payment-specs",
        "skill": "rspec_run_model",
        "description": "Run Payment specs and provide feedback on failures",
        "args": "Payment",
        "agent": "RSpec Specialist",
        "feedback_enabled": true
      },
      {
        "type": "CONDITIONAL",
        "node_id": "check-specs-passing",
        "description": "Check if specs are passing",
        "condition": {
          "type": "test_result",
          "key": "payment_spec.status",
          "operator": "equals",
          "value": "passing"
        },
        "true_branch": {
          "type": "ACTION",
          "skill": "log_success",
          "description": "All specs passing, proceed to service"
        },
        "false_branch": {
          "type": "ACTION",
          "skill": "log_failure",
          "description": "Specs failed even after feedback - manual review needed"
        }
      }
    ]
  }
}
```

## Execution Flow

### Step 1: Write Comprehensive Specs

**RSpec Specialist** creates comprehensive tests:

```ruby
# spec/models/payment_spec.rb
require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:invoice).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[pending completed failed refunded]) }
    it { should validate_presence_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid').for(:email) }
  end

  describe 'scopes' do
    it 'returns only completed payments' do
      # ... scope tests
    end
  end

  describe '#refundable?' do
    it 'returns true for completed payments' do
      # ... method tests
    end
  end
end
```

**Output**:
```
✓ spec/models/payment_spec.rb created (20 examples)
```

### Step 2: Generate Minimal Payment Model

**Data Lead** creates basic model:

```ruby
# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :user
end

# db/migrate/20250121100000_create_payments.rb
class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.decimal :amount, precision: 10, scale: 2
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
```

**Output**:
```
✓ app/models/payment.rb created
✓ db/migrate/20250121100000_create_payments.rb created
✓ Migration ran successfully
```

### Step 3: Run Payment Specs (Round 1)

**RSpec Specialist** runs tests:

```bash
bundle exec rspec spec/models/payment_spec.rb
```

**Output**:
```
Failures:

  1) Payment associations should belong_to invoice.optional
     Failure/Error: it { should belong_to(:invoice).optional }
       Expected Payment to have a belongs_to association called invoice (no association called invoice)

  2) Payment validations should validate_presence_of amount
     Failure/Error: it { should validate_presence_of(:amount) }
       Payment did not properly validate that :amount cannot be empty/falsy

  3) Payment validations should validate_numericality_of amount
     Failure/Error: it { should validate_numericality_of(:amount).is_greater_than(0) }
       Expected Payment to validate that :amount looks like a number

  4) Payment validations should validate_presence_of status
     Failure/Error: it { should validate_presence_of(:status) }
       Payment did not properly validate that :status cannot be empty/falsy

  5) Payment validations should validate_inclusion_of status
     Failure/Error: it { should validate_inclusion_of(:status).in_array(%w[pending completed failed refunded]) }
       Expected Payment to validate that :status is either "pending", "completed", "failed", or "refunded"

  6) Payment validations should validate_presence_of email
     Failure/Error: it { should validate_presence_of(:email) }
       Expected Payment to have a required attribute named email

  ... (10 more failures)

Finished in 0.5 seconds
20 examples, 16 failures
```

### Step 4: RSpec Specialist Sends FEEDBACK

**Analyzing failures, sends feedback**:

```json
{
  "type": "FEEDBACK",
  "from_node": "run-payment-specs",
  "to_node": "create-payment-model",
  "feedback_type": "FIX_REQUEST",
  "message": "PaymentSpec has 16 failures - missing validations, associations, and attributes",
  "suggested_fix": "Add missing components to Payment model",
  "priority": "critical",
  "artifacts": ["spec/models/payment_spec.rb"],
  "missing_components": {
    "associations": ["belongs_to :invoice, optional: true"],
    "validations": [
      "validates :amount, presence: true, numericality: { greater_than: 0 }",
      "validates :status, presence: true, inclusion: { in: %w[pending completed failed refunded] }",
      "validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }"
    ],
    "attributes": ["email:string"],
    "methods": ["refundable?"],
    "scopes": ["scope :completed, -> { where(status: 'completed') }"]
  }
}
```

**Feedback queued**:
```
📢 Feedback sent: run-payment-specs → create-payment-model (FIX_REQUEST)
✓ Feedback queued at 2025-01-21T10:05:00Z
```

### Step 5: Workflow Detects Feedback

**Workflow orchestrator** checks queue after tests:

```bash
check_feedback_queue()  # Returns 1 (feedback pending)

# Output:
📢 Detected 1 pending feedback messages
```

### Step 6: Process Feedback Queue

**Workflow delegates to feedback-coordinator**:

```bash
process_feedback_queue()
```

**Output**:
```
🔄 Processing feedback queue...
Processing: run-payment-specs → create-payment-model (FIX_REQUEST)

🔄 Starting fix-verify cycle: create-payment-model → run-payment-specs
🔧 Re-executing parent node with feedback context...
```

### Step 7: Model Node Re-executes with Feedback

**Data Lead** reads feedback from working memory:

```bash
# Read feedback
feedback=$(read_memory "feedback.create-payment-model")

echo "📢 Feedback received for this node:"
echo "$feedback" | jq '.'

# Output:
{
  "feedback_type": "FIX_REQUEST",
  "message": "PaymentSpec has 16 failures - missing validations, associations, and attributes",
  "suggested_fix": "Add missing components to Payment model",
  "missing_components": {
    "associations": ["belongs_to :invoice, optional: true"],
    "validations": [...],
    "attributes": ["email:string"],
    "methods": ["refundable?"],
    "scopes": [...]
  }
}
```

**Applying fixes**:

```ruby
# app/models/payment.rb (updated)
class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :invoice, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed failed refunded] }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :completed, -> { where(status: 'completed') }

  def refundable?
    completed? && created_at > 30.days.ago
  end

  private

  def completed?
    status == 'completed'
  end
end
```

**Migration update**:
```ruby
# db/migrate/20250121100000_create_payments.rb (updated)
class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.decimal :amount, precision: 10, scale: 2
      t.string :status
      t.string :email  # ADDED
      t.references :user, null: false, foreign_key: true
      t.references :invoice, foreign_key: true  # ADDED

      t.timestamps
    end
  end
end
```

**Output**:
```
✓ Payment model updated with feedback fixes
✓ Migration updated
✓ rails db:migrate:reset executed
✓ Parent fix complete
```

### Step 8: Verify Fix by Re-running Tests

**RSpec Specialist** re-executes specs:

```bash
bundle exec rspec spec/models/payment_spec.rb
```

**Output**:
```
Finished in 0.8 seconds
20 examples, 0 failures ✓
```

**Verification successful**:
```
✅ Fix verified successfully
✅ Feedback marked as resolved
```

### Step 9: CONDITIONAL Check

**Workflow checks condition**:

```bash
🔀 Evaluating CONDITIONAL node: check-specs-passing
   Condition: payment_spec.status == 'passing'
   ✓ Condition true (20/20 tests passing)

Executing true branch: All specs passing, proceed to service
```

## Working Memory Updates

**Timeline of memory writes**:

```jsonl
{"timestamp":"2025-01-21T10:00:00Z","agent":"RSpec Specialist","key":"payment_spec.created","value":true,"confidence":"verified"}
{"timestamp":"2025-01-21T10:02:00Z","agent":"Data Lead","key":"payment_model.created","value":true,"confidence":"verified"}
{"timestamp":"2025-01-21T10:05:00Z","agent":"RSpec Specialist","key":"payment_spec.status","value":"failing","confidence":"verified"}
{"timestamp":"2025-01-21T10:05:00Z","agent":"RSpec Specialist","key":"payment_spec.failures","value":16,"confidence":"verified"}
{"timestamp":"2025-01-21T10:08:00Z","agent":"Data Lead","key":"payment_model.updated_with_feedback","value":true,"confidence":"verified"}
{"timestamp":"2025-01-21T10:10:00Z","agent":"RSpec Specialist","key":"payment_spec.status","value":"passing","confidence":"verified"}
{"timestamp":"2025-01-21T10:10:00Z","agent":"feedback-coordinator","key":"feedback.resolved","value":true,"confidence":"verified"}
```

## Feedback State Log

**File**: `.claude/reactree-feedback.jsonl`

```jsonl
{"timestamp":"2025-01-21T10:05:00Z","from_node":"run-payment-specs","to_node":"create-payment-model","feedback_type":"FIX_REQUEST","message":"PaymentSpec has 16 failures - missing validations, associations, and attributes","suggested_fix":"Add missing components to Payment model","priority":"critical","status":"queued","round":1}
{"timestamp":"2025-01-21T10:06:00Z","from_node":"run-payment-specs","to_node":"create-payment-model","status":"delivered"}
{"timestamp":"2025-01-21T10:06:30Z","from_node":"run-payment-specs","to_node":"create-payment-model","status":"processing"}
{"timestamp":"2025-01-21T10:08:00Z","from_node":"run-payment-specs","to_node":"create-payment-model","status":"verifying"}
{"timestamp":"2025-01-21T10:10:00Z","from_node":"run-payment-specs","to_node":"create-payment-model","status":"resolved","resolved_at":"2025-01-21T10:10:00Z"}
```

## Execution State Log

**File**: `.claude/reactree-state.jsonl`

```jsonl
{"type":"node_start","node_id":"write-payment-specs","timestamp":"2025-01-21T10:00:00Z"}
{"type":"node_complete","node_id":"write-payment-specs","status":"success","timestamp":"2025-01-21T10:01:00Z"}
{"type":"node_start","node_id":"create-payment-model","timestamp":"2025-01-21T10:01:30Z"}
{"type":"node_complete","node_id":"create-payment-model","status":"success","timestamp":"2025-01-21T10:02:00Z"}
{"type":"node_start","node_id":"run-payment-specs","timestamp":"2025-01-21T10:02:30Z"}
{"type":"test_result","key":"payment_spec.status","status":"failing","failures":16,"timestamp":"2025-01-21T10:05:00Z"}
{"type":"feedback_sent","from":"run-payment-specs","to":"create-payment-model","type":"FIX_REQUEST","timestamp":"2025-01-21T10:05:00Z"}
{"type":"node_complete","node_id":"run-payment-specs","status":"failed_with_feedback","timestamp":"2025-01-21T10:05:30Z"}
{"type":"feedback_processing_start","timestamp":"2025-01-21T10:06:00Z"}
{"type":"node_restart","node_id":"create-payment-model","reason":"feedback","timestamp":"2025-01-21T10:06:30Z"}
{"type":"node_complete","node_id":"create-payment-model","status":"success","timestamp":"2025-01-21T10:08:00Z"}
{"type":"node_restart","node_id":"run-payment-specs","reason":"verification","timestamp":"2025-01-21T10:08:30Z"}
{"type":"test_result","key":"payment_spec.status","status":"passing","examples":20,"failures":0,"timestamp":"2025-01-21T10:10:00Z"}
{"type":"feedback_resolved","timestamp":"2025-01-21T10:10:00Z"}
{"type":"conditional_eval","node_id":"check-specs-passing","condition_met":true,"branch":"true","timestamp":"2025-01-21T10:10:30Z"}
```

## Beads Tracking

```bash
BD-payment-tdd-123: Implement PaymentService with TDD feedback
  Status: In Progress

  Subtasks:
    ✓ Write comprehensive Payment specs (20 examples)
    ✓ Generate minimal Payment model
    ⚠ Run specs (16 failures detected)
    🔄 Feedback cycle initiated
    ✓ Model updated with feedback
    ✓ Specs re-run (20/20 passing)
    ⏳ Proceed to service implementation

  Feedback cycles: 1
  Feedback resolution: Success
```

## Benefits Demonstrated

1. **True TDD**: Tests written first, drive implementation
2. **Self-Correcting**: Workflow automatically fixes issues based on test failures
3. **No Manual Intervention**: Feedback loop handles fix-verify without user action
4. **Comprehensive Coverage**: All validations, associations, scopes, methods added
5. **Audit Trail**: Complete log of feedback cycle for debugging
6. **Bounded Execution**: Max 2 rounds prevents infinite loops
7. **State Persistence**: Can resume if workflow interrupted

## Alternative Scenario: Round 2 Needed

**If first fix incomplete**:

```
Round 1:
  Tests: 16 failures → Feedback → Model fixes → Tests: 3 failures (improvement)

Round 2:
  Tests: 3 failures → Feedback → Model fixes → Tests: 0 failures ✓

Total: 2 rounds, all issues resolved
```

**If max rounds exceeded**:

```
Round 1:
  Tests: 16 failures → Feedback → Model fixes → Tests: 10 failures

Round 2:
  Tests: 10 failures → Feedback → Model fixes → Tests: 5 failures

Round 3: ❌ BLOCKED (max rounds = 2)
  Workflow marks feedback as 'failed'
  Beads issue updated: Manual review required
  User notified of unresolved failures
```

## Usage

To execute this TDD workflow with feedback:

```bash
/reactree-dev "Implement Payment model with comprehensive validations using TDD"
```

Or with explicit feedback flag:

```bash
/reactree-feature "Payment processing" --tdd --feedback-enabled
```

## Conclusion

This example demonstrates how FEEDBACK edges transform static workflows into adaptive systems:

- **Tests discover issues** → Automatically trigger fixes
- **Parent re-executes** → Applies suggested changes
- **Child verifies** → Confirms fix works
- **No manual intervention** → Fully autonomous fix-verify cycle
- **Bounded execution** → Max 2 rounds prevents chaos
- **Complete audit trail** → Full visibility into feedback flow

Result: **Self-correcting TDD workflows** that ensure comprehensive test coverage and correct implementations without human in the loop.
