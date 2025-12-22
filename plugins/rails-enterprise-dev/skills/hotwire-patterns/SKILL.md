---
name: "Turbo & Hotwire Patterns"
description: "Complete guide to Hotwire implementation including Turbo Drive, Turbo Frames, Turbo Streams, and Stimulus controllers in Rails applications. Use this skill when implementing real-time updates, partial page rendering, or JavaScript behaviors in Rails views."
---

# Turbo & Hotwire Patterns Skill

This skill provides comprehensive guidance for implementing Hotwire (Turbo + Stimulus) in Ruby on Rails applications.

## When to Use This Skill

- Implementing partial page updates
- Adding real-time features
- Creating Turbo Frames and Streams
- Writing Stimulus controllers
- Debugging Turbo-related issues

## External References

- **Turbo**: https://turbo.hotwired.dev/
- **Stimulus**: https://stimulus.hotwired.dev/

## Hotwire Stack Overview

```
Hotwire
├── Turbo
│   ├── Turbo Drive      — Full page navigation without reload
│   ├── Turbo Frames     — Partial page updates
│   └── Turbo Streams    — Real-time updates over WebSocket/HTTP
│
└── Stimulus             — Lightweight JavaScript controllers
```

## Turbo Drive

Automatically converts all link clicks and form submissions into AJAX requests.

### Disabling for Specific Links
```erb
<%# Skip Turbo Drive for this link %>
<%= link_to "External", "https://example.com", data: { turbo: false } %>

<%# Skip for form %>
<%= form_with model: @user, data: { turbo: false } do |f| %>
```

### Progress Bar
```css
/* Customize Turbo progress bar */
.turbo-progress-bar {
  background-color: #4f46e5;
  height: 3px;
}
```

## Turbo Frames

Partial page updates within a frame boundary.

### Basic Frame

```erb
<%# app/views/tasks/index.html.erb %>
<%= turbo_frame_tag "tasks_list" do %>
  <% @tasks.each do |task| %>
    <%= render task %>
  <% end %>
  
  <%= link_to "Load more", tasks_path(page: @next_page) %>
<% end %>
```

### Frame Navigation

```erb
<%# Links within frame navigate inside frame %>
<%= turbo_frame_tag dom_id(@task) do %>
  <h3><%= @task.title %></h3>
  <%= link_to "Edit", edit_task_path(@task) %>
<% end %>

<%# Edit form replaces frame content %>
<%# app/views/tasks/edit.html.erb %>
<%= turbo_frame_tag dom_id(@task) do %>
  <%= render "form", task: @task %>
<% end %>
```

### Breaking Out of Frame

```erb
<%# Target another frame %>
<%= link_to "Details", task_path(@task), data: { turbo_frame: "task_detail" } %>

<%# Target the whole page %>
<%= link_to "Full Page", task_path(@task), data: { turbo_frame: "_top" } %>
```

### Lazy Loading Frames

```erb
<%# Load content when frame becomes visible %>
<%= turbo_frame_tag "comments", 
                    src: task_comments_path(@task), 
                    loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>
```

### Frame with Different Source

```erb
<%# Frame that loads from different URL %>
<%= turbo_frame_tag "sidebar",
                    src: sidebar_path,
                    target: "_top" do %>
  <p>Loading sidebar...</p>
<% end %>
```

## Turbo Streams

Real-time DOM updates via WebSocket or HTTP responses.

### Stream Actions

```erb
<%# Append to container %>
<%= turbo_stream.append "tasks" do %>
  <%= render @task %>
<% end %>

<%# Prepend to container %>
<%= turbo_stream.prepend "tasks" do %>
  <%= render @task %>
<% end %>

<%# Replace specific element %>
<%= turbo_stream.replace dom_id(@task) do %>
  <%= render @task %>
<% end %>

<%# Update contents (not replace element) %>
<%= turbo_stream.update "task_count" do %>
  <%= @tasks.count %>
<% end %>

<%# Remove element %>
<%= turbo_stream.remove dom_id(@task) %>

<%# Before/After %>
<%= turbo_stream.before dom_id(@task) do %>
  <div class="alert">Task updated!</div>
<% end %>

<%= turbo_stream.after dom_id(@task) do %>
  <div class="related">Related tasks...</div>
<% end %>
```

### Stream Response from Controller

```ruby
# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  def create
    @task = current_account.tasks.build(task_params)
    
    respond_to do |format|
      if @task.save
        format.turbo_stream  # Renders create.turbo_stream.erb
        format.html { redirect_to @task }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "task_form",
            partial: "form",
            locals: { task: @task }
          )
        end
        format.html { render :new }
      end
    end
  end
  
  def destroy
    @task = current_account.tasks.find(params[:id])
    @task.destroy
    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@task)) }
      format.html { redirect_to tasks_path }
    end
  end
end
```

```erb
<%# app/views/tasks/create.turbo_stream.erb %>
<%= turbo_stream.prepend "tasks" do %>
  <%= render @task %>
<% end %>

<%= turbo_stream.replace "task_form" do %>
  <%= render "form", task: Task.new %>
<% end %>

<%= turbo_stream.update "tasks_count" do %>
  <%= current_account.tasks.count %>
<% end %>
```

### Broadcast Streams (Real-time)

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  after_create_commit -> { broadcast_prepend_to "tasks" }
  after_update_commit -> { broadcast_replace_to "tasks" }
  after_destroy_commit -> { broadcast_remove_to "tasks" }
  
  # Or with custom stream name
  after_create_commit -> { 
    broadcast_prepend_to [account, "tasks"],
                         target: "tasks_list",
                         partial: "tasks/task"
  }
end
```

```erb
<%# Subscribe to stream in view %>
<%= turbo_stream_from @account, "tasks" %>

<div id="tasks_list">
  <%= render @tasks %>
</div>
```

## Stimulus Controllers

Lightweight JavaScript behaviors.

### Basic Controller

```javascript
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Hello controller connected!")
  }
  
  greet() {
    alert("Hello, Stimulus!")
  }
}
```

```erb
<div data-controller="hello">
  <button data-action="click->hello#greet">Greet</button>
</div>
```

### Targets

```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "count"]
  
  search() {
    const query = this.inputTarget.value
    
    fetch(`/search?q=${query}`)
      .then(response => response.text())
      .then(html => {
        this.resultsTarget.innerHTML = html
      })
  }
  
  clear() {
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }
  
  // Check if target exists
  updateCount() {
    if (this.hasCountTarget) {
      this.countTarget.textContent = this.resultsTarget.children.length
    }
  }
}
```

```erb
<div data-controller="search">
  <input data-search-target="input" 
         data-action="input->search#search">
  
  <button data-action="click->search#clear">Clear</button>
  
  <span data-search-target="count"></span>
  
  <div data-search-target="results"></div>
</div>
```

### Values

```javascript
// app/javascript/controllers/countdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    seconds: { type: Number, default: 60 },
    url: String,
    autoStart: { type: Boolean, default: false }
  }
  
  connect() {
    if (this.autoStartValue) {
      this.start()
    }
  }
  
  start() {
    this.remaining = this.secondsValue
    this.timer = setInterval(() => this.tick(), 1000)
  }
  
  tick() {
    if (this.remaining > 0) {
      this.remaining--
      this.element.textContent = this.remaining
    } else {
      this.finish()
    }
  }
  
  finish() {
    clearInterval(this.timer)
    if (this.hasUrlValue) {
      window.location.href = this.urlValue
    }
  }
  
  // Called when value changes
  secondsValueChanged() {
    this.remaining = this.secondsValue
  }
  
  disconnect() {
    clearInterval(this.timer)
  }
}
```

```erb
<div data-controller="countdown"
     data-countdown-seconds-value="30"
     data-countdown-url-value="/timeout"
     data-countdown-auto-start-value="true">
  30
</div>
```

### Actions

```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]
  
  // Default action (no method specified)
  submit(event) {
    event.preventDefault()
    this.submitTarget.disabled = true
    // ... form submission logic
  }
  
  // With event options
  // data-action="keydown.enter->form#submit"
  // data-action="click->form#submit:prevent"
}
```

```erb
<form data-controller="form"
      data-action="submit->form#submit">
  
  <input data-action="keydown.enter->form#submit:prevent">
  
  <button data-form-target="submit"
          data-action="click->form#validate">
    Submit
  </button>
</form>
```

### Classes

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = ["open", "closed"]
  static targets = ["menu"]
  
  toggle() {
    if (this.menuTarget.classList.contains(this.openClass)) {
      this.close()
    } else {
      this.open()
    }
  }
  
  open() {
    this.menuTarget.classList.remove(this.closedClass)
    this.menuTarget.classList.add(this.openClass)
  }
  
  close() {
    this.menuTarget.classList.remove(this.openClass)
    this.menuTarget.classList.add(this.closedClass)
  }
}
```

```erb
<div data-controller="dropdown"
     data-dropdown-open-class="block"
     data-dropdown-closed-class="hidden">
  
  <button data-action="click->dropdown#toggle">Menu</button>
  
  <div data-dropdown-target="menu" class="hidden">
    Menu content
  </div>
</div>
```

### Outlets (Controller Communication)

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["form"]
  
  open() {
    this.element.classList.add("open")
    
    // Call method on connected form controller
    if (this.hasFormOutlet) {
      this.formOutlet.reset()
    }
  }
  
  close() {
    this.element.classList.remove("open")
  }
}
```

```erb
<div data-controller="modal"
     data-modal-form-outlet="#task-form">
  
  <div id="task-form" data-controller="form">
    <!-- form content -->
  </div>
</div>
```

## Common Patterns

### Infinite Scroll

```erb
<%# View %>
<div data-controller="infinite-scroll"
     data-infinite-scroll-url-value="<%= tasks_path %>"
     data-infinite-scroll-page-value="1">
  
  <div id="tasks" data-infinite-scroll-target="container">
    <%= render @tasks %>
  </div>
  
  <div data-infinite-scroll-target="loading" class="hidden">
    Loading...
  </div>
</div>
```

```javascript
// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "loading"]
  static values = { url: String, page: Number }
  
  connect() {
    this.observer = new IntersectionObserver(
      entries => this.handleIntersect(entries),
      { threshold: 0.1 }
    )
    this.observer.observe(this.loadingTarget)
  }
  
  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.loadMore()
      }
    })
  }
  
  async loadMore() {
    this.loadingTarget.classList.remove("hidden")
    
    const response = await fetch(
      `${this.urlValue}?page=${this.pageValue + 1}`,
      { headers: { "Accept": "text/vnd.turbo-stream.html" } }
    )
    
    if (response.ok) {
      this.pageValue++
      const html = await response.text()
      Turbo.renderStreamMessage(html)
    }
    
    this.loadingTarget.classList.add("hidden")
  }
  
  disconnect() {
    this.observer.disconnect()
  }
}
```

### Auto-Submit Form

```erb
<%= form_with url: search_path, 
              method: :get,
              data: { 
                controller: "auto-submit",
                turbo_frame: "results"
              } do |f| %>
  
  <%= f.text_field :q, 
                   data: { 
                     action: "input->auto-submit#submit",
                     auto_submit_target: "input"
                   } %>
<% end %>

<%= turbo_frame_tag "results" do %>
  <%= render @results %>
<% end %>
```

```javascript
// app/javascript/controllers/auto_submit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
}
```

### Flash Messages with Turbo

```erb
<%# app/views/layouts/_flash.html.erb %>
<div id="flash">
  <% flash.each do |type, message| %>
    <div class="flash flash-<%= type %>"
         data-controller="flash"
         data-flash-timeout-value="5000">
      <%= message %>
      <button data-action="click->flash#dismiss">×</button>
    </div>
  <% end %>
</div>
```

```javascript
// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 5000 } }
  
  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
  }
  
  dismiss() {
    this.element.remove()
  }
  
  disconnect() {
    clearTimeout(this.timer)
  }
}
```

## Debugging

### Turbo Events

```javascript
// Listen to Turbo events for debugging
document.addEventListener("turbo:before-fetch-request", (event) => {
  console.log("Turbo request:", event.detail.url)
})

document.addEventListener("turbo:frame-missing", (event) => {
  console.log("Frame missing:", event.target.id)
})
```

### Common Issues

1. **Frame not updating**: Check frame IDs match between source and target
2. **Streams not working**: Verify `turbo_stream_from` subscription
3. **Actions not firing**: Check data-action syntax and controller registration
