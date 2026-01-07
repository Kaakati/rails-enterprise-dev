---
paths: "{app/services,lib/services}/**/*.rb"
---

# Service Object Patterns

Apply to all files in `app/services/**/*.rb` and `lib/services/**/*.rb`

## Naming Convention

**Always end with `Service`:**
```ruby
# ✅ CORRECT
CreateOrderService
ProcessPaymentService
ImportDataService

# ❌ WRONG
CreateOrder  # Missing "Service" suffix
OrderCreator  # Wrong pattern
```

**Use verb + noun pattern:**
- `Create + Order = CreateOrderService`
- `Process + Payment = ProcessPaymentService`
- `Import + Data = ImportDataService`
- `Generate + Report = GenerateReportService`

## Standard Service Object Structure

```ruby
# app/services/orders/create_service.rb
module Orders
  class CreateService
    # == Initialization =====================================================
    def initialize(user:, params:, coupon_code: nil)
      @user = user
      @params = params
      @coupon_code = coupon_code
    end

    # == Main Entry Point ===================================================
    def call
      validate_params!

      Order.transaction do
        create_order
        apply_coupon if @coupon_code
        calculate_totals
        process_payment
        send_confirmation
      end

      Result.success(order: @order)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(error: e.message, order: @order)
    rescue Payment::Error => e
      Result.failure(error: "Payment failed: #{e.message}", order: @order)
    end

    private

    attr_reader :user, :params, :coupon_code

    # == Private Methods ====================================================
    def validate_params!
      raise ArgumentError, "User cannot be nil" if user.nil?
      raise ArgumentError, "Items cannot be empty" if params[:items].blank?
    end

    def create_order
      @order = user.orders.create!(params.slice(:shipping_address, :billing_address))
      params[:items].each do |item_params|
        @order.line_items.create!(item_params)
      end
    end

    def apply_coupon
      coupon = Coupon.find_by(code: @coupon_code)
      @order.update!(coupon: coupon) if coupon&.valid_for?(@order)
    end

    def calculate_totals
      @order.calculate_total!
    end

    def process_payment
      Payments::ChargeService.new(order: @order, token: params[:payment_token]).call
    end

    def send_confirmation
      OrderMailer.confirmation(@order).deliver_later
    end
  end
end
```

## Result Object Pattern

**Use structured result objects:**

```ruby
# app/services/result.rb
class Result
  attr_reader :success, :data, :error

  def initialize(success:, data: {}, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def self.success(**data)
    new(success: true, data: data)
  end

  def self.failure(error:, **data)
    new(success: false, error: error, data: data)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  # Delegate to data hash
  def method_missing(method_name, *args)
    return @data[method_name] if @data.key?(method_name)
    super
  end

  def respond_to_missing?(method_name, include_private = false)
    @data.key?(method_name) || super
  end
end

# Usage in controller
def create
  result = Orders::CreateService.new(
    user: current_user,
    params: order_params,
    coupon_code: params[:coupon_code]
  ).call

  if result.success?
    redirect_to result.order, notice: "Order created!"
  else
    flash.now[:alert] = result.error
    render :new, status: :unprocessable_entity
  end
end
```

## Alternative: dry-monads

**For more advanced result handling, use `dry-monads`:**

```ruby
# Gemfile
gem 'dry-monads'

# app/services/orders/create_service.rb
require 'dry/monads'

module Orders
  class CreateService
    include Dry::Monads[:result, :do]

    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      validate_user
      validate_params
      order = yield create_order
      yield process_payment(order)

      Success(order: order)
    end

    private

    def validate_user
      return Success() if @user.present?
      Failure(error: "User is required")
    end

    def validate_params
      return Success() if @params[:items].present?
      Failure(error: "Items cannot be empty")
    end

    def create_order
      order = @user.orders.create(@params)
      order.persisted? ? Success(order) : Failure(errors: order.errors)
    end

    def process_payment(order)
      result = Payments::ChargeService.new(order: order).call
      result.success? ? Success() : Failure(error: "Payment failed")
    end
  end
end
```

## Service Organization Patterns

### Namespace by Domain

```ruby
# app/services/orders/create_service.rb
module Orders
  class CreateService
    # ...
  end
end

# app/services/orders/cancel_service.rb
module Orders
  class CancelService
    # ...
  end
end

# app/services/payments/charge_service.rb
module Payments
  class ChargeService
    # ...
  end
end
```

### Callable Pattern

**Use `.call` class method for simple services:**

```ruby
class CalculateTaxService
  def self.call(order)
    new(order).call
  end

  def initialize(order)
    @order = order
  end

  def call
    @order.subtotal * tax_rate
  end

  private

  def tax_rate
    @order.shipping_address.tax_rate
  end
end

# Usage
tax = CalculateTaxService.call(order)
```

## Error Handling

**Handle errors explicitly:**

```ruby
class ImportDataService
  class ImportError < StandardError; end

  def initialize(file:, user:)
    @file = file
    @user = user
  end

  def call
    validate_file!
    import_records
    Result.success(imported_count: @imported_count)
  rescue CSV::MalformedCSVError => e
    Result.failure(error: "Invalid CSV format: #{e.message}")
  rescue ImportError => e
    Result.failure(error: e.message)
  rescue StandardError => e
    Rails.logger.error("Import failed: #{e.message}")
    Result.failure(error: "An unexpected error occurred")
  end

  private

  def validate_file!
    raise ImportError, "File is required" unless @file.present?
    raise ImportError, "File must be CSV" unless @file.content_type == 'text/csv'
  end

  def import_records
    @imported_count = 0
    CSV.foreach(@file.path, headers: true) do |row|
      create_record(row)
      @imported_count += 1
    end
  end

  def create_record(row)
    Record.create!(
      user: @user,
      data: row.to_h
    )
  end
end
```

## Dependency Injection

**Inject dependencies for testability:**

```ruby
class ProcessOrderService
  def initialize(order:, payment_processor: Stripe::PaymentProcessor, mailer: OrderMailer)
    @order = order
    @payment_processor = payment_processor
    @mailer = mailer
  end

  def call
    charge = @payment_processor.charge(
      amount: @order.total,
      token: @order.payment_token
    )

    if charge.success?
      @order.update!(status: :paid)
      @mailer.receipt(@order).deliver_later
      Result.success(order: @order)
    else
      Result.failure(error: charge.error_message)
    end
  end
end

# In tests, inject mock dependencies
RSpec.describe ProcessOrderService do
  let(:payment_processor) { instance_double(Stripe::PaymentProcessor) }
  let(:mailer) { instance_double(OrderMailer) }
  let(:service) { described_class.new(order: order, payment_processor: payment_processor, mailer: mailer) }

  it 'processes payment successfully' do
    allow(payment_processor).to receive(:charge).and_return(OpenStruct.new(success?: true))
    allow(mailer).to receive(:receipt).and_return(double(deliver_later: true))

    result = service.call

    expect(result.success?).to be true
  end
end
```

## Transaction Safety

**Use database transactions for multi-step operations:**

```ruby
class CreateSubscriptionService
  def initialize(user:, plan:, payment_method:)
    @user = user
    @plan = plan
    @payment_method = payment_method
  end

  def call
    ActiveRecord::Base.transaction do
      subscription = create_subscription
      charge_initial_payment(subscription)
      activate_subscription(subscription)
      send_welcome_email(subscription)

      Result.success(subscription: subscription)
    end
  rescue ActiveRecord::RecordInvalid, Payment::Error => e
    Result.failure(error: e.message)
  end

  private

  def create_subscription
    @user.subscriptions.create!(
      plan: @plan,
      status: :pending,
      payment_method: @payment_method
    )
  end

  def charge_initial_payment(subscription)
    Payments::ChargeService.new(
      amount: @plan.price,
      payment_method: @payment_method
    ).call!  # Raises on failure, triggers transaction rollback
  end

  def activate_subscription(subscription)
    subscription.update!(status: :active, activated_at: Time.current)
  end

  def send_welcome_email(subscription)
    SubscriptionMailer.welcome(subscription).deliver_later
  end
end
```

## Idempotency

**Design services to be idempotent when possible:**

```ruby
class ProcessWebhookService
  def initialize(webhook_id:, event_type:, payload:)
    @webhook_id = webhook_id
    @event_type = event_type
    @payload = payload
  end

  def call
    # Check if already processed (idempotency)
    return Result.success(message: "Already processed") if already_processed?

    process_event
    mark_as_processed

    Result.success(message: "Processed successfully")
  rescue StandardError => e
    Result.failure(error: e.message)
  end

  private

  def already_processed?
    ProcessedWebhook.exists?(webhook_id: @webhook_id)
  end

  def process_event
    case @event_type
    when 'payment.succeeded'
      update_payment_status
    when 'subscription.cancelled'
      cancel_subscription
    else
      Rails.logger.warn("Unknown event type: #{@event_type}")
    end
  end

  def mark_as_processed
    ProcessedWebhook.create!(
      webhook_id: @webhook_id,
      event_type: @event_type,
      processed_at: Time.current
    )
  end
end
```

## Testing Service Objects

```ruby
# spec/services/orders/create_service_spec.rb
RSpec.describe Orders::CreateService do
  subject(:service) { described_class.new(user: user, params: params) }

  let(:user) { create(:user) }
  let(:params) { { items: [{ product_id: 1, quantity: 2 }] } }

  describe '#call' do
    context 'with valid params' do
      it 'creates an order' do
        expect { service.call }.to change(Order, :count).by(1)
      end

      it 'returns success result' do
        result = service.call
        expect(result).to be_success
        expect(result.order).to be_a(Order)
      end
    end

    context 'with invalid params' do
      let(:params) { { items: [] } }

      it 'does not create an order' do
        expect { service.call }.not_to change(Order, :count)
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to include("Items cannot be empty")
      end
    end

    context 'when payment fails' do
      before do
        allow_any_instance_of(Payments::ChargeService).to receive(:call).and_return(
          Result.failure(error: "Card declined")
        )
      end

      it 'rolls back the transaction' do
        expect { service.call }.not_to change(Order, :count)
      end

      it 'returns failure result with error' do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to include("Payment failed")
      end
    end
  end
end
```

## Anti-Patterns

**❌ NEVER:**
- Create services without clear single responsibility
- Modify global state or class variables
- Skip error handling
- Use services as god objects (multiple responsibilities)
- Directly access `params` or `session` (inject dependencies)
- Return different types from `call` method (always return Result)
- Use multiple entry point methods (only use `call`)

**✅ INSTEAD:**
- Single Responsibility Principle
- Dependency injection
- Explicit error handling with Result objects
- Focused services with one clear purpose
- Pass all dependencies via initialize
- Consistent Result object interface
- Single `call` method as entry point
