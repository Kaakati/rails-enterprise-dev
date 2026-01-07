---
paths: "{app/components/**/*.{rb,erb},app/views/**/*.erb}"
---

# Accessibility (WCAG 2.2 Level AA)

Apply to all ViewComponents and ERB templates

## Keyboard Navigation

```erb
<%# ✅ All interactive elements must be keyboard accessible %>
<button type="button">Accessible Button</button>
<a href="/path">Accessible Link</a>

<%# ❌ WRONG: div as button (not keyboard accessible) %>
<div onclick="doSomething()">Not Accessible</div>

<%# ✅ If custom element needed, add tabindex and role %>
<div role="button" tabindex="0" data-action="click->handler#action">
  Custom Button
</div>
```

**Never use `tabindex` > 0:**
```erb
<%# ❌ WRONG: Disrupts natural tab order %>
<input tabindex="3">
<input tabindex="1">
<input tabindex="2">

<%# ✅ CORRECT: Natural DOM order %>
<input>
<input>
<input>
```

## ARIA Attributes

**Label all interactive elements:**
```erb
<%# Button with icon (needs label) %>
<button aria-label="Close modal">
  <svg>...</svg>
</button>

<%# Expandable section %>
<button aria-expanded="false" aria-controls="details">
  Show Details
</button>
<div id="details" hidden>...</div>

<%# Live regions for dynamic content %>
<div role="alert" aria-live="assertive">
  <%= flash[:alert] %>
</div>

<div role="status" aria-live="polite">
  Loading results...
</div>
```

## Color Contrast

**Minimum contrast ratios:**
- Normal text: 4.5:1
- Large text (18pt+): 3:1
- UI components: 3:1

**TailAdmin classes meet WCAG requirements:**
```erb
<%# Text colors with sufficient contrast %>
<p class="text-black dark:text-white">Readable text</p>

<%# Use semantic colors %>
<span class="text-success">Success message</span>
<span class="text-danger">Error message</span>
```

## Form Accessibility

```erb
<%# ✅ Always use label with for attribute %>
<label for="email">Email Address</label>
<input type="email" id="email" name="email">

<%# ✅ Provide error messages %>
<input type="email"
       id="email"
       aria-invalid="true"
       aria-describedby="email-error">
<div id="email-error" role="alert">
  Please enter a valid email
</div>

<%# ✅ Group related inputs %>
<fieldset>
  <legend>Contact Information</legend>
  <label for="name">Name</label>
  <input id="name">

  <label for="email">Email</label>
  <input id="email">
</fieldset>
```

## Image Alt Text

```erb
<%# ✅ Descriptive alt text for meaningful images %>
<%= image_tag "logo.png", alt: "Company Name Logo" %>

<%# ✅ Empty alt for decorative images %>
<%= image_tag "decorative-border.png", alt: "" %>

<%# ❌ NEVER omit alt attribute %>
<%= image_tag "important.png" %>  # WRONG!
```

## Semantic HTML

```erb
<%# ✅ Use semantic elements %>
<header>
  <nav>
    <ul>
      <li><a href="/">Home</a></li>
    </ul>
  </nav>
</header>

<main>
  <article>
    <h1>Page Title</h1>
    <p>Content...</p>
  </article>
</main>

<aside>
  <h2>Related</h2>
</aside>

<footer>
  <p>&copy; 2026</p>
</footer>

<%# ❌ WRONG: Generic divs %>
<div class="header">
  <div class="nav">...</div>
</div>
```
