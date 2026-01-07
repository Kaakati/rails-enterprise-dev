---
paths: "app/javascript/**/*_controller.js"
---

# Stimulus Controller Patterns

Apply to all files matching `app/javascript/**/*_controller.js`

## Naming Convention

**File and class naming:**
```javascript
// File: app/javascript/controllers/dropdown_controller.js
// Class: DropdownController
// HTML identifier: dropdown

// ✅ CORRECT
export default class extends Controller {
  // Stimulus automatically infers identifier from filename
}

// ❌ WRONG filename
// app/javascript/controllers/Dropdown.js  // Should be snake_case
// app/javascript/controllers/dropdown.js  // Missing _controller suffix
```

## Standard Structure

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]
  static values = { open: Boolean }
  static classes = ["active"]

  connect() {
    // Called when element appears in DOM
    this.close()
  }

  disconnect() {
    // Called when element is removed from DOM
    this.close()
  }

  toggle(event) {
    event.preventDefault()
    this.openValue = !this.openValue
  }

  // Value changed callback
  openValueChanged() {
    if (this.openValue) {
      this.menuTarget.classList.remove("hidden")
      this.buttonTarget.setAttribute("aria-expanded", "true")
    } else {
      this.menuTarget.classList.add("hidden")
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }

  close() {
    this.openValue = false
  }
}
```

## HTML Usage

```erb
<div data-controller="dropdown">
  <button data-dropdown-target="button"
          data-action="click->dropdown#toggle"
          aria-haspopup="true"
          aria-expanded="false">
    Menu
  </button>

  <ul data-dropdown-target="menu" class="hidden">
    <li><a href="#">Edit</a></li>
    <li><a href="#">Delete</a></li>
  </ul>
</div>
```

## Lifecycle Callbacks

```javascript
export default class extends Controller {
  initialize() {
    // Once, when controller is instantiated
  }

  connect() {
    // When element enters DOM (can happen multiple times)
    this.startPolling()
  }

  disconnect() {
    // When element leaves DOM
    this.stopPolling()
  }

  targetConnected(target, targetName) {
    // When target is added
  }

  targetDisconnected(target, targetName) {
    // When target is removed
  }
}
```

## Values and CSS Classes

**Values (typed data):**
```javascript
export default class extends Controller {
  static values = {
    url: String,
    refreshInterval: Number,
    active: Boolean,
    items: Array,
    config: Object
  }

  connect() {
    console.log(this.urlValue)  // Access value
    this.fetchData()
  }

  urlValueChanged(value, previousValue) {
    // Called when value changes
  }
}
```

```erb
<div data-controller="auto-refresh"
     data-auto-refresh-url-value="/api/status"
     data-auto-refresh-refresh-interval-value="5000"
     data-auto-refresh-active-value="true">
</div>
```

**CSS Classes:**
```javascript
export default class extends Controller {
  static classes = ["active", "loading"]

  show() {
    this.element.classList.add(this.activeClass)
  }

  hide() {
    this.element.classList.remove(this.activeClass)
  }
}
```

```erb
<div data-controller="toggle"
     data-toggle-active-class="bg-blue-500">
</div>
```

## Accessibility

**Always include keyboard and ARIA support:**

```javascript
export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()

    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "false")

    // Trap focus in dialog
    this.previousFocus = document.activeElement
    this.dialogTarget.focus()

    // Listen for Escape key
    this.boundEscapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundEscapeHandler)
  }

  close() {
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "true")

    // Restore focus
    this.previousFocus?.focus()

    // Remove listener
    document.removeEventListener("keydown", this.boundEscapeHandler)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
```

## Anti-Patterns

**❌ NEVER:**
- Manipulate DOM outside controller's element
- Store state in DOM data attributes (use values)
- Skip accessibility (keyboard, ARIA)
- Use jQuery (use vanilla JS)

**✅ INSTEAD:**
- Only modify element and targets
- Use Stimulus values for state
- Always include keyboard/ARIA support
- Use native DOM APIs
