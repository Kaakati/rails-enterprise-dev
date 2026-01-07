---
paths: app/components/**/*.rb
---

# ViewComponent Patterns

Apply to all files in `app/components/**/*.rb`

## Naming Convention

**Always end with `Component`:**
```ruby
# ✅ CORRECT
TaskCardComponent
UserAvatarComponent
ModalComponent

# ❌ WRONG
TaskCard  # Missing "Component" suffix
Task  # Too generic
```

## Critical: Method Exposure

**ALWAYS use `delegate` to expose service methods to templates:**

```ruby
# ✅ CORRECT: Delegate to service
class TaskCardComponent < ViewComponent::Base
  delegate :task_id, :title, :status, :due_date, :assignee_name, to: :@service

  def initialize(service:)
    @service = service
  end
end

# ❌ WRONG: Expose service directly
class TaskCardComponent < ViewComponent::Base
  attr_reader :service  # WRONG: Template can call @service.internal_method

  def initialize(service:)
    @service = service
  end
end
```

**Why delegation is required:**
- Prevents template access to internal service methods
- Explicit API contract
- Type safety (Sorbet can validate)
- Prevents accidental exposure of sensitive methods

## Template Requirements

**Every component MUST have a template file:**

```ruby
# app/components/task_card_component.rb
class TaskCardComponent < ViewComponent::Base
  delegate :title, :status, to: :@service

  def initialize(service:)
    @service = service
  end
end
```

```erb
<%# app/components/task_card_component.html.erb %>
<div class="card">
  <h3><%= title %></h3>
  <span class="badge"><%= status %></span>
</div>
```

## Slots Pattern

**Use slots for flexible component composition:**

```ruby
class ModalComponent < ViewComponent::Base
  renders_one :header
  renders_one :body
  renders_one :footer

  def initialize(size: :medium)
    @size = size
  end
end
```

```erb
<%# app/components/modal_component.html.erb %>
<div class="modal modal-<%= @size %>">
  <div class="modal-header">
    <%= header %>
  </div>
  <div class="modal-body">
    <%= body %>
  </div>
  <div class="modal-footer">
    <%= footer %>
  end>
</div>
```

```erb
<%# Usage in view %>
<%= render ModalComponent.new(size: :large) do |modal| %>
  <% modal.with_header do %>
    <h2>Confirm Delete</h2>
  <% end %>

  <% modal.with_body do %>
    <p>Are you sure?</p>
  <% end %>

  <% modal.with_footer do %>
    <%= button_tag "Cancel" %>
    <%= button_tag "Delete", class: "btn-danger" %>
  <% end %>
<% end %>
```

## TailAdmin CSS Classes

**Use TailAdmin design system classes:**

```erb
<%# Card component %>
<div class="rounded-sm border border-stroke bg-white shadow-default dark:border-strokedark dark:bg-boxdark">
  <div class="border-b border-stroke px-7 py-4 dark:border-strokedark">
    <h3 class="font-medium text-black dark:text-white"><%= title %></h3>
  </div>
  <div class="p-7">
    <%= content %>
  </div>
</div>
```

## Component Previews

**Always create previews for development:**

```ruby
# spec/components/previews/task_card_component_preview.rb
class TaskCardComponentPreview < ViewComponent::Preview
  def default
    service = TaskCardService.new(
      task_id: 1,
      title: "Complete project",
      status: "in_progress"
    )

    render TaskCardComponent.new(service: service)
  end

  def completed
    service = TaskCardService.new(
      task_id: 2,
      title: "Review PR",
      status: "completed"
    )

    render TaskCardComponent.new(service: service)
  end
end
```

## Testing Components

```ruby
# spec/components/task_card_component_spec.rb
RSpec.describe TaskCardComponent, type: :component do
  let(:service) do
    instance_double(
      TaskCardService,
      title: "Test Task",
      status: "pending"
    )
  end

  it "renders title" do
    render_inline(described_class.new(service: service))

    expect(page).to have_text("Test Task")
  end

  it "renders status badge" do
    render_inline(described_class.new(service: service))

    expect(page).to have_css(".badge", text: "pending")
  end
end
```

## Anti-Patterns

**❌ NEVER:**
- Expose `@service` directly to templates
- Create components without template files
- Put logic in templates (move to component class)
- Use inline styles (use TailAdmin classes)
- Skip component previews

**✅ INSTEAD:**
- Delegate methods explicitly
- Always create template file
- Put logic in component class
- Use Tailwind/TailAdmin classes
- Create previews for all components
