# Performance Debt Reference

Comprehensive guide to detecting and addressing performance issues in Rails applications.

## N+1 Query Detection

### Understanding N+1

An N+1 query occurs when code executes 1 query to fetch a list, then N additional queries to fetch associated records.

```ruby
# N+1 Problem: 1 + N queries
users = User.all  # 1 query
users.each do |user|
  puts user.posts.count  # N queries (one per user)
end
```

### Detection Tools

**Bullet Gem**:
```ruby
# Gemfile
group :development do
  gem 'bullet'
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
end
```

**Manual Detection**:
```bash
# Search for potential N+1 patterns
grep -rn "\.each.*\." app/controllers/ app/views/

# Check logs for repeated queries
grep "SELECT" log/development.log | sort | uniq -c | sort -rn | head -20
```

**Prosopite Gem** (alternative to Bullet):
```ruby
# Gemfile
gem 'prosopite'

# config/environments/development.rb
config.after_initialize do
  Prosopite.rails_logger = true
  Prosopite.raise = true  # Raise on N+1 in tests
end
```

### Common N+1 Patterns

**In Controllers**:
```ruby
# BAD - N+1 when rendering
def index
  @posts = Post.all  # Missing includes
end

# GOOD
def index
  @posts = Post.includes(:author, :comments).all
end
```

**In Views**:
```erb
<%# BAD - N+1 in view %>
<% @posts.each do |post| %>
  <%= post.author.name %>
  <%= post.comments.count %>
<% end %>

<%# GOOD - ensure includes in controller %>
<%# @posts = Post.includes(:author, :comments) %>
```

**With Counter Caches**:
```ruby
# BAD - N queries for counts
@users.each { |u| puts u.posts.count }

# GOOD - Counter cache
# Migration:
add_column :users, :posts_count, :integer, default: 0
User.reset_counters(user.id, :posts)

# Model:
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Usage - No query!
@users.each { |u| puts u.posts_count }
```

### Eager Loading Strategies

| Method | Use Case | SQL Generated |
|--------|----------|---------------|
| `includes` | General use, let Rails decide | LEFT OUTER JOIN or separate queries |
| `preload` | Force separate queries | Always separate queries |
| `eager_load` | Force single query with JOIN | LEFT OUTER JOIN |
| `joins` | Filter by association, don't load data | INNER JOIN |

```ruby
# includes - Rails chooses strategy
Post.includes(:comments).where(published: true)

# preload - Always 2 queries
Post.preload(:comments).where(published: true)

# eager_load - Always JOIN
Post.eager_load(:comments).where(comments: { approved: true })

# joins - For filtering only (doesn't load association)
Post.joins(:comments).where(comments: { approved: true })
```

---

## Missing Database Indexes

### Detection

```bash
# Using lol_dba gem
gem install lol_dba
lol_dba db:find_indexes

# Using rails-pg-extras (PostgreSQL)
rails pg_extras:index_usage

# Manual: Find foreign keys without indexes
grep -rn "belongs_to\|references" app/models/ db/migrate/
# Then check db/schema.rb for corresponding indexes
```

### Common Missing Indexes

| Pattern | Index Needed |
|---------|--------------|
| `belongs_to :user` | `add_index :table, :user_id` |
| `where(status: ...)` | `add_index :table, :status` |
| `order(:created_at)` | `add_index :table, :created_at` |
| `where(a: x, b: y)` | `add_index :table, [:a, :b]` |
| Polymorphic | `add_index :table, [:commentable_type, :commentable_id]` |

### Index Analysis

```ruby
# Check index usage (PostgreSQL)
ActiveRecord::Base.connection.execute(<<-SQL)
  SELECT
    relname as table,
    indexrelname as index,
    idx_scan as scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
  FROM pg_stat_user_indexes
  ORDER BY idx_scan ASC
  LIMIT 20;
SQL

# Find unused indexes
ActiveRecord::Base.connection.execute(<<-SQL)
  SELECT indexrelid::regclass as index, relid::regclass as table
  FROM pg_stat_user_indexes
  WHERE idx_scan = 0
    AND indexrelid::regclass::text NOT LIKE '%_pkey';
SQL
```

### Index Creation Guidelines

```ruby
# Basic index
add_index :orders, :user_id

# Composite index (order matters!)
add_index :orders, [:user_id, :status]  # Good for: WHERE user_id = ? AND status = ?

# Partial index (PostgreSQL)
add_index :orders, :user_id, where: "status = 'pending'"

# Unique index
add_index :users, :email, unique: true

# Concurrent index (no lock, PostgreSQL)
add_index :orders, :user_id, algorithm: :concurrently
```

---

## Slow Queries

### Detection

**Rails Logs**:
```ruby
# config/environments/development.rb
config.active_record.verbose_query_logs = true

# Log queries over threshold
ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  if event.duration > 100  # milliseconds
    Rails.logger.warn "SLOW QUERY (#{event.duration.round}ms): #{event.payload[:sql]}"
  end
end
```

**Query Analysis**:
```ruby
# Explain a query
User.where(active: true).explain

# Explain with analyze (PostgreSQL)
User.where(active: true).explain(:analyze)

# In rails console
ActiveRecord::Base.connection.execute("EXPLAIN ANALYZE SELECT * FROM users WHERE active = true")
```

### Common Slow Query Patterns

**Full Table Scans**:
```ruby
# SLOW - No index on status
Order.where(status: 'pending')

# FIX - Add index
add_index :orders, :status
```

**LIKE with Leading Wildcard**:
```ruby
# SLOW - Can't use index
User.where("name LIKE ?", "%smith%")

# FASTER - Full-text search
# PostgreSQL:
User.where("to_tsvector('english', name) @@ to_tsquery('english', ?)", "smith")
```

**Large IN Clauses**:
```ruby
# SLOW - Large array
User.where(id: large_array_of_ids)

# FASTER - Use joins or subqueries
User.where(id: Order.select(:user_id).where(status: 'pending'))
```

**SELECT ***:
```ruby
# SLOW - Fetches all columns
users = User.all

# FASTER - Select only needed columns
users = User.select(:id, :name, :email)

# Or use pluck for simple arrays
user_ids = User.where(active: true).pluck(:id)
```

---

## Memory Bloat

### Detection

```ruby
# Memory monitoring
require 'get_process_mem'

def log_memory(label)
  mem = GetProcessMem.new
  Rails.logger.info "MEMORY [#{label}]: #{mem.mb.round(2)} MB"
end

log_memory("before")
# ... operation ...
log_memory("after")
```

### Common Memory Issues

**Loading Too Many Records**:
```ruby
# BAD - Loads all records into memory
User.all.each { |u| process(u) }

# GOOD - Batch processing
User.find_each(batch_size: 1000) { |u| process(u) }

# GOOD - Streaming for exports
User.find_each.lazy.map { |u| u.to_csv }
```

**Unbounded Queries**:
```ruby
# BAD - Could return millions
logs = AuditLog.where(created_at: 1.year.ago..)

# GOOD - Paginate or limit
logs = AuditLog.where(created_at: 1.year.ago..).limit(1000)
```

**String Concatenation in Loops**:
```ruby
# BAD - Creates many intermediate strings
result = ""
items.each { |i| result += i.to_s }

# GOOD - Use array join
result = items.map(&:to_s).join
```

**Leaking Objects in Background Jobs**:
```ruby
# BAD - Instance variable persists
class MyJob
  def perform
    @data ||= expensive_load  # Persists across job runs
  end
end

# GOOD - Local variables
class MyJob
  def perform
    data = expensive_load
    # ...
  end
end
```

---

## Caching Opportunities

### Detection

Look for:
- Repeated expensive queries
- Computed values that don't change often
- External API calls

```bash
# Find repeated queries in logs
grep "SELECT" log/development.log | sort | uniq -c | sort -rn | head -10
```

### Caching Strategies

**Low-Level Caching**:
```ruby
# Cache expensive computation
def expensive_stats
  Rails.cache.fetch("user_#{id}_stats", expires_in: 1.hour) do
    calculate_expensive_stats
  end
end
```

**Fragment Caching**:
```erb
<%# Cache view fragments %>
<% cache @product do %>
  <%= render @product %>
<% end %>

<%# With explicit key %>
<% cache [:product_card, @product, current_user.locale] do %>
  <%= render @product %>
<% end %>
```

**Russian Doll Caching**:
```erb
<% cache @category do %>
  <h1><%= @category.name %></h1>
  <% @category.products.each do |product| %>
    <% cache product do %>
      <%= render product %>
    <% end %>
  <% end %>
<% end %>
```

**Query Caching**:
```ruby
# Automatic within request
# But can manually cache across requests:
def cached_active_users
  Rails.cache.fetch("active_users", expires_in: 5.minutes) do
    User.where(active: true).pluck(:id)
  end
end
```

---

## Severity Scoring

| Issue Type | Impact | Typical Severity |
|------------|--------|------------------|
| N+1 in hot path | High latency | High |
| N+1 in admin only | Low user impact | Medium |
| Missing index on FK | Slow joins | High |
| Missing index on rarely queried | Minimal impact | Low |
| Full table scan | Very slow | Critical |
| Memory bloat in job | OOM crashes | Critical |
| No caching | Wasted resources | Medium |

### SLA by Severity

| Severity | SLA | Example |
|----------|-----|---------|
| Critical | 1 sprint | OOM in production job |
| High | 2 sprints | N+1 on main page |
| Medium | Quarterly | Missing cache for reports |
| Low | Opportunistic | Unused index cleanup |

---

## CI Integration

```yaml
# .github/workflows/performance.yml
name: Performance Checks

on: [push, pull_request]

jobs:
  n_plus_one:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Setup DB
        run: bundle exec rails db:setup

      - name: Run tests with Bullet
        env:
          BULLET_ENABLED: true
          BULLET_RAISE: true
        run: bundle exec rspec

  query_analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1

      - name: Check for missing indexes
        run: |
          gem install lol_dba
          lol_dba db:find_indexes 2>&1 | tee index_report.txt

          if grep -q "Missing" index_report.txt; then
            echo "::warning::Missing indexes detected"
            cat index_report.txt
          fi
```
