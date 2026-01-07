---
paths: "**/*.rb"
---

# Performance Best Practices

Apply to all Ruby files

## N+1 Query Prevention

```ruby
# ❌ BAD: N+1 queries (1 + N database queries)
@posts = Post.all
@posts.each do |post|
  puts post.author.name  # Separate query for each post!
end

# ✅ GOOD: Eager loading (2 queries total)
@posts = Post.includes(:author)
@posts.each do |post|
  puts post.author.name  # No additional queries
end

# ✅ BETTER: Preload with conditions
@posts = Post.includes(:author, :comments)
               .where(published: true)
```

**Use Bullet gem in development to detect N+1:**
```ruby
# Gemfile (development group)
gem 'bullet'

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
end
```

## Database Indexing

```ruby
# ✅ ALWAYS index foreign keys
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true, index: true
    end
  end
end

# ✅ Index frequently queried columns
add_index :posts, :published_at
add_index :posts, :status

# ✅ Composite indexes for multi-column queries
add_index :orders, [:user_id, :status]
```

## Caching Strategies

**Fragment caching:**
```erb
<%# app/views/posts/index.html.erb %>
<% @posts.each do |post| %>
  <% cache post do %>
    <%= render post %>
  <% end %>
<% end %>
```

**Russian doll caching:**
```erb
<%# Outer cache %>
<% cache @post do %>
  <h1><%= @post.title %></h1>

  <%# Inner cache %>
  <% cache [@post, @post.author] do %>
    <p>By <%= @post.author.name %></p>
  <% end %>
<% end %>
```

**Low-level caching:**
```ruby
def expensive_computation
  Rails.cache.fetch("expensive_#{id}", expires_in: 12.hours) do
    # Expensive calculation here
    compute_result
  end
end
```

## Background Jobs

```ruby
# ❌ BAD: Slow operations in request cycle
def create
  @order = Order.create(order_params)
  @order.send_confirmation_email  # Blocks for 2-3 seconds!
  @order.generate_invoice_pdf     # Blocks for 5 seconds!
end

# ✅ GOOD: Move to background jobs
def create
  @order = Order.create(order_params)
  OrderConfirmationJob.perform_later(@order.id)
  GenerateInvoiceJob.perform_later(@order.id)
end
```

## Select Only Needed Columns

```ruby
# ❌ BAD: Loads all columns
User.all.pluck(:id)  # Loads entire user objects first!

# ✅ GOOD: Select only what you need
User.select(:id, :name).where(active: true)
```

## Batch Processing

```ruby
# ❌ BAD: Loads all records into memory
User.all.each do |user|
  user.send_notification
end

# ✅ GOOD: Process in batches
User.find_each(batch_size: 1000) do |user|
  user.send_notification
end
```
