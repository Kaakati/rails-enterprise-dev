---
name: "ViewComponents Specialist"
description: "Expert patterns for ViewComponent implementation, slots, previews, and method exposure. Use when: (1) Creating ViewComponents, (2) Implementing slots or content blocks, (3) Setting up component previews, (4) Debugging template/rendering errors, (5) Exposing service methods to views. Trigger keywords: ViewComponent, components, UI, rendering, slots, previews, partials, presenters, render_inline, erb"
version: 1.1.0
---

# ViewComponents Specialist

Expert patterns for building ViewComponents in Rails applications.

## Critical Rule: Method Exposure

```
Service has method + Component EXPOSES it = View can call it
```

Views cannot reach through components to access service internals. Every method a view calls must be public on the component.

## Pre-Work Protocol (MANDATORY)

Before ANY component work:
```bash
# 1. Determine template pattern
head -50 $(find app/components -name '*_component.rb' | head -1) 2>/dev/null
grep -l 'def call' app/components/**/*_component.rb 2>/dev/null | head -3

# 2. Check helper usage pattern
grep -r 'helpers\.' app/components/ --include='*.rb' | head -3

# 3. Check delegation patterns
grep -r 'delegate' app/components/ --include='*.rb' | head -3
```

## Component Creation Decision Tree

```
What type of component?
│
├─ Simple display (badge, icon)
│   └─ Basic Component pattern
│
├─ Wraps a service/data object
│   └─ Service Wrapper pattern
│
├─ Has customizable sections
│   └─ Slots pattern
│
└─ Very simple, no template file needed
    └─ Inline Template pattern
```

---

## Pattern 1: Basic Component

```ruby
# app/components/ui/badge_component.rb
class Ui::BadgeComponent < ViewComponent::Base
  def initialize(text:, color: :gray)
    @text = text
    @color = color
  end

  # Private methods for internal logic
  private

  def color_classes
    { gray: "bg-gray-100 text-gray-800",
      green: "bg-green-100 text-green-800",
      red: "bg-red-100 text-red-800" }[@color]
  end
end
```

```erb
<%# app/components/ui/badge_component.html.erb %>
<span class="px-2 py-1 text-xs font-medium rounded-full <%= color_classes %>">
  <%= @text %>
</span>
```

---

## Pattern 2: Service Wrapper

**Use when component wraps a service object and needs to expose its data.**

```ruby
class Dashboard::MetricsComponent < ViewComponent::Base
  # EXPOSE all methods view needs (critical!)
  delegate :total_tasks, :completed_tasks, :pending_tasks, to: :@service

  def initialize(service:)
    @service = service
  end

  # Add formatted versions as wrappers
  def formatted_success_rate
    "#{(@service.success_rate * 100).round(1)}%"
  end

  def formatted_currency(amount)
    helpers.number_to_currency(amount)
  end
end
```

**Verification before writing view:**
```bash
# List methods view will call
grep -oE '@component\.[a-z_]+' app/views/dashboard/*.erb | sort -u

# List public methods in component
grep -E '^\s+def [a-z_]+' app/components/dashboard/metrics_component.rb

# Any mismatch = BUG
```

---

## Pattern 3: Slots

```ruby
class Card::Component < ViewComponent::Base
  renders_one :header    # Single slot
  renders_one :footer
  renders_many :actions  # Multiple slots

  def initialize(title: nil, collapsible: false)
    @title = title
    @collapsible = collapsible
  end
end
```

```erb
<%# app/components/card/component.html.erb %>
<div class="bg-white rounded-lg shadow">
  <% if header? || @title %>
    <div class="px-4 py-3 border-b">
      <%= header? ? header : content_tag(:h3, @title, class: "text-lg font-medium") %>
    </div>
  <% end %>

  <div class="p-4">
    <%= content %>
  </div>

  <% if footer? || actions? %>
    <div class="px-4 py-3 border-t flex justify-end space-x-2">
      <%= footer? ? footer : safe_join(actions) %>
    </div>
  <% end %>
</div>
```

**Usage:**
```erb
<%= render Card::Component.new(title: "Stats") do |card| %>
  <% card.with_header do %>Custom Header<% end %>
  <% card.with_action do %>
    <%= helpers.link_to "Edit", edit_path %>
  <% end %>
  Body content here
<% end %>
```

---

## Pattern 4: Inline Template

**Use for simple components that don't need a separate template file.**

```ruby
class Ui::IconComponent < ViewComponent::Base
  def initialize(name:, size: :md)
    @name = name
    @size = size
  end

  def call
    helpers.content_tag :svg, class: svg_classes do
      helpers.content_tag :use, nil, href: "#icon-#{@name}"
    end
  end

  private

  def svg_classes
    size_class = { sm: "w-4 h-4", md: "w-5 h-5", lg: "w-6 h-6" }[@size]
    "inline-block #{size_class}"
  end
end
```

---

## Helper Access Rules

**ALWAYS use `helpers.` prefix or delegate:**

```ruby
# WRONG - raises undefined method
def user_link
  link_to(@user.name, user_path(@user))
end

# RIGHT - helpers prefix
def user_link
  helpers.link_to(@user.name, helpers.user_path(@user))
end

# BETTER - delegate for frequently used
class MyComponent < ViewComponent::Base
  delegate :link_to, :image_tag, :number_to_currency, :dom_id, to: :helpers
end
```

**Common helpers needing prefix:**
- Navigation: `link_to`, `button_to`, `url_for`, `*_path`
- Assets: `image_tag`, `asset_path`
- Formatting: `number_to_currency`, `time_ago_in_words`, `truncate`
- HTML: `content_tag`, `tag`, `safe_join`, `dom_id`

---

## NEVER Do This

**NEVER** assume service methods are accessible from view:
```erb
<%# WRONG - view reaches through component %>
<%= @dashboard.service.calculate_total %>

<%# RIGHT - component exposes method %>
<%= @dashboard.total %>
```

**NEVER** create component without template (unless using `def call`):
```ruby
# This will error with "template not found"
class MyComponent < ViewComponent::Base
  def initialize(data:)
    @data = data
  end
  # Missing: template file OR def call
end
```

**NEVER** use Rails helpers without `helpers.` prefix:
```ruby
# WRONG
link_to("Click", path)  # undefined method

# RIGHT
helpers.link_to("Click", path)
```

---

## Testing Components

```ruby
RSpec.describe Dashboard::MetricsComponent, type: :component do
  let(:service) { instance_double(MetricsService) }

  before do
    allow(service).to receive(:total_tasks).and_return(100)
    allow(service).to receive(:success_rate).and_return(0.85)
  end

  it "renders total tasks" do
    render_inline(described_class.new(service: service))
    expect(page).to have_text("100")
  end

  it "formats success rate" do
    component = described_class.new(service: service)
    expect(component.formatted_success_rate).to eq("85.0%")
  end
end
```

---

## Pre-Creation Checklist

```
[ ] Checked existing component patterns in codebase
[ ] Determined template style (file vs inline def call)
[ ] Listed ALL methods view will need
[ ] All needed methods are PUBLIC on component
[ ] Service methods exposed via delegate or wrappers
[ ] All Rails helpers use helpers. prefix or are delegated
```

## Handoff Template

When completing component work:
```
## Component: Namespace::NameComponent
- File: app/components/namespace/name_component.rb
- Template: app/components/namespace/name_component.html.erb

### Public Methods (callable from view)
- method_name → ReturnType
- other_method(param) → ReturnType

### Usage
<%= render Namespace::NameComponent.new(service: @service) %>

### Verified
- [ ] Template renders
- [ ] All view-needed methods exposed
- [ ] helpers. prefix used correctly
```
