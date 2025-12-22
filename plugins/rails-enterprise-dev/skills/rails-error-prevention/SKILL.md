---
name: Rails Error Prevention
description: Common junior developer mistakes and how to prevent them
version: 1.0.0
category: core
---

# Rails Error Prevention Patterns

Comprehensive guide to preventing common junior developer mistakes in Rails applications.

## Overview

This skill covers the most frequent error patterns that cause production bugs:
- **Nil handling errors** (`NoMethodError: undefined method for nil`)
- **N+1 query problems** (performance issues)
- **Security vulnerabilities** (mass assignment, SQL injection, XSS)
- **Validation failures** (unhandled errors)
- **Performance mistakes** (inefficient queries, memory issues)

---

## 1. NIL HANDLING BEST PRACTICES

### Pattern 1: Safe Navigation Operator

**Problem:**
```ruby
# Crashes if user is nil
user.email.downcase

# Crashes if email is nil
user.email.downcase
```

**Solution:**
```ruby
# Returns nil if user is nil
user&.email&.downcase

# With default value
user&.email&.downcase || 'no-email@example.com'

# For hash access
credentials.dig(:api, :key) || 'default_key'
```

**When to use:**
- Chain of method calls on potentially nil objects
- Accessing attributes from associations that might not exist
- Optional parameters or attributes
- Data from external sources (APIs, user input)

**When NOT to use:**
- When nil should be an error (use validations instead)
- When chaining more than 2-3 calls (refactor to explicit nil check)
- In performance-critical code (safe navigation has small overhead)

### Pattern 2: Presence Validations

**Always validate required fields at the model level:**

```ruby
class Payment < ApplicationRecord
  # Required fields
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending paid failed refunded] }
  validates :account_id, presence: true
  validates :currency, presence: true

  # Format validations
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :email?
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, if: :phone?

  # Uniqueness with index (prevents race conditions)
  validates :transaction_id, uniqueness: true
end
```

**Why this prevents nil errors:**
- Database won't allow nil values for validated fields
- Code can safely assume these fields exist
- Validation failures caught early (before `create!` crashes)

### Pattern 3: Handle find_by Returning Nil

**Problem:**
```ruby
# Crashes if not found
user = User.find_by(email: email)
user.name  # NoMethodError if user is nil
```

**Solutions:**

**Option 1: Use find! to raise exception**
```ruby
user = User.find_by!(email: email)  # Raises ActiveRecord::RecordNotFound
user.name  # Safe, exception already raised if not found
```

**Option 2: Handle nil explicitly**
```ruby
user = User.find_by(email: email)
if user
  user.name
else
  'User not found'
end
```

**Option 3: Safe navigation**
```ruby
User.find_by(email: email)&.name || 'Unknown'
```

**Option 4: Use find_or_initialize_by**
```ruby
# Always returns a user (either found or new)
user = User.find_or_initialize_by(email: email)
user.new_record?  # true if not found
```

### Pattern 4: Handling Nil in Collections

**Problem:**
```ruby
# Crashes if hash has nil keys or values
credentials.each do |key, value|
  key.to_sym  # NoMethodError if key is nil
  value.upcase  # NoMethodError if value is nil
end
```

**Solutions:**

**Compact before iteration:**
```ruby
# Remove nil keys/values
credentials.compact.each do |key, value|
  key.to_sym  # Safe, no nil keys after compact
end
```

**Check presence in iteration:**
```ruby
credentials.each do |key, value|
  next if key.nil? || value.nil?

  key.to_sym  # Safe after nil check
end
```

**Use safe navigation:**
```ruby
credentials.each do |key, value|
  key&.to_sym
  value&.upcase
end
```

### Pattern 5: Explicit Nil Checks for Complex Logic

**For complex conditionals, be explicit:**

```ruby
# Good: Clear what happens when nil
def process_payment(amount)
  return Result.failure('Amount required') if amount.nil?
  return Result.failure('Amount must be positive') if amount <= 0

  # Safe to proceed, amount is validated
  Payment.create(amount: amount)
end
```

**Bad: Relying on falsy behavior**
```ruby
def process_payment(amount)
  return unless amount  # What about amount = 0?
  Payment.create(amount: amount)
end
```

---

## 2. N+1 QUERY PREVENTION

### Pattern 1: Always Use Includes for Associations

**Problem:**
```ruby
# Controller
@posts = Post.all

# View: app/views/posts/index.html.erb
<% @posts.each do |post| %>
  <%= post.author.name %>  # N+1! Queries author for each post
  <%= post.comments.count %>  # Another N+1!
<% end %>
```

**Solution:**
```ruby
# Controller
@posts = Post.includes(:author)
             .left_joins(:comments)
             .select('posts.*, COUNT(comments.id) as comments_count')
             .group('posts.id')

# View - Now only 2 queries total
<% @posts.each do |post| %>
  <%= post.author.name %>  # Already loaded
  <%= post.comments_count %>  # Pre-counted
<% end %>
```

### Pattern 2: Use Bullet Gem in Development

**Add to Gemfile:**
```ruby
group :development do
  gem 'bullet'
end
```

**Configure in config/environments/development.rb:**
```ruby
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = false  # Don't show browser alerts
  Bullet.console = true  # Show in console
  Bullet.rails_logger = true  # Log to Rails logger
  Bullet.add_footer = true  # Add footer to pages
end
```

**Bullet will warn you about:**
- N+1 queries (use `includes`)
- Unused eager loading (remove unnecessary `includes`)
- Missing counter caches

### Pattern 3: Preload Nested Associations

**For nested associations:**

```ruby
# Bad: N+1 for both comments and comment authors
@posts = Post.includes(:comments)

# Good: Preload nested associations
@posts = Post.includes(comments: :author)

# For multiple levels
@posts = Post.includes(
  :author,
  comments: [:author, :reactions],
  tags: :category
)
```

### Pattern 4: Use Counter Caches

**For frequently accessed counts:**

```ruby
# Migration
class AddCommentsCountToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :comments_count, :integer, default: 0, null: false

    # Backfill existing data
    Post.find_each do |post|
      Post.reset_counters(post.id, :comments)
    end
  end
end

# Model
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# Usage (no query!)
post.comments_count  # Uses cached column, not COUNT query
```

---

## 3. SECURITY PATTERNS

### Pattern 1: Always Use Strong Parameters

**Never:**
```ruby
User.create(params[:user])  # Mass assignment vulnerability!
```

**Always:**
```ruby
def create
  @user = User.new(user_params)

  if @user.save
    redirect_to @user, notice: 'User created'
  else
    render :new, alert: 'Failed to create user'
  end
end

private

def user_params
  params.require(:user).permit(:name, :email, :password)
end
```

**For nested attributes:**
```ruby
def post_params
  params.require(:post).permit(
    :title,
    :body,
    :published,
    comments_attributes: [:id, :body, :author_name, :_destroy]
  )
end
```

### Pattern 2: SQL Injection Prevention

**Never:**
```ruby
User.where("email = '#{email}'")  # SQL injection vulnerability!
User.where("age > #{age}")  # Also vulnerable!
```

**Always:**
```ruby
# Option 1: Placeholders (safest)
User.where("email = ?", email)
User.where("age > ? AND active = ?", age, true)

# Option 2: Hash conditions (preferred)
User.where(email: email)
User.where(age: 18..65, active: true)

# Option 3: Named placeholders (readable)
User.where("email = :email AND active = :active", email: email, active: true)
```

### Pattern 3: XSS Prevention

**In views, Rails auto-escapes by default:**

```erb
<!-- Safe: Automatically escaped -->
<%= user.bio %>

<!-- Dangerous: Marks as HTML safe (only use if you trust the content) -->
<%= user.bio.html_safe %>

<!-- Safe: Sanitize user-generated HTML -->
<%= sanitize user.bio, tags: %w[p br strong em], attributes: %w[href] %>

<!-- Safe: Strip all HTML -->
<%= strip_tags user.bio %>
```

### Pattern 4: Secure Password Handling

**Always use has_secure_password:**

```ruby
# Model
class User < ApplicationRecord
  has_secure_password

  validates :password, length: { minimum: 8 }, if: :password_digest_changed?
end

# Controller
def create
  @user = User.new(user_params)

  if @user.save
    session[:user_id] = @user.id
    redirect_to root_path
  else
    render :new
  end
end

private

def user_params
  params.require(:user).permit(:email, :password, :password_confirmation)
end
```

**Never:**
- Store passwords in plain text
- Use reversible encryption (use bcrypt via `has_secure_password`)
- Log passwords
- Display passwords in error messages

---

## 4. ERROR HANDLING PATTERNS

### Pattern 1: Rescue Specific Exceptions

**Bad:**
```ruby
begin
  payment = process_payment(amount)
rescue StandardError => e
  # Too broad! Catches everything including typos
  Rails.logger.error(e.message)
end
```

**Good:**
```ruby
begin
  payment = process_payment(amount)
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error("Payment validation failed: #{e.message}")
  Result.failure(e.record.errors)
rescue Stripe::CardError => e
  Rails.logger.error("Card error: #{e.message}")
  Result.failure("Card declined")
rescue Stripe::RateLimitError => e
  Rails.logger.error("Stripe rate limit: #{e.message}")
  Result.failure("Service temporarily unavailable")
rescue StandardError => e
  # Catch-all for unexpected errors
  Rails.logger.error("Unexpected payment error: #{e.class} - #{e.message}")
  Sentry.capture_exception(e)
  Result.failure("Payment processing failed")
end
```

### Pattern 2: Handle Validation Failures

**Bad:**
```ruby
def create
  @payment = Payment.create!(payment_params)  # Raises on failure
  redirect_to @payment
end
```

**Good:**
```ruby
def create
  @payment = Payment.new(payment_params)

  if @payment.save
    redirect_to @payment, notice: 'Payment created successfully'
  else
    flash.now[:alert] = 'Payment could not be created'
    render :new, status: :unprocessable_entity
  end
end
```

### Pattern 3: Use Result Pattern for Services

**For service objects, return structured results:**

```ruby
class ProcessPayment
  def self.call(amount:, user:)
    new(amount, user).call
  end

  def initialize(amount, user)
    @amount = amount
    @user = user
  end

  def call
    return Result.failure('Amount required') if @amount.nil?
    return Result.failure('Amount must be positive') if @amount <= 0
    return Result.failure('User required') if @user.nil?

    payment = Payment.new(amount: @amount, user: @user)

    unless payment.save
      return Result.failure(payment.errors.full_messages)
    end

    charge_result = charge_stripe(payment)

    unless charge_result.success?
      payment.update(status: 'failed')
      return Result.failure(charge_result.error)
    end

    payment.update(status: 'paid')
    Result.success(payment)

  rescue Stripe::CardError => e
    payment&.update(status: 'failed')
    Result.failure("Card declined: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Payment processing error: #{e.class} - #{e.message}")
    Sentry.capture_exception(e)
    Result.failure("Payment processing failed")
  end
end

# Result object (simple implementation)
class Result
  attr_reader :value, :error

  def self.success(value)
    new(success: true, value: value)
  end

  def self.failure(error)
    new(success: false, error: error)
  end

  def initialize(success:, value: nil, error: nil)
    @success = success
    @value = value
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
```

---

## 5. PERFORMANCE PATTERNS

### Pattern 1: Select Only Needed Columns

**Inefficient:**
```ruby
# Loads all columns (including large text fields)
Post.all.map(&:title)

# Loads entire records just to get IDs
user.posts.map(&:id)
```

**Efficient:**
```ruby
# Only loads title column
Post.pluck(:title)

# Only loads IDs
user.posts.ids  # or user.post_ids (if association exists)

# Multiple columns
Post.pluck(:id, :title, :created_at)

# With select (returns ActiveRecord objects, but only with selected attributes)
Post.select(:id, :title, :created_at)
```

### Pattern 2: Use exists? Instead of any?

**Inefficient:**
```ruby
if User.where(active: true).any?  # Loads records into memory
if User.where(active: true).count > 0  # Counts all records
```

**Efficient:**
```ruby
if User.where(active: true).exists?  # Just checks existence (LIMIT 1)
```

### Pattern 3: Batch Processing with find_each

**Inefficient:**
```ruby
# Loads ALL users into memory at once
User.all.each do |user|
  user.update(processed: true)
end
```

**Efficient:**
```ruby
# Processes in batches of 1000 (configurable)
User.find_each(batch_size: 1000) do |user|
  user.update(processed: true)
end

# For batch operations
User.in_batches(of: 1000) do |batch|
  batch.update_all(processed: true)  # Single UPDATE query per batch
end
```

### Pattern 4: Avoid N+1 in Calculations

**Inefficient:**
```ruby
# Queries for each post
total_comments = posts.sum { |post| post.comments.count }
```

**Efficient:**
```ruby
# Single query with GROUP BY
total_comments = Comment.where(post_id: posts.ids).count
```

### Pattern 5: Use find_by Instead of where.first

**Less Efficient:**
```ruby
User.where(email: email).first  # WHERE ... LIMIT 1
User.where(email: email).take  # WHERE ... LIMIT 1 (no ordering)
```

**More Efficient:**
```ruby
User.find_by(email: email)  # More idiomatic, same result
```

---

## 6. MIGRATION SAFETY PATTERNS

### Pattern 1: Always Add Indexes on Foreign Keys

**Always:**
```ruby
class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      # foreign_key: true adds constraint
      # index: true adds index for performance
      t.references :account, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    # Composite indexes for common queries
    add_index :payments, [:account_id, :status]
    add_index :payments, [:user_id, :created_at]
  end
end
```

### Pattern 2: Make Migrations Reversible

**Bad:**
```ruby
def change
  execute "UPDATE users SET role = 'member' WHERE role IS NULL"
end
```

**Good:**
```ruby
def up
  execute "UPDATE users SET role = 'member' WHERE role IS NULL"
end

def down
  # Provide a way to reverse (if possible)
  execute "UPDATE users SET role = NULL WHERE role = 'member'"
end
```

**For irreversible migrations:**
```ruby
def up
  drop_table :legacy_data
end

def down
  raise ActiveRecord::IrreversibleMigration
end
```

### Pattern 3: Add NULL Constraints Safely

**Unsafe (will fail if existing rows have nil):**
```ruby
def change
  change_column_null :users, :email, false
end
```

**Safe:**
```ruby
def up
  # 1. Set default for existing nil values
  User.where(email: nil).update_all(email: 'noemail@example.com')

  # 2. Add constraint
  change_column_null :users, :email, false
end

def down
  change_column_null :users, :email, true
end
```

### Pattern 4: Add Uniqueness Constraints with Index

**Race Condition (validation only):**
```ruby
# Model only
validates :email, uniqueness: true

# Two simultaneous requests can create duplicates
```

**Safe (database constraint):**
```ruby
# Migration
add_index :users, :email, unique: true

# Model
validates :email, uniqueness: true
```

---

## 7. COMMON EDGE CASES TO TEST

Always write tests for these scenarios:

**Nil and Empty Values:**
- [ ] Nil values
- [ ] Empty strings (`""`)
- [ ] Empty arrays (`[]`)
- [ ] Empty hashes (`{}`)
- [ ] Blank strings with whitespace (`"   "`)

**Numeric Edge Cases:**
- [ ] Zero (`0`)
- [ ] Negative numbers
- [ ] Very large numbers
- [ ] Decimal precision issues
- [ ] Division by zero

**String Edge Cases:**
- [ ] Very long strings
- [ ] Special characters
- [ ] Unicode characters
- [ ] SQL injection attempts
- [ ] XSS attempts

**Date/Time Edge Cases:**
- [ ] Timezones
- [ ] Daylight saving time transitions
- [ ] Leap years
- [ ] Date boundaries (beginning/end of month/year)

**ActiveRecord Edge Cases:**
- [ ] Records not found
- [ ] Validation failures
- [ ] Duplicate values (uniqueness)
- [ ] Missing associations
- [ ] Cascading deletes
- [ ] Concurrent updates (optimistic locking)

---

## 8. PRE-IMPLEMENTATION CHECKLIST

Before writing any code, ensure you understand:

**For Models:**
- [ ] What fields are required? (add validations)
- [ ] What associations exist? (add `dependent:` option)
- [ ] What should be indexed? (foreign keys, frequently queried columns)
- [ ] Are there uniqueness constraints? (add unique index)
- [ ] What can be nil? (use safe navigation for optional fields)

**For Controllers:**
- [ ] What parameters are accepted? (define strong params)
- [ ] How are validation failures handled? (render vs redirect)
- [ ] What exceptions might occur? (rescue specific exceptions)
- [ ] Are there authorization checks? (before_action)
- [ ] Is this vulnerable to N+1? (use includes)

**For Services:**
- [ ] What inputs are required? (validate at start)
- [ ] What can go wrong? (rescue specific exceptions)
- [ ] How are errors communicated? (Result pattern)
- [ ] Is this transactional? (wrap in ActiveRecord::Base.transaction)
- [ ] Are there external dependencies? (handle timeouts, failures)

**For Views:**
- [ ] Can any values be nil? (use safe navigation)
- [ ] Is user input displayed? (sanitize or escape)
- [ ] Are there N+1 queries? (check with Bullet)
- [ ] Is this accessible? (proper HTML semantics, ARIA)

---

## 9. QUICK REFERENCE: SAFE VS UNSAFE PATTERNS

### Nil Safety

| Unsafe | Safe |
|--------|------|
| `user.email` | `user&.email` |
| `params[:id].to_i` | `params[:id]&.to_i || 0` |
| `find_by(...).name` | `find_by(...)&.name` |
| `data.each { \|k,v\| k.to_sym }` | `data.compact.each { \|k,v\| k.to_sym }` |

### N+1 Prevention

| Unsafe | Safe |
|--------|------|
| `Post.all` (in view with `post.author`) | `Post.includes(:author)` |
| `posts.map(&:comments).flatten` | `Comment.where(post_id: posts.ids)` |
| `post.comments.count` (in loop) | Add counter_cache |
| `where(...).count > 0` | `where(...).exists?` |

### Security

| Unsafe | Safe |
|--------|------|
| `User.create(params[:user])` | `User.create(user_params)` |
| `where("email = '#{email}'"` | `where("email = ?", email)` |
| `<%= raw user.bio %>` | `<%= sanitize user.bio %>` |
| Storing plain text passwords | `has_secure_password` |

### Performance

| Inefficient | Efficient |
|-------------|-----------|
| `Post.all.map(&:title)` | `Post.pluck(:title)` |
| `User.all.each { ... }` | `User.find_each { ... }` |
| `where(...).any?` | `where(...).exists?` |
| `where(...).first` | `find_by(...)` |

---

## 10. REMEMBER

**The Error Prevention Hierarchy:**

1. **Prevent at Database Level** (constraints, indexes, NOT NULL)
2. **Validate at Model Level** (presence, format, uniqueness)
3. **Check at Service Level** (input validation, explicit nil checks)
4. **Handle at Controller Level** (strong params, rescue exceptions)
5. **Safe Navigation in Views** (`&.`, presence checks)

**When in Doubt:**
- Add a validation
- Use safe navigation
- Handle the error explicitly
- Write a test for the edge case

**Junior Developer Motto:**
> "If it can be nil, it will be nil. If it can fail, it will fail. Plan accordingly."
