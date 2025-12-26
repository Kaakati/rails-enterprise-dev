# Deployment Workflow with CONDITIONAL Control Flow

This example demonstrates using CONDITIONAL control flow nodes for intelligent deployment decisions in the ReAcTree plugin.

## Scenario

Deploy a Rails application to staging with intelligent decision-making:
- Run integration tests first
- If tests pass AND coverage > 85% → Deploy to staging
- If tests pass BUT coverage < 85% → Request more tests
- If tests fail → Debug and fix failures
- After deployment → Run smoke tests

## Workflow Definition

```json
{
  "workflow_name": "Intelligent Staging Deployment",
  "workflow_type": "deployment",
  "root_node": {
    "type": "SEQUENCE",
    "children": [
      {
        "type": "ACTION",
        "skill": "run_integration_tests",
        "description": "Run full integration test suite",
        "agent": "RSpec Specialist",
        "output_to_memory": "integration_tests.status"
      },
      {
        "type": "CONDITIONAL",
        "node_id": "check-test-results",
        "description": "Decide next step based on test results",
        "condition": {
          "type": "test_result",
          "key": "integration_tests.status",
          "operator": "equals",
          "value": "passing"
        },
        "true_branch": {
          "type": "CONDITIONAL",
          "node_id": "check-coverage",
          "description": "Verify coverage meets threshold",
          "condition": {
            "type": "observation_check",
            "key": "coverage.percentage",
            "operator": "greater_than",
            "value": "85"
          },
          "true_branch": {
            "type": "SEQUENCE",
            "description": "Deploy and verify",
            "children": [
              {
                "type": "ACTION",
                "skill": "deploy_to_staging",
                "agent": "Deployment Engineer",
                "output_to_memory": "deployment.status"
              },
              {
                "type": "CONDITIONAL",
                "node_id": "check-deployment-success",
                "condition": {
                  "type": "observation_check",
                  "key": "deployment.status",
                  "operator": "equals",
                  "value": "success"
                },
                "true_branch": {
                  "type": "ACTION",
                  "skill": "run_smoke_tests",
                  "agent": "QA Specialist"
                },
                "false_branch": {
                  "type": "ACTION",
                  "skill": "rollback_deployment",
                  "agent": "Deployment Engineer"
                }
              }
            ]
          },
          "false_branch": {
            "type": "SEQUENCE",
            "description": "Request additional test coverage",
            "children": [
              {
                "type": "ACTION",
                "skill": "analyze_coverage_gaps",
                "agent": "RSpec Specialist"
              },
              {
                "type": "ACTION",
                "skill": "suggest_additional_tests",
                "agent": "RSpec Specialist"
              }
            ]
          }
        },
        "false_branch": {
          "type": "SEQUENCE",
          "description": "Debug and fix test failures",
          "children": [
            {
              "type": "ACTION",
              "skill": "analyze_test_failures",
              "agent": "RSpec Specialist"
            },
            {
              "type": "ACTION",
              "skill": "create_failure_report",
              "agent": "RSpec Specialist"
            }
          ]
        }
      }
    ]
  }
}
```

## Execution Flow

### Scenario 1: Happy Path (Tests Pass, Coverage Good)

**Step 1: Run Integration Tests**
```bash
Running integration tests...
```

**Output:**
```
Randomized with seed 12345

PaymentController
  POST /payments/create
    ✓ creates payment successfully
    ✓ validates amount
    ✓ handles Stripe errors

SubscriptionController
  POST /subscriptions/create
    ✓ creates subscription
    ✓ handles trial periods

... (40 more examples)

Finished in 12.54 seconds
45 examples, 0 failures

Coverage: 92.5%
```

**Step 2: Check Test Results (CONDITIONAL Level 1)**
```bash
🔀 Evaluating CONDITIONAL node: check-test-results
   Condition: integration_tests.status == 'passing'
   ✓ Condition true (45/45 tests passing)
```

**Step 3: Check Coverage (CONDITIONAL Level 2)**
```bash
🔀 Evaluating CONDITIONAL node: check-coverage
   Condition: coverage.percentage > 85
   ✓ Condition true (92.5% > 85%)

Executing true branch: Deploy and verify
```

**Step 4: Deploy to Staging**
```bash
Deploying to staging environment...

✓ Building Docker image (v2.3.1)
✓ Pushing to registry
✓ Updating Kubernetes deployment
✓ Waiting for rollout to complete...
✓ Deployment successful

Deployment status: success
```

**Step 5: Check Deployment Success (CONDITIONAL Level 3)**
```bash
🔀 Evaluating CONDITIONAL node: check-deployment-success
   Condition: deployment.status == 'success'
   ✓ Condition true

Executing true branch: Run smoke tests
```

**Step 6: Smoke Tests**
```bash
Running smoke tests...

✓ Health check endpoint responding
✓ Database connectivity verified
✓ Redis cache operational
✓ Background jobs processing
✓ Payment API integration working

All smoke tests passed!
```

**Final Result:**
```bash
✅ Deployment workflow completed successfully

Summary:
  Integration Tests: 45/45 passing (92.5% coverage)
  Deployment: Success (v2.3.1 on staging)
  Smoke Tests: All passed
  Duration: 3m 45s
```

### Scenario 2: Tests Pass but Coverage Low

**Step 1: Run Integration Tests**
```
45 examples, 0 failures
Coverage: 78.2%
```

**Step 2: Check Test Results**
```bash
🔀 CONDITIONAL: check-test-results
   ✓ Tests passing
```

**Step 3: Check Coverage**
```bash
🔀 CONDITIONAL: check-coverage
   Condition: coverage.percentage > 85
   ✗ Condition false (78.2% < 85%)

Executing false branch: Request additional tests
```

**Step 4: Analyze Coverage Gaps**
```bash
Analyzing coverage gaps...

Uncovered areas:
  ├── app/services/payment_refund_service.rb (45% coverage)
  │   Missing: Error handling paths
  │   Missing: Partial refund scenarios
  ├── app/controllers/admin/reports_controller.rb (60% coverage)
  │   Missing: CSV export edge cases
  │   Missing: Date range validations
  └── app/models/subscription.rb (72% coverage)
      Missing: State transition validations
```

**Step 5: Suggest Additional Tests**
```bash
Suggested tests to reach 85% coverage:

1. spec/services/payment_refund_service_spec.rb
   - Add: "handles Stripe refund errors gracefully"
   - Add: "processes partial refunds correctly"
   - Add: "validates refund amount"

2. spec/controllers/admin/reports_controller_spec.rb
   - Add: "exports CSV with special characters"
   - Add: "validates date range boundaries"
   - Add: "handles empty result sets"

3. spec/models/subscription_spec.rb
   - Add: "prevents invalid state transitions"
   - Add: "handles concurrent updates"

Estimated time to implement: 45 minutes
Estimated coverage gain: 78.2% → 87.5%
```

**Final Result:**
```bash
⚠️ Deployment blocked: Coverage below threshold

Next steps:
  1. Implement suggested tests (see above)
  2. Run workflow again once coverage > 85%

Beads issue updated with coverage gap analysis.
```

### Scenario 3: Tests Failing

**Step 1: Run Integration Tests**
```
45 examples, 3 failures
```

**Step 2: Check Test Results**
```bash
🔀 CONDITIONAL: check-test-results
   Condition: integration_tests.status == 'passing'
   ✗ Condition false (3 failures detected)

Executing false branch: Debug and fix test failures
```

**Step 3: Analyze Test Failures**
```bash
Analyzing test failures...

Failure 1:
  Spec: spec/services/payment_service_spec.rb:42
  Error: Expected Stripe::Charge to receive :create with amount: 1000
         but received amount: 100 (off by 10x)
  Root cause: Currency conversion bug in PaymentService#convert_to_cents

Failure 2:
  Spec: spec/controllers/subscriptions_controller_spec.rb:78
  Error: NoMethodError: undefined method `trial_end_date` for nil:NilClass
  Root cause: Missing eager loading for subscription.plan association

Failure 3:
  Spec: spec/models/user_spec.rb:156
  Error: Validation failed: Email has already been taken
  Root cause: Test setup not cleaning up previous user with same email
```

**Step 4: Create Failure Report**
```bash
Creating failure report...

Failure Report Summary
======================

Total Failures: 3
Severity: 2 High, 1 Low
Estimated Fix Time: 30 minutes

High Priority:
  1. PaymentService currency conversion bug (affects payments)
  2. Missing eager loading (N+1 query + nil error)

Low Priority:
  3. Test isolation issue (flaky test)

Recommended Actions:
  1. Fix PaymentService#convert_to_cents (multiply by 100, not divide)
  2. Add includes(:plan) to SubscriptionsController#index
  3. Add before(:each) cleanup to user specs

Beads issue created: BD-xyz123 - Fix integration test failures
```

**Final Result:**
```bash
❌ Deployment aborted: Tests failing

Summary:
  Integration Tests: 42/45 passing (3 failures)
  Failure analysis: Complete (see report above)
  Beads issue: BD-xyz123

Next steps:
  1. Fix identified issues (est. 30 min)
  2. Run tests locally to verify
  3. Re-run deployment workflow
```

## Working Memory Updates

During workflow execution, these facts are stored:

**Scenario 1 (Success)**:
```jsonl
{"timestamp":"2025-01-21T14:00:00Z","agent":"RSpec Specialist","key":"integration_tests.status","value":"passing","confidence":"verified"}
{"timestamp":"2025-01-21T14:00:12Z","agent":"RSpec Specialist","key":"coverage.percentage","value":92.5,"confidence":"verified"}
{"timestamp":"2025-01-21T14:02:30Z","agent":"Deployment Engineer","key":"deployment.status","value":"success","confidence":"verified"}
{"timestamp":"2025-01-21T14:02:31Z","agent":"Deployment Engineer","key":"deployment.version","value":"v2.3.1","confidence":"verified"}
{"timestamp":"2025-01-21T14:03:45Z","agent":"QA Specialist","key":"smoke_tests.status","value":"passing","confidence":"verified"}
```

**Scenario 2 (Low Coverage)**:
```jsonl
{"timestamp":"2025-01-21T14:00:00Z","agent":"RSpec Specialist","key":"integration_tests.status","value":"passing"}
{"timestamp":"2025-01-21T14:00:12Z","agent":"RSpec Specialist","key":"coverage.percentage","value":78.2}
{"timestamp":"2025-01-21T14:00:15Z","agent":"RSpec Specialist","key":"coverage.gaps","value":["payment_refund_service.rb","admin/reports_controller.rb","subscription.rb"]}
```

**Scenario 3 (Test Failures)**:
```jsonl
{"timestamp":"2025-01-21T14:00:00Z","agent":"RSpec Specialist","key":"integration_tests.status","value":"failing"}
{"timestamp":"2025-01-21T14:00:12Z","agent":"RSpec Specialist","key":"integration_tests.failures","value":3}
{"timestamp":"2025-01-21T14:00:30Z","agent":"RSpec Specialist","key":"failure_analysis.complete","value":true}
```

## State Tracking

**State Log** (`.claude/reactree-state.jsonl`):

```jsonl
{"type":"node_start","node_id":"run-tests","timestamp":"2025-01-21T14:00:00Z"}
{"type":"node_complete","node_id":"run-tests","status":"success","timestamp":"2025-01-21T14:00:12Z"}
{"type":"conditional_eval","node_id":"check-test-results","condition_met":true,"branch":"true","timestamp":"2025-01-21T14:00:13Z"}
{"type":"conditional_eval","node_id":"check-coverage","condition_met":true,"branch":"true","timestamp":"2025-01-21T14:00:14Z"}
{"type":"node_start","node_id":"deploy-to-staging","timestamp":"2025-01-21T14:00:15Z"}
{"type":"node_complete","node_id":"deploy-to-staging","status":"success","timestamp":"2025-01-21T14:02:30Z"}
{"type":"conditional_eval","node_id":"check-deployment-success","condition_met":true,"branch":"true","timestamp":"2025-01-21T14:02:31Z"}
{"type":"node_start","node_id":"run-smoke-tests","timestamp":"2025-01-21T14:02:32Z"}
{"type":"node_complete","node_id":"run-smoke-tests","status":"success","timestamp":"2025-01-21T14:03:45Z"}
```

## Condition Evaluation Cache

**Cache File** (`.claude/reactree-conditions.jsonl`):

```jsonl
{"timestamp":"2025-01-21T14:00:13Z","node_id":"check-test-results","condition_key":"integration_tests.status","result":true,"cache_until":"2025-01-21T14:05:13Z"}
{"timestamp":"2025-01-21T14:00:14Z","node_id":"check-coverage","condition_key":"coverage.percentage","result":true,"cache_until":"2025-01-21T14:05:14Z"}
{"timestamp":"2025-01-21T14:02:31Z","node_id":"check-deployment-success","condition_key":"deployment.status","result":true,"cache_until":"2025-01-21T14:07:31Z"}
```

**Cache Benefits**:
- If workflow retried within 5 minutes, cached conditions reused
- Avoids re-running expensive test suites
- Consistent decision-making within cache window

## Beads Tracking

### Scenario 1: Success
```bash
BD-deploy-123: Deploy to staging
  Status: Closed (Success)
  Duration: 3m 45s

  Subtasks:
    ✓ Run integration tests
    ✓ Deploy to staging (v2.3.1)
    ✓ Run smoke tests
```

### Scenario 2: Coverage Low
```bash
BD-deploy-124: Deploy to staging
  Status: Blocked (Coverage below threshold)

  Subtasks:
    ✓ Run integration tests
    ⚠ Coverage analysis
    ⏸ Deployment (blocked)

  Next Action: Implement suggested tests to reach 85% coverage
```

### Scenario 3: Test Failures
```bash
BD-deploy-125: Deploy to staging
  Status: Blocked (Test failures)

  Subtasks:
    ❌ Run integration tests (3 failures)
    ✓ Failure analysis

  Created Issue: BD-xyz123 - Fix integration test failures
```

## Benefits Demonstrated

1. **Intelligent Branching**: Automatic decision-making based on test results and coverage
2. **Nested Decisions**: Multi-level checks (tests → coverage → deployment → smoke tests)
3. **Graceful Degradation**: Different paths for different scenarios
4. **State Tracking**: Full audit trail of all decisions
5. **Memory Integration**: Conditions evaluated from working memory
6. **Condition Caching**: Avoid redundant evaluations within time window
7. **Beads Integration**: Workflow status tracked in issue tracker

## Usage

To execute this deployment workflow:

```bash
/reactree-dev "Deploy to staging with intelligent quality gates"
```

Or use deployment-specific command (if available):

```bash
/reactree-deploy --environment staging --quality-gates enabled
```

## Conclusion

This example demonstrates how CONDITIONAL control flow enables:
- **Smart Deployment Decisions**: Deploy only when quality thresholds met
- **Multi-Level Validation**: Tests → Coverage → Deployment → Smoke Tests
- **Actionable Feedback**: Clear next steps when deployment blocked
- **Audit Trail**: Complete log of all decisions and branches taken
- **Fail-Safe Design**: Conservative false branches prevent bad deployments

The workflow adapts to 3 different scenarios without manual intervention, ensuring only high-quality code reaches staging.
