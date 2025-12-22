---
name: "ActiveRecord Query Patterns"
description: "Complete guide to ActiveRecord query optimization, associations, scopes, and PostgreSQL-specific patterns. Use this skill when writing database queries, designing model associations, creating migrations, optimizing query performance, or debugging N+1 queries and grouping errors."
---

# ActiveRecord Query Patterns Skill

This skill provides comprehensive guidance for writing efficient, correct ActiveRecord queries in Rails applications with PostgreSQL.

## When to Use This Skill

- Writing complex ActiveRecord queries
- Designing model associations
- Creating database migrations
- Optimizing query performance
- Debugging N+1 queries
- Working with GROUP BY operations
- Implementing scopes and query objects

## Model Structure

### Standard Model Template

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  # == Constants ============================================================
  STATUSES = %w[pending in_progress completed failed cancelled].freeze

  # == Associations =========================================================
  belongs_to :account
  belongs_to :merchant
  belongs_to :carrier, optional: true
  belongs_to :recipient
  belongs_to :zone, optional: true
  
  has_many :timelines, dependent: :destroy
  has_many :task_actions, dependent: :destroy
  has_many :photos, dependent: :destroy

  # == Validations ==========================================================
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :tracking_number, presence: true, uniqueness: { scope: :account_id }

  # == Scopes ===============================================================
  scope :active, -> { where.not(status: %w[completed failed cancelled]) }
  scope :completed, -> { where(status: 'completed') }
  scope :for_carrier, ->(carrier) { where(carrier: carrier) }
  scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # == Callbacks ============================================================
  before_validation :generate_tracking_number, on: :create
  after_commit :notify_recipient, on: :create

  # == Class Methods ========================================================
  def self.search(query)
    where("tracking_number ILIKE :q OR description ILIKE :q", q: "%#{query}%")
  end

  # == Instance Methods =====================================================
  def completable?
    %w[pending in_progress].include?(status)
  end

  def complete!
    update!(status: 'completed', completed_at: Time.current)
  end

  private

  def generate_tracking_number
    self.tracking_number ||= SecureRandom.hex(8).upcase
  end

  def notify_recipient
    TaskNotificationJob.perform_later(id)
  end
end
```

## Association Patterns

### Basic Associations

```ruby
# One-to-Many
class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :tasks, dependent: :destroy
end

class User < ApplicationRecord
  belongs_to :account
end

# Many-to-Many (with join table)
class Task < ApplicationRecord
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
end

class Tag < ApplicationRecord
  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags
end

class TaskTag < ApplicationRecord
  belongs_to :task
  belongs_to :tag
end

# Polymorphic
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

class Task < ApplicationRecord
  has_many :comments, as: :commentable
end

class Invoice < ApplicationRecord
  has_many :comments, as: :commentable
end
```

### Association Options

```ruby
class Task < ApplicationRecord
  # Foreign key specification
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by_id'
  
  # Optional association
  belongs_to :carrier, optional: true
  
  # Counter cache
  belongs_to :merchant, counter_cache: true
  
  # Dependent options
  has_many :photos, dependent: :destroy      # Delete associated records
  has_many :logs, dependent: :nullify        # Set foreign key to NULL
  has_many :exports, dependent: :restrict_with_error  # Prevent deletion
  
  # Scoped association
  has_many :active_timelines, -> { where(active: true) }, class_name: 'Timeline'
  
  # Touch parent on update
  belongs_to :bundle, touch: true
end
```

## Query Patterns

### Basic Queries

```ruby
# Find
Task.find(1)                    # Raises RecordNotFound
Task.find_by(id: 1)             # Returns nil if not found
Task.find_by!(id: 1)            # Raises RecordNotFound

# Where
Task.where(status: 'pending')
Task.where(status: %w[pending in_progress])  # IN query
Task.where.not(status: 'completed')
Task.where(created_at: 1.week.ago..)         # Range (>= date)
Task.where(created_at: ..1.week.ago)         # Range (<= date)
Task.where(created_at: 1.month.ago..1.week.ago)  # Between

# Order
Task.order(created_at: :desc)
Task.order(:status, created_at: :desc)

# Limit & Offset
Task.limit(10).offset(20)

# Distinct
Task.distinct.pluck(:status)
```

### Avoiding N+1 Queries

```ruby
# WRONG - N+1 query
tasks = Task.all
tasks.each { |t| puts t.carrier.name }  # Query per task!

# CORRECT - Eager loading
tasks = Task.includes(:carrier)
tasks.each { |t| puts t.carrier.name }  # Single query

# Multiple associations
Task.includes(:carrier, :merchant, :recipient)

# Nested associations
Task.includes(merchant: :branches)

# With conditions on association (use joins or references)
Task.includes(:carrier).where(carriers: { active: true }).references(:carriers)
# OR
Task.joins(:carrier).where(carriers: { active: true })
```

### Choosing Loading Strategy

```ruby
# includes - Smart loading (preload or eager_load based on usage)
Task.includes(:carrier)

# preload - Separate queries (can't filter on association)
Task.preload(:carrier)
# SELECT * FROM tasks
# SELECT * FROM carriers WHERE id IN (...)

# eager_load - Single LEFT JOIN query
Task.eager_load(:carrier)
# SELECT tasks.*, carriers.* FROM tasks LEFT JOIN carriers...

# joins - INNER JOIN (no loading, just filtering)
Task.joins(:carrier).where(carriers: { active: true })
```

### GROUP BY Queries (Critical for PostgreSQL)

**Rule**: Every non-aggregated column in SELECT must appear in GROUP BY.

```ruby
# CORRECT - Only grouped columns and aggregates
Task.group(:status).count
# => { "pending" => 10, "completed" => 25 }

Task.group(:status).sum(:amount)
# => { "pending" => 1000, "completed" => 5000 }

# CORRECT - Multiple GROUP BY columns
Task
  .group(:status, :task_type)
  .count
# => { ["pending", "express"] => 5, ["completed", "standard"] => 10 }

# CORRECT - Explicit select with aggregates
Task
  .select(:status, 'COUNT(*) as task_count', 'AVG(amount) as avg_amount')
  .group(:status)

# CORRECT - Date grouping
Task
  .group("DATE(created_at)")
  .count

# WRONG - includes with group
Task.includes(:carrier).group(:status).count  # ERROR!

# CORRECT - Separate queries if you need associated data
status_counts = Task.group(:status).count
tasks_by_status = status_counts.keys.each_with_object({}) do |status, hash|
  hash[status] = Task.where(status: status).includes(:carrier).limit(5)
end
```

### Subqueries

```ruby
# Subquery in WHERE
active_carrier_ids = Carrier.where(active: true).select(:id)
Task.where(carrier_id: active_carrier_ids)
# SELECT * FROM tasks WHERE carrier_id IN (SELECT id FROM carriers WHERE active = true)

# Subquery with join
Task.where(carrier_id: Carrier.active.select(:id))
    .where(merchant_id: Merchant.premium.select(:id))
```

### Raw SQL (When Needed)

```ruby
# Safe with sanitization
Task.where("created_at > ?", 1.week.ago)
Task.where("description ILIKE ?", "%#{query}%")

# Named bindings
Task.where("status = :status AND amount > :min", status: 'pending', min: 100)

# Select with raw SQL
Task.select("*, amount * 0.1 as commission")

# Find by SQL
Task.find_by_sql(["SELECT * FROM tasks WHERE status = ?", 'pending'])
```

## Scope Patterns

### Simple Scopes

```ruby
class Task < ApplicationRecord
  scope :active, -> { where.not(status: %w[completed cancelled]) }
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Time.current.all_day) }
end
```

### Parameterized Scopes

```ruby
class Task < ApplicationRecord
  scope :by_status, ->(status) { where(status: status) }
  scope :created_after, ->(date) { where('created_at >= ?', date) }
  scope :for_carrier, ->(carrier_id) { where(carrier_id: carrier_id) }
  
  # With default
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }
  
  # Conditional scope
  scope :by_status_if_present, ->(status) { where(status: status) if status.present? }
end
```

### Chainable Scopes

```ruby
# All scopes are chainable
Task.active.recent.by_status('pending').for_carrier(123)

# Combine with where
Task.active.where(merchant_id: 456)
```

## Query Objects

```ruby
# app/queries/tasks/pending_delivery_query.rb
module Tasks
  class PendingDeliveryQuery
    def initialize(relation = Task.all)
      @relation = relation
    end

    def call(zone_id: nil, since: 24.hours.ago)
      result = @relation
        .where(status: 'pending')
        .where('created_at >= ?', since)
        .includes(:carrier, :recipient)
      
      result = result.where(zone_id: zone_id) if zone_id.present?
      result.order(created_at: :asc)
    end
  end
end

# Usage
Tasks::PendingDeliveryQuery.new.call(zone_id: 123)
Tasks::PendingDeliveryQuery.new(account.tasks).call(since: 1.hour.ago)
```

## Migration Patterns

### Create Table

```ruby
class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :account, null: false, foreign_key: true
      t.references :merchant, null: false, foreign_key: true
      t.references :carrier, foreign_key: true  # nullable
      
      t.string :tracking_number, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :amount, precision: 10, scale: 2
      t.jsonb :metadata, default: {}
      
      t.datetime :completed_at
      t.timestamps
      
      t.index :tracking_number, unique: true
      t.index :status
      t.index [:account_id, :status]
      t.index [:merchant_id, :created_at]
      t.index :metadata, using: :gin  # For JSONB queries
    end
  end
end
```

### Safe Migrations

```ruby
# Add column with default (safe in PostgreSQL 11+)
class AddPriorityToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :priority, :integer, default: 0, null: false
  end
end

# Add index concurrently (for large tables)
class AddIndexToTasksStatus < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :tasks, :status, algorithm: :concurrently
  end
end

# Remove column safely
class RemoveOldColumnFromTasks < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :tasks, :old_column, :string }
  end
end
```

### JSONB Columns

```ruby
# Migration
add_column :tasks, :metadata, :jsonb, default: {}
add_index :tasks, :metadata, using: :gin

# Model
class Task < ApplicationRecord
  # Using jsonb_accessor gem
  jsonb_accessor :metadata,
    priority: :integer,
    tags: [:string, array: true],
    notes: :string
end

# Queries
Task.where("metadata @> ?", { priority: 1 }.to_json)
Task.where("metadata->>'priority' = ?", '1')
Task.where("metadata ? 'special_flag'")
```

## Performance Optimization

### Batch Processing

```ruby
# WRONG - Loads all records into memory
Task.all.each { |task| process(task) }

# CORRECT - Batches of 1000
Task.find_each(batch_size: 1000) { |task| process(task) }

# With specific order
Task.order(:id).find_each { |task| process(task) }

# In batches (for batch operations)
Task.in_batches(of: 1000) do |batch|
  batch.update_all(processed: true)
end
```

### Select Only Needed Columns

```ruby
# WRONG - Loads all columns
users = User.all
users.each { |u| puts u.email }

# CORRECT - Only needed columns
users = User.select(:id, :email)
users.each { |u| puts u.email }

# With pluck (returns arrays, not AR objects)
emails = User.pluck(:email)
```

### Counter Caches

```ruby
# Migration
add_column :merchants, :tasks_count, :integer, default: 0

# Model
class Task < ApplicationRecord
  belongs_to :merchant, counter_cache: true
end

# Now merchant.tasks_count doesn't query
merchant.tasks_count  # Uses cached count
```

### Exists? vs Any? vs Present?

```ruby
# EFFICIENT - Stops at first match
Task.where(status: 'pending').exists?
# SELECT 1 FROM tasks WHERE status = 'pending' LIMIT 1

# LESS EFFICIENT - Loads records
Task.where(status: 'pending').any?
# May load records depending on implementation

# INEFFICIENT - Loads all records
Task.where(status: 'pending').present?
# SELECT * FROM tasks WHERE status = 'pending'
```

### Explain & Analyze

```ruby
# In Rails console
Task.where(status: 'pending').explain
Task.where(status: 'pending').explain(:analyze)

# Check for sequential scans on large tables
# Look for "Seq Scan" - may need index
```

## Debugging Queries

```bash
# In Rails console, enable query logging
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Or in development.rb
config.active_record.verbose_query_logs = true

# Using bullet gem for N+1 detection
# Gemfile: gem 'bullet', group: :development
```

## Pre-Query Checklist

Before writing any complex query:

```
[ ] What columns am I selecting?
[ ] Am I using GROUP BY? If so, is every SELECT column grouped or aggregated?
[ ] Am I using includes/preload with GROUP BY? (DON'T!)
[ ] Will this query run on a large table? Do indexes exist?
[ ] Am I iterating and accessing associations? Use includes.
[ ] Am I loading more data than needed? Use select/pluck.
```
