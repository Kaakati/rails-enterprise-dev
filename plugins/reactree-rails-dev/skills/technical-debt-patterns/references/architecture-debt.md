# Architecture Debt Reference

Comprehensive guide to detecting and addressing architectural issues in Rails applications.

## God Objects

Large classes that have accumulated too many responsibilities over time.

### Detection

**Quantitative Indicators**:
```bash
# Lines of code per model
for file in app/models/*.rb; do
  lines=$(wc -l < "$file")
  if [ "$lines" -gt 300 ]; then
    echo "$(basename $file): $lines lines"
  fi
done

# Method count per model
for file in app/models/*.rb; do
  methods=$(grep -c "^[[:space:]]*def " "$file" 2>/dev/null)
  if [ "$methods" -gt 30 ]; then
    echo "$(basename $file): $methods methods"
  fi
done

# Association count
for file in app/models/*.rb; do
  assoc=$(grep -c "has_many\|has_one\|belongs_to\|has_and_belongs_to_many" "$file" 2>/dev/null)
  if [ "$assoc" -gt 10 ]; then
    echo "$(basename $file): $assoc associations"
  fi
done
```

**Qualitative Indicators**:
- Class name is very generic (User, Account, Order)
- Multiple developers frequently modify the same file
- Class is included in most test files
- Difficult to understand class purpose in one sentence

### Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Lines | > 300 | > 500 |
| Methods | > 30 | > 50 |
| Associations | > 10 | > 15 |
| Concerns included | > 5 | > 8 |

### Common God Objects

**User Model**:
```ruby
# Typical God Object - User does everything
class User < ApplicationRecord
  # Authentication
  has_secure_password
  def generate_token; end
  def reset_password; end

  # Profile
  def full_name; end
  def avatar_url; end

  # Orders
  has_many :orders
  def recent_orders; end
  def total_spent; end

  # Notifications
  has_many :notifications
  def unread_count; end

  # Admin features
  def admin?; end
  def can_manage?(resource); end

  # Reporting
  def activity_report; end
  def usage_stats; end

  # ... 50 more methods
end
```

### Refactoring Strategies

**1. Extract Concerns**:
```ruby
# app/models/concerns/user/authentication.rb
module User::Authentication
  extend ActiveSupport::Concern

  included do
    has_secure_password
  end

  def generate_token
    # ...
  end

  def reset_password
    # ...
  end
end

# app/models/user.rb
class User < ApplicationRecord
  include User::Authentication
  include User::Profile
  include User::Ordering
end
```

**2. Extract Service Objects**:
```ruby
# Instead of User#activity_report
class UserActivityReport
  def initialize(user)
    @user = user
  end

  def generate
    # Complex reporting logic
  end
end

# Usage
UserActivityReport.new(user).generate
```

**3. Extract Query Objects**:
```ruby
# Instead of User.active_in_period(start, end)
class ActiveUsersQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def in_period(start_date, end_date)
    @relation.where(last_active_at: start_date..end_date)
  end
end
```

---

## Fat Controllers

Controllers with too much business logic.

### Detection

```bash
# Lines per controller
for file in app/controllers/*.rb; do
  lines=$(wc -l < "$file")
  if [ "$lines" -gt 100 ]; then
    echo "$(basename $file): $lines lines"
  fi
done

# Actions per controller
for file in app/controllers/*.rb; do
  actions=$(grep -c "^[[:space:]]*def " "$file" 2>/dev/null)
  if [ "$actions" -gt 10 ]; then
    echo "$(basename $file): $actions actions"
  fi
done
```

### Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Lines | > 100 | > 200 |
| Actions | > 10 | > 15 |
| Lines per action | > 15 | > 25 |

### Example: Fat Controller

```ruby
# BAD - Controller does too much
class OrdersController < ApplicationController
  def create
    # Validation
    return render_error unless params[:items].present?
    return render_error unless current_user.can_order?

    # Build order
    @order = Order.new(order_params)
    @order.user = current_user

    # Calculate totals
    subtotal = @order.items.sum(&:price)
    tax = subtotal * 0.08
    shipping = calculate_shipping(@order)
    @order.total = subtotal + tax + shipping

    # Apply discounts
    if promo = PromoCode.find_by(code: params[:promo_code])
      @order.discount = promo.calculate_discount(@order)
      @order.total -= @order.discount
    end

    # Process payment
    result = Stripe::Charge.create(
      amount: (@order.total * 100).to_i,
      currency: 'usd',
      source: params[:stripe_token]
    )

    if result.paid?
      @order.payment_id = result.id
      @order.save!

      # Send notifications
      OrderMailer.confirmation(@order).deliver_later
      AdminMailer.new_order(@order).deliver_later

      # Update inventory
      @order.items.each do |item|
        item.product.decrement!(:stock, item.quantity)
      end

      render json: @order, status: :created
    else
      render json: { error: 'Payment failed' }, status: :unprocessable_entity
    end
  rescue Stripe::CardError => e
    render json: { error: e.message }, status: :payment_required
  end
end
```

### Refactored: Thin Controller

```ruby
# GOOD - Controller orchestrates services
class OrdersController < ApplicationController
  def create
    result = CreateOrder.call(
      user: current_user,
      items: order_params[:items],
      promo_code: params[:promo_code],
      payment_token: params[:stripe_token]
    )

    if result.success?
      render json: result.order, status: :created
    else
      render json: { errors: result.errors }, status: result.status
    end
  end

  private

  def order_params
    params.require(:order).permit(items: [:product_id, :quantity])
  end
end
```

---

## Circular Dependencies

When class A depends on class B, and class B depends on class A.

### Detection

```bash
# Find potential circular dependencies in models
for file in app/models/*.rb; do
  class_name=$(grep -m1 "^class" "$file" | awk '{print $2}')
  deps=$(grep -oE "[A-Z][a-z]+[A-Z][a-z]+" "$file" | sort -u)

  for dep in $deps; do
    dep_file="app/models/$(echo $dep | sed 's/\([A-Z]\)/_\L\1/g' | sed 's/^_//').rb"
    if [ -f "$dep_file" ] && grep -q "$class_name" "$dep_file" 2>/dev/null; then
      echo "Potential circular: $class_name <-> $dep"
    fi
  done
done
```

### Examples

**Circular through associations**:
```ruby
# Circular: User -> Team -> User
class User < ApplicationRecord
  belongs_to :team
  has_many :managed_teams, class_name: 'Team', foreign_key: :manager_id
end

class Team < ApplicationRecord
  belongs_to :manager, class_name: 'User'
  has_many :members, class_name: 'User'
end
```

**Circular through service calls**:
```ruby
# Circular: OrderService -> InventoryService -> OrderService
class OrderService
  def create_order(items)
    InventoryService.new.reserve_items(items)
  end
end

class InventoryService
  def reserve_items(items)
    OrderService.new.validate_order(items)  # Circular!
  end
end
```

### Resolution Strategies

**1. Extract shared dependency**:
```ruby
# Before: A <-> B
# After: A -> C <- B

class InventoryValidator  # New shared class
  def validate(items)
    # Shared validation logic
  end
end

class OrderService
  def create_order(items)
    InventoryValidator.new.validate(items)
  end
end
```

**2. Use callbacks/events**:
```ruby
# Instead of direct calls, use events
class OrderService
  def create_order(items)
    order = Order.create!(items: items)
    ActiveSupport::Notifications.instrument('order.created', order: order)
  end
end

class InventoryService
  def self.subscribe
    ActiveSupport::Notifications.subscribe('order.created') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      new.reserve_for_order(event.payload[:order])
    end
  end
end
```

**3. Dependency injection**:
```ruby
class OrderService
  def initialize(inventory_service: InventoryService.new)
    @inventory_service = inventory_service
  end

  def create_order(items)
    @inventory_service.reserve_items(items)
  end
end
```

---

## Layer Violations

When code bypasses architectural layers.

### Common Violations

**View accessing database directly**:
```erb
<%# BAD - Database query in view %>
<% User.where(active: true).each do |user| %>
  <%= user.name %>
<% end %>

<%# GOOD - Use instance variable from controller %>
<% @active_users.each do |user| %>
  <%= user.name %>
<% end %>
```

**Model sending emails**:
```ruby
# BAD - Model has delivery responsibility
class Order < ApplicationRecord
  after_create :send_confirmation

  def send_confirmation
    OrderMailer.confirmation(self).deliver_later
  end
end

# GOOD - Use callback object or service
class Order < ApplicationRecord
  after_create_commit :notify_creation

  private

  def notify_creation
    OrderCreatedJob.perform_later(id)
  end
end
```

**Controller accessing external services**:
```ruby
# BAD - Controller calls external API
class PaymentsController < ApplicationController
  def create
    Stripe::Charge.create(amount: params[:amount])  # Direct API call
  end
end

# GOOD - Use service layer
class PaymentsController < ApplicationController
  def create
    PaymentService.new.charge(current_user, params[:amount])
  end
end
```

### Detection

```bash
# Views with database queries
grep -rn "\.where\|\.find\|\.all" app/views/

# Models with mailer calls
grep -rn "Mailer\." app/models/

# Controllers with external service calls
grep -rn "Stripe::\|Twilio::\|HTTParty" app/controllers/
```

### Proper Layer Responsibilities

| Layer | Should | Should Not |
|-------|--------|------------|
| View | Render data, format output | Query database, call services |
| Controller | Coordinate flow, handle params | Contain business logic |
| Model | Define data, validations, associations | Send emails, call external APIs |
| Service | Business logic, orchestration | Directly render responses |
| Job | Async processing | Return values to caller |

---

## Tight Coupling

When changes in one class require changes in many others.

### Detection

**Afferent Coupling (Ca)** - How many classes depend on this class:
```bash
# Count references to a class
class_name="User"
grep -rln "$class_name" app/ --include="*.rb" | wc -l
```

**Efferent Coupling (Ce)** - How many classes this class depends on:
```bash
# Count classes referenced in a file
grep -oE "[A-Z][a-z]+(::[A-Z][a-z]+)*" app/models/order.rb | sort -u | wc -l
```

### Instability Metric

```
Instability = Ce / (Ca + Ce)
```

- 0 = Maximally stable (many depend on it, hard to change)
- 1 = Maximally unstable (depends on many, easy to change)

High-level modules should be stable; low-level details should be unstable.

### Reducing Coupling

**Use interfaces/protocols**:
```ruby
# Tight coupling
class OrderService
  def process(order)
    StripeGateway.new.charge(order.total)  # Direct dependency
  end
end

# Loose coupling
class OrderService
  def initialize(payment_gateway: StripeGateway.new)
    @payment_gateway = payment_gateway
  end

  def process(order)
    @payment_gateway.charge(order.total)  # Can swap implementation
  end
end
```

---

## Severity Scoring

| Issue | Blast Radius | Fix Effort | Severity |
|-------|--------------|------------|----------|
| God Object (>500 lines) | High | High | Critical |
| Circular dependencies | Medium | High | High |
| Fat controller (>200 lines) | Medium | Medium | High |
| Layer violations (view→DB) | Low | Low | Medium |
| Tight coupling | Medium | Medium | Medium |

### Remediation Priorities

1. **Critical**: God objects blocking feature work
2. **High**: Circular dependencies causing bugs
3. **Medium**: Fat controllers slowing development
4. **Low**: Minor layer violations

---

## Beads Integration

```bash
# Create architecture debt epic
bd create --type epic \
  --title "Address Architecture Debt in Core Models" \
  --priority 1

# Individual tasks
bd create --type task \
  --title "Extract User authentication to concern" \
  --deps EPIC-ID

bd create --type task \
  --title "Refactor OrdersController to use service" \
  --deps EPIC-ID

bd create --type task \
  --title "Break circular dependency User <-> Team" \
  --deps EPIC-ID
```
