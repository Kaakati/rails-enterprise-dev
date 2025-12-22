---
name: "Service Object Patterns"
description: "Complete guide to implementing Service Objects in Ruby on Rails applications. Use this skill when creating business logic services, organizing service namespaces, handling service results, and designing service interfaces for complex operations."
---

# Service Object Patterns Skill

This skill provides comprehensive guidance for implementing Service Objects in Rails applications following consistent patterns and conventions.

## When to Use This Skill

- Creating new service objects for business logic
- Refactoring fat models or controllers
- Designing service interfaces
- Implementing result objects for service responses
- Organizing services into namespaces

## When to Use Service Objects

### Use Service Objects When:
- Business logic spans multiple models
- Operation has multiple steps/side effects
- Logic doesn't naturally belong to one model
- Need to orchestrate external services
- Complex validation or business rules
- Operation needs transaction management

### Don't Use Service Objects When:
- Simple CRUD operations
- Logic clearly belongs to one model
- Single-line delegation
- No side effects beyond model updates

## Directory Structure

```
app/services/
├── application_service.rb          # Base class
├── tasks_manager/
│   ├── create_task.rb
│   ├── assign_carrier.rb
│   ├── complete_task.rb
│   └── bundling/
│       ├── bundle_tasks.rb
│       └── optimize_routes.rb
├── billing_manager/
│   ├── generate_invoice.rb
│   ├── process_payment.rb
│   └── calculate_fees.rb
├── notifications_manager/
│   ├── send_sms.rb
│   └── send_push_notification.rb
└── integrations/
    ├── salla/
    │   └── sync_orders.rb
    └── shipping/
        └── create_label.rb
```

## Naming Convention

```ruby
# Pattern: {Domain}Manager::{Action} or {Domain}Manager::{SubDomain}::{Action}

# Examples:
TasksManager::CreateTask
TasksManager::Bundling::BundleTasks
BillingManager::GenerateInvoice
IntegrationsManager::Salla::SyncOrders
```

## Base Service Class

```ruby
# app/services/application_service.rb
class ApplicationService
  def self.call(...)
    new(...).call
  end

  private

  attr_reader :params

  def initialize(**params)
    @params = params
  end
end
```

## Basic Service Pattern

```ruby
# app/services/tasks_manager/create_task.rb
module TasksManager
  class CreateTask < ApplicationService
    def initialize(account:, merchant:, params:)
      @account = account
      @merchant = merchant
      @params = params
    end

    def call
      validate_params!
      
      ActiveRecord::Base.transaction do
        task = build_task
        assign_zone(task)
        task.save!
        schedule_notifications(task)
        task
      end
    end

    private

    attr_reader :account, :merchant, :params

    def validate_params!
      raise ArgumentError, "Recipient required" unless params[:recipient_id]
      raise ArgumentError, "Address required" unless params[:address]
    end

    def build_task
      account.tasks.build(
        merchant: merchant,
        recipient_id: params[:recipient_id],
        description: params[:description],
        amount: params[:amount],
        status: 'pending'
      )
    end

    def assign_zone(task)
      zone = ZoneFinder.new(account, params[:address]).find
      task.zone = zone
    end

    def schedule_notifications(task)
      TaskNotificationJob.perform_later(task.id)
    end
  end
end

# Usage:
task = TasksManager::CreateTask.call(
  account: current_account,
  merchant: merchant,
  params: task_params
)
```

## Result Object Pattern

For services that need structured success/failure responses:

```ruby
# app/services/service_result.rb
class ServiceResult
  attr_reader :data, :error, :errors

  def initialize(success:, data: nil, error: nil, errors: [])
    @success = success
    @data = data
    @error = error
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.failure(error = nil, errors: [])
    new(success: false, error: error, errors: errors)
  end
end
```

```ruby
# app/services/tasks_manager/assign_carrier.rb
module TasksManager
  class AssignCarrier < ApplicationService
    def initialize(task:, carrier:)
      @task = task
      @carrier = carrier
    end

    def call
      return ServiceResult.failure("Task already assigned") if task.carrier.present?
      return ServiceResult.failure("Carrier not available") unless carrier_available?
      return ServiceResult.failure("Carrier not in zone") unless carrier_in_zone?

      ActiveRecord::Base.transaction do
        task.update!(carrier: carrier, assigned_at: Time.current)
        notify_carrier
        notify_recipient
      end

      ServiceResult.success(task.reload)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(e.message, errors: task.errors.full_messages)
    end

    private

    attr_reader :task, :carrier

    def carrier_available?
      carrier.active? && carrier.available?
    end

    def carrier_in_zone?
      return true unless task.zone
      carrier.zones.include?(task.zone)
    end

    def notify_carrier
      CarrierNotificationJob.perform_later(carrier.id, task.id)
    end

    def notify_recipient
      RecipientNotificationJob.perform_later(task.id, :carrier_assigned)
    end
  end
end

# Usage in controller:
result = TasksManager::AssignCarrier.call(task: @task, carrier: @carrier)

if result.success?
  render json: result.data, status: :ok
else
  render json: { error: result.error, errors: result.errors }, status: :unprocessable_entity
end
```

## Dry-Monads Pattern (Alternative)

If using the `dry-monads` gem:

```ruby
# Gemfile
gem 'dry-monads'

# app/services/tasks_manager/complete_task.rb
module TasksManager
  class CompleteTask
    include Dry::Monads[:result, :do]

    def initialize(task:, otp:, photos: [])
      @task = task
      @otp = otp
      @photos = photos
    end

    def call
      yield validate_otp
      yield validate_photos
      yield complete_task
      yield process_payment
      yield notify_parties

      Success(task.reload)
    end

    private

    attr_reader :task, :otp, :photos

    def validate_otp
      return Failure(:invalid_otp) unless task.otp == otp
      Success()
    end

    def validate_photos
      return Failure(:photos_required) if task.requires_photos? && photos.empty?
      Success()
    end

    def complete_task
      task.update!(
        status: 'completed',
        completed_at: Time.current
      )
      Success()
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.message)
    end

    def process_payment
      # Payment processing logic
      Success()
    end

    def notify_parties
      TaskCompletionNotificationJob.perform_later(task.id)
      Success()
    end
  end
end

# Usage:
result = TasksManager::CompleteTask.new(task: @task, otp: params[:otp]).call

case result
in Success(task)
  render json: task
in Failure(:invalid_otp)
  render json: { error: "Invalid OTP" }, status: :unprocessable_entity
in Failure(error)
  render json: { error: error }, status: :unprocessable_entity
end
```

## Service Composition

For complex operations that coordinate multiple services:

```ruby
# app/services/tasks_manager/process_delivery.rb
module TasksManager
  class ProcessDelivery < ApplicationService
    def initialize(task:, carrier:, params:)
      @task = task
      @carrier = carrier
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        validate_delivery!
        complete_task!
        process_cod! if task.cod?
        generate_invoice!
        notify_all_parties!
      end

      ServiceResult.success(task.reload)
    rescue StandardError => e
      ServiceResult.failure(e.message)
    end

    private

    attr_reader :task, :carrier, :params

    def validate_delivery!
      result = DeliveryValidator.call(task: task, params: params)
      raise result.error unless result.success?
    end

    def complete_task!
      result = CompleteTask.call(
        task: task,
        otp: params[:otp],
        photos: params[:photos]
      )
      raise result.error unless result.success?
    end

    def process_cod!
      result = BillingManager::ProcessCod.call(
        task: task,
        carrier: carrier,
        amount: task.cod_amount
      )
      raise result.error unless result.success?
    end

    def generate_invoice!
      BillingManager::GenerateInvoice.call(task: task)
    end

    def notify_all_parties!
      NotificationsManager::DeliveryComplete.call(task: task)
    end
  end
end
```

## Service with External API

```ruby
# app/services/integrations/shipping/create_label.rb
module Integrations
  module Shipping
    class CreateLabel < ApplicationService
      TIMEOUT = 30.seconds

      def initialize(task:, shipping_company:)
        @task = task
        @shipping_company = shipping_company
      end

      def call
        response = make_api_request
        
        if response.success?
          label = create_label_record(response.body)
          ServiceResult.success(label)
        else
          handle_error(response)
        end
      rescue Faraday::TimeoutError
        ServiceResult.failure("Shipping API timeout")
      rescue Faraday::ConnectionFailed
        ServiceResult.failure("Unable to connect to shipping API")
      end

      private

      attr_reader :task, :shipping_company

      def make_api_request
        client.post('/labels', label_payload)
      end

      def client
        @client ||= Faraday.new(url: shipping_company.api_url) do |f|
          f.request :json
          f.response :json
          f.options.timeout = TIMEOUT
          f.headers['Authorization'] = "Bearer #{shipping_company.api_key}"
        end
      end

      def label_payload
        {
          sender: sender_details,
          recipient: recipient_details,
          package: package_details
        }
      end

      def create_label_record(response_body)
        task.create_shipping_label!(
          tracking_number: response_body['tracking_number'],
          label_url: response_body['label_url'],
          shipping_company: shipping_company
        )
      end

      def handle_error(response)
        error_message = response.body['error'] || "API Error: #{response.status}"
        Rails.logger.error("Shipping API Error: #{error_message}")
        ServiceResult.failure(error_message)
      end
    end
  end
end
```

## Service with Background Jobs

```ruby
# app/services/tasks_manager/bulk_import.rb
module TasksManager
  class BulkImport < ApplicationService
    def initialize(account:, file:, user:)
      @account = account
      @file = file
      @user = user
    end

    def call
      import = create_import_record
      schedule_processing(import)
      ServiceResult.success(import)
    end

    private

    attr_reader :account, :file, :user

    def create_import_record
      account.task_imports.create!(
        file: file,
        user: user,
        status: 'pending',
        total_rows: count_rows
      )
    end

    def schedule_processing(import)
      BulkImportJob.perform_later(import.id)
    end

    def count_rows
      # Count rows in uploaded file
      CSV.read(file.path).count - 1  # Minus header
    end
  end
end
```

## Testing Services

```ruby
# spec/services/tasks_manager/create_task_spec.rb
require 'rails_helper'

RSpec.describe TasksManager::CreateTask do
  let(:account) { create(:account) }
  let(:merchant) { create(:merchant, account: account) }
  let(:recipient) { create(:recipient, account: account) }
  
  let(:valid_params) do
    {
      recipient_id: recipient.id,
      description: "Test delivery",
      amount: 100,
      address: "123 Test St"
    }
  end

  describe '.call' do
    context 'with valid params' do
      it 'creates a task' do
        expect {
          described_class.call(
            account: account,
            merchant: merchant,
            params: valid_params
          )
        }.to change(Task, :count).by(1)
      end

      it 'assigns the zone' do
        task = described_class.call(
          account: account,
          merchant: merchant,
          params: valid_params
        )
        
        expect(task.zone).to be_present
      end

      it 'schedules notification' do
        expect {
          described_class.call(
            account: account,
            merchant: merchant,
            params: valid_params
          )
        }.to have_enqueued_job(TaskNotificationJob)
      end
    end

    context 'with invalid params' do
      it 'raises error without recipient' do
        invalid_params = valid_params.except(:recipient_id)
        
        expect {
          described_class.call(
            account: account,
            merchant: merchant,
            params: invalid_params
          )
        }.to raise_error(ArgumentError, "Recipient required")
      end
    end
  end
end
```

## Service Interface Guidelines

### Method Visibility

```ruby
class MyService
  # PUBLIC: Only .call is public (entry point)
  def self.call(...)
    new(...).call
  end

  def call
    # Main logic
  end

  private

  # PRIVATE: All other methods are private
  attr_reader :params

  def validate!
    # validation
  end

  def process
    # processing
  end
end
```

### Input Validation

```ruby
def initialize(user:, params:)
  @user = user
  @params = params
  validate_input!
end

private

def validate_input!
  raise ArgumentError, "User required" unless @user
  raise ArgumentError, "Params required" unless @params
end
```

### Transaction Management

```ruby
def call
  ActiveRecord::Base.transaction do
    step_one
    step_two
    step_three
  end
rescue ActiveRecord::RecordInvalid => e
  # Handle validation errors
  ServiceResult.failure(e.message)
rescue StandardError => e
  # Handle other errors
  Rails.logger.error("Service error: #{e.message}")
  ServiceResult.failure("An error occurred")
end
```

## Pre-Creation Checklist

Before creating a service:

```bash
# 1. Check existing service structure
ls app/services/
ls app/services/*/ 2>/dev/null

# 2. Review existing service patterns
head -50 $(find app/services -name '*.rb' | head -1)

# 3. Check naming conventions
grep -r 'class.*Manager' app/services/ --include='*.rb' | head -10

# 4. Verify namespace exists
ls app/services/{namespace}/ 2>/dev/null
```
