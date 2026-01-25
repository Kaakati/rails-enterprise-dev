# Code Smells Reference

Detailed detection patterns and remediation strategies for common code smells in Rails applications.

## Long Method

Methods that are too long and do too much.

### Detection

**Thresholds**:
| Lines | Severity | Action |
|-------|----------|--------|
| 20-40 | Medium | Refactor when touching |
| 40-80 | High | Plan refactoring |
| >80 | Critical | Immediate refactoring |

**Automated Detection**:
```bash
# Using Reek
reek --smell LongMethod app/

# Manual detection
awk '
  /^[[:space:]]*def / {
    start = NR
    gsub(/.*def /, "")
    name = $1
  }
  /^[[:space:]]*end/ && start > 0 {
    len = NR - start
    if (len > 20) print FILENAME ":" name " (" len " lines)"
    start = 0
  }
' app/**/*.rb
```

### Examples

**Smell**:
```ruby
def process_order(order)
  # Validation (lines 1-15)
  raise InvalidOrderError unless order.valid?
  raise EmptyCartError if order.items.empty?
  validate_inventory(order)
  validate_payment_method(order)

  # Calculation (lines 16-40)
  subtotal = order.items.sum(&:price)
  tax = calculate_tax(order, subtotal)
  shipping = calculate_shipping(order)
  discounts = apply_discounts(order, subtotal)
  total = subtotal + tax + shipping - discounts

  # Payment processing (lines 41-70)
  payment_result = process_payment(order, total)
  handle_payment_result(payment_result)

  # Order fulfillment (lines 71-100)
  update_inventory(order)
  create_shipment(order)
  send_confirmation_email(order)

  order.complete!
end
```

**Refactored**:
```ruby
def process_order(order)
  validate_order(order)
  total = calculate_order_total(order)
  process_payment_for(order, total)
  fulfill_order(order)
  order.complete!
end

private

def validate_order(order)
  OrderValidator.new(order).validate!
end

def calculate_order_total(order)
  OrderCalculator.new(order).total
end

def process_payment_for(order, total)
  PaymentProcessor.new(order, total).process!
end

def fulfill_order(order)
  OrderFulfillment.new(order).fulfill!
end
```

### Remediation Patterns

1. **Extract Method**: Pull cohesive chunks into named methods
2. **Extract Service Object**: Move complex logic to dedicated classes
3. **Replace Method with Method Object**: When method has many local variables
4. **Decompose Conditional**: Extract complex conditionals to methods

---

## Large Class

Classes that have grown to do too much.

### Detection

**Thresholds**:
| Lines | Severity | Associations | Methods |
|-------|----------|--------------|---------|
| 150-300 | Medium | 5-10 | 15-25 |
| 300-500 | High | 10-15 | 25-40 |
| >500 | Critical | >15 | >40 |

**Automated Detection**:
```bash
# File size check
for file in app/models/*.rb app/services/*.rb; do
  lines=$(wc -l < "$file" 2>/dev/null)
  if [ "$lines" -gt 150 ]; then
    echo "$file: $lines lines"
  fi
done

# Method count check
for file in app/models/*.rb; do
  methods=$(grep -c "^[[:space:]]*def " "$file" 2>/dev/null)
  if [ "$methods" -gt 20 ]; then
    echo "$file: $methods methods"
  fi
done
```

### Examples

**Smell**: User model that handles too much
```ruby
class User < ApplicationRecord
  # Associations (15+)
  has_many :orders
  has_many :addresses
  has_many :payment_methods
  has_many :preferences
  has_many :notifications
  # ... more associations

  # Validations (20+)
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }
  # ... more validations

  # Authentication methods
  def authenticate(password); end
  def generate_token; end
  def reset_password; end

  # Profile methods
  def full_name; end
  def avatar_url; end
  def update_preferences; end

  # Order methods
  def recent_orders; end
  def total_spent; end
  def favorite_products; end

  # Notification methods
  def unread_notifications; end
  def mark_all_read; end

  # 50+ more methods...
end
```

**Refactored**:
```ruby
class User < ApplicationRecord
  include User::Authentication
  include User::Profile
  include User::Orders
  include User::Notifications

  has_many :orders
  has_many :addresses

  validates :email, presence: true, uniqueness: true
end

# app/models/concerns/user/authentication.rb
module User::Authentication
  extend ActiveSupport::Concern

  def authenticate(password); end
  def generate_token; end
  def reset_password; end
end

# app/models/concerns/user/orders.rb
module User::Orders
  extend ActiveSupport::Concern

  def recent_orders
    orders.recent
  end

  def total_spent
    orders.completed.sum(:total)
  end
end
```

### Remediation Patterns

1. **Extract Concern**: Move related methods to concerns
2. **Extract Class**: Create new classes for distinct responsibilities
3. **Extract Module**: Group related functionality
4. **Delegate to Service Objects**: Move business logic out of models

---

## Feature Envy

Method uses another object's data more than its own.

### Detection

Look for methods that:
- Call multiple methods on the same external object
- Access another object's attributes repeatedly
- Could logically belong to the other class

**Pattern Recognition**:
```ruby
# Envy indicator: Multiple calls to same object
def calculate_shipping(order)
  order.items.count * order.shipping_rate +
    order.address.zone_surcharge +
    order.express? ? order.express_fee : 0
end
```

### Examples

**Smell**:
```ruby
class InvoiceGenerator
  def generate(order)
    pdf = PDF.new
    pdf.add_header("Invoice for #{order.customer.name}")
    pdf.add_line("Email: #{order.customer.email}")
    pdf.add_line("Address: #{order.customer.address.full}")

    order.items.each do |item|
      pdf.add_line("#{item.name}: #{item.quantity} x #{item.price}")
    end

    pdf.add_line("Subtotal: #{order.subtotal}")
    pdf.add_line("Tax: #{order.tax}")
    pdf.add_line("Total: #{order.total}")
    pdf
  end
end
```

**Refactored**:
```ruby
class InvoiceGenerator
  def generate(order)
    pdf = PDF.new
    add_customer_section(pdf, order.customer)
    add_items_section(pdf, order.items)
    add_totals_section(pdf, order.totals)
    pdf
  end
end

class Order
  def totals
    OrderTotals.new(subtotal: subtotal, tax: tax, total: total)
  end
end

class Customer
  def invoice_header
    "Invoice for #{name}"
  end

  def contact_info
    { email: email, address: address.full }
  end
end
```

### Remediation Patterns

1. **Move Method**: Move the method to the class it envies
2. **Extract Method + Move**: Extract envious code, then move it
3. **Introduce Parameter Object**: If passing many attributes

---

## Data Clump

Same group of data items appear together repeatedly.

### Detection

Look for:
- Same parameters passed to multiple methods
- Same fields in multiple classes
- Repeated parameter combinations

**Pattern Recognition**:
```bash
# Find repeated parameter patterns
grep -rn "def.*address.*city.*state.*zip" app/
grep -rn "def.*start_date.*end_date" app/
```

### Examples

**Smell**:
```ruby
def create_user(name, email, phone, street, city, state, zip)
def update_user(name, email, phone, street, city, state, zip)
def validate_address(street, city, state, zip)
def format_address(street, city, state, zip)
def ship_to(street, city, state, zip)
```

**Refactored**:
```ruby
# Value object for address
class Address
  attr_reader :street, :city, :state, :zip

  def initialize(street:, city:, state:, zip:)
    @street = street
    @city = city
    @state = state
    @zip = zip
  end

  def valid?
    street.present? && city.present? && state.present? && zip.present?
  end

  def formatted
    "#{street}, #{city}, #{state} #{zip}"
  end
end

# Usage
def create_user(name, email, phone, address)
def ship_to(address)
```

### Remediation Patterns

1. **Extract Class**: Create a value object for the clump
2. **Introduce Parameter Object**: Wrap parameters in an object
3. **Preserve Whole Object**: Pass the entire object instead of parts

---

## Primitive Obsession

Using primitives instead of small objects for simple tasks.

### Detection

Look for:
- String/integer patterns representing concepts (phone, email, money)
- Repeated validation of the same primitive type
- Constants or arrays used to represent types

### Examples

**Smell**:
```ruby
class Order
  attr_accessor :status  # String: "pending", "processing", "shipped", "delivered"
  attr_accessor :total   # Float for money
  attr_accessor :phone   # String for phone number

  def shipped?
    status == "shipped"
  end

  def valid_phone?
    phone.match?(/\A\d{10}\z/)
  end
end
```

**Refactored**:
```ruby
class Order
  enum status: { pending: 0, processing: 1, shipped: 2, delivered: 3 }
  monetize :total_cents

  has_one :phone_number
end

class PhoneNumber
  validates :number, format: { with: /\A\d{10}\z/ }

  def formatted
    "(#{number[0..2]}) #{number[3..5]}-#{number[6..9]}"
  end
end
```

---

## Summary: Detection Commands

```bash
# All code smells via Reek
reek app/ --format json

# Long methods
reek --smell LongMethod app/

# Large classes
reek --smell LargeClass app/

# Feature envy
reek --smell FeatureEnvy app/

# Data clumps
reek --smell DataClump app/

# Primitive obsession (manual check)
grep -rn "== ['\"].*['\"]" app/models/  # String comparisons
```
