---
paths: app/models/**/*.rb
---

# Rails Model Conventions

Apply to all files in `app/models/**/*.rb`

## Structure Order

Organize model code in this specific order:

1. **Constants** (`STATUSES = []`, `ROLES = []`, etc.)
2. **Enums** (`enum :status, [...]`)
3. **Associations** (`belongs_to`, `has_many`, etc.)
4. **Validations** (`validates`, `validate`)
5. **Scopes** (`scope :active, -> { ... }`)
6. **Callbacks** (`before_save`, `after_create`, etc.)
7. **Class methods** (`def self.method_name`)
8. **Instance methods** (public `def method_name`)
9. **Private methods** (`private` section)

## Enum Best Practices

### ALWAYS Use Integer-Backed Enums

**Rails 8+ Modern Syntax** (Recommended):
```ruby
class Task < ApplicationRecord
  enum :status, [:pending, :in_progress, :completed, :failed, :cancelled]
  # Maps: pending=0, in_progress=1, completed=2, failed=3, cancelled=4
end
```

**Rails 7+ Hash Syntax** (Explicit Integers):
```ruby
class Task < ApplicationRecord
  enum status: {
    pending: 0,
    in_progress: 1,
    completed: 2,
    failed: 3,
    cancelled: 4
  }
end
```

**❌ NEVER Use String-Backed Enums:**
```ruby
# WRONG: Slower database queries (Rails docs quote)
class Task < ApplicationRecord
  enum status: {
    pending: 'pending',
    in_progress: 'in_progress'
  }
end
```

**Why Integer-Backed?**
- **Faster database queries** (Rails docs: string columns "will likely lead to slower database queries")
- Database efficiency (integer vs varchar storage)
- Better index performance
- Smaller storage footprint (4 bytes vs variable)
- Rails default and convention

### CRITICAL: Array Order Must Be Maintained

> "Once a value is added to the enum array, its position in the array must be maintained, and new values should only be added to the end of the array." - Rails API Docs

```ruby
# ✅ CORRECT: Adding new values at the end
enum :status, [:pending, :in_progress, :completed, :cancelled]  # v1
enum :status, [:pending, :in_progress, :completed, :cancelled, :failed]  # v2 - added at end

# ❌ WRONG: Inserting in middle breaks existing data
enum :status, [:pending, :in_progress, :failed, :completed, :cancelled]  # BREAKS v1 data!
```

### Enum Options

**Prefix** (avoid method name conflicts):
```ruby
enum :status, [:active, :archived], prefix: true
# Creates: active_status?, archived_status!, Task.active_status scope
```

**Suffix** (alternative disambiguation):
```ruby
enum :role, [:admin, :user], suffix: true
# Creates: admin_role?, user_role!, Task.admin_role scope
```

**Disable Auto-Generated Scopes:**
```ruby
enum :status, [:draft, :published], scopes: false
# Only creates predicate/bang methods, no Task.draft scope
```

**Validation** (deferred vs immediate):
```ruby
# Deferred validation (allows invalid assignment, fails at save)
enum :status, [:active, :inactive], validate: true

# Allow nil values
enum :status, [:active, :inactive], validate: { allow_nil: true }
```

**Default Value:**
```ruby
enum :status, [:active, :archived], default: :active
```

**Disable Instance Methods** (only generate scopes):
```ruby
enum :status, [:active, :archived], instance_methods: false
```

### Multiple Enums in Same Model

```ruby
class Conversation < ApplicationRecord
  enum :status, [:active, :archived]
  enum :role, [:owner, :member]

  # When value names overlap, use prefix/suffix:
  enum :payment_status, [:pending, :completed], prefix: :payment
  enum :shipping_status, [:pending, :completed], prefix: :shipping
  # Creates: payment_pending?, shipping_pending?, etc.
end
```

### Generated Methods

For `enum :status, [:active, :archived]`, Rails automatically creates:

**Bang Methods** (update and save!):
```ruby
conversation.active!    # Sets status to :active and saves
conversation.archived!  # Sets status to :archived and saves
```

**Predicate Methods** (query current state):
```ruby
conversation.active?    # Returns true if status == :active
conversation.archived?  # Returns true if status == :archived
```

**Scopes** (query collections):
```ruby
Conversation.active          # WHERE status = 0
Conversation.not_active      # WHERE status != 0
Conversation.archived        # WHERE status = 1
Conversation.not_archived    # WHERE status != 1
```

**Class Accessor** (hash mapping):
```ruby
Conversation.statuses
# => { "active" => 0, "archived" => 1 } (HashWithIndifferentAccess)
```

### Advanced: Direct SQL Access

For complex WHERE clauses, access integer values directly:

```ruby
# Access integer value for raw SQL
Conversation.where("status <> ?", Conversation.statuses[:archived])

# Or use the generated scope (preferred)
Conversation.not_archived
```

### Database Migration

**Always use integer columns for enums:**

```ruby
class AddStatusToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :status, :integer, default: 0, null: false
    add_index :tasks, :status  # Index for query performance
  end
end
```

## Association Options

**Dependency Management:**
```ruby
# Delete associated records when parent is destroyed
has_many :photos, dependent: :destroy

# Set foreign key to NULL when parent is destroyed
has_many :logs, dependent: :nullify

# Prevent deletion if associated records exist
has_many :exports, dependent: :restrict_with_error
```

**Optional Associations:**
```ruby
# Rails 5+ requires explicit optional: true for nullable belongs_to
belongs_to :carrier, optional: true
```

**Counter Cache:**
```ruby
# Maintain count of associated records
belongs_to :merchant, counter_cache: true
# Requires: add_column :merchants, :tasks_count, :integer, default: 0
```

**Touch Parent Timestamp:**
```ruby
# Update parent's updated_at when child changes
belongs_to :bundle, touch: true
```

## Validation Best Practices

**Validation Order** (presence before format/length):
```ruby
validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
```

**Optional Format Validations:**
```ruby
# Allow blank but validate format when present
validates :phone, format: { with: /\A\d{10}\z/ }, allow_blank: true
```

**Tenant-Scoped Uniqueness:**
```ruby
# Scope uniqueness to tenant/account
validates :tracking_number, uniqueness: { scope: :account_id }
```

## Anti-Patterns

**❌ NEVER:**
- Use string-backed enums (use integer-backed)
- Insert enum values in the middle of an array (breaks existing data)
- Put business logic in models (extract to Service Objects)
- Make direct external API calls from models (use Service Objects)
- Write complex callbacks (extract to Service Objects)
- Create fat models (>200 lines = refactor to Concerns or Services)
- Expose `@instance_variable` directly to views (use delegated methods)
- Use callbacks for complex side effects (use Service Objects with explicit orchestration)

**✅ INSTEAD:**
- Integer-backed enums for performance
- Append enum values to the end of arrays
- Service Objects for business logic
- Service Objects for external API calls
- Service Objects for complex orchestration
- Concerns for shared model behavior
- Public instance methods for view data
- Service layer for complex workflows

## Example Model Structure

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  # == Constants ============================================================
  STATUSES = %w[pending in_progress completed failed cancelled].freeze

  # == Enums ================================================================
  enum :status, [:pending, :in_progress, :completed, :failed, :cancelled], prefix: true

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
  validates :tracking_number, presence: true, uniqueness: { scope: :account_id }
  validates :status, presence: true

  # == Scopes ===============================================================
  scope :active, -> { where.not(status: %w[completed failed cancelled]) }
  scope :for_carrier, ->(carrier) { where(carrier: carrier) }
  scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }

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
    update!(completed_status: true, completed_at: Time.current)
  end

  # == Private Methods ======================================================
  private

  def generate_tracking_number
    self.tracking_number ||= SecureRandom.hex(8).upcase
  end

  def notify_recipient
    TaskNotificationJob.perform_later(id)
  end
end
```
