---
paths: db/migrate/**/*.rb
---

# Migration Best Practices

Apply to all files in `db/migrate/**/*.rb`

## Always Reversible

```ruby
# ✅ CORRECT: Reversible with change
class AddPublishedAtToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :published_at, :datetime
    add_index :posts, :published_at
  end
end

# ✅ CORRECT: Explicit up/down
class RemoveDeprecatedColumn < ActiveRecord::Migration[7.1]
  def up
    remove_column :posts, :deprecated_field
  end

  def down
    add_column :posts, :deprecated_field, :string
  end
end
```

## Never Edit Existing Migrations

Once a migration runs in production, NEVER edit it. Create a new migration to fix mistakes.

## Add Indexes

**Always index foreign keys and frequently queried columns:**

```ruby
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false
      t.timestamps
    end

    add_index :orders, :status  # Frequently filtered
    add_index :orders, :created_at  # Sorted by date
  end
end
```

## Concurrent Indexes (PostgreSQL)

**Use `algorithm: :concurrently` for large tables:**

```ruby
class AddIndexToLargeTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!  # Required for concurrent indexes

  def change
    add_index :posts, :user_id, algorithm: :concurrently
  end
end
```

## Data Migrations

**Separate data changes from schema changes:**

```ruby
class BackfillDefaultRole < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        User.where(role: nil).update_all(role: 'member')
      end

      dir.down do
        # Optional: reverse data change
        User.where(role: 'member').update_all(role: nil)
      end
    end
  end
end
```

## Anti-Patterns

**❌ NEVER:**
- Edit migrations after they run in production
- Create migrations without indexes on foreign keys
- Mix schema and data changes in one migration
- Use `up`/`down` when `change` would work

**✅ INSTEAD:**
- Create new migrations to fix issues
- Always index foreign keys
- Separate schema and data migrations
- Prefer `change` for auto-reversibility
