---
paths: app/mailers/**/*.rb
---

# Action Mailer Patterns

Apply to all files in `app/mailers/**/*.rb`

## Naming Convention

**Always end with `Mailer`:**
```ruby
# ✅ CORRECT
UserMailer
OrderMailer
NotificationMailer

# ❌ WRONG
UserEmails  # Missing "Mailer" suffix
EmailSender  # Wrong pattern
```

## Standard Mailer Structure

```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome(user)
    @user = user
    @login_url = login_url

    mail(
      to: @user.email,
      subject: "Welcome to #{ApplicationConfig.site_name}!"
    )
  end

  def password_reset(user, token)
    @user = user
    @reset_url = password_reset_url(token: token)

    mail(
      to: @user.email,
      subject: "Reset your password"
    )
  end
end
```

## Delivering Emails

**Asynchronous delivery (recommended):**
```ruby
# Enqueue for background processing
UserMailer.welcome(user).deliver_later

# With delay
UserMailer.welcome(user).deliver_later(wait: 1.hour)

# With specific queue
UserMailer.welcome(user).deliver_later(queue: :mailers)
```

**Synchronous delivery (use sparingly):**
```ruby
# Immediate delivery (blocks execution)
UserMailer.welcome(user).deliver_now
```

## Templates

**Create both HTML and text versions:**
```
app/views/user_mailer/
├── welcome.html.erb
└── welcome.text.erb
```

```erb
<%# app/views/user_mailer/welcome.html.erb %>
<h1>Welcome, <%= @user.name %>!</h1>
<p>Thanks for signing up.</p>
<%= link_to 'Get Started', @login_url %>

<%# app/views/user_mailer/welcome.text.erb %>
Welcome, <%= @user.name %>!

Thanks for signing up.

Get Started: <%= @login_url %>
```

## Attachments

```ruby
def invoice(order)
  @order = order

  attachments['invoice.pdf'] = order.generate_pdf

  mail(to: order.user.email, subject: 'Your Invoice')
end
```

## Anti-Patterns

**❌ NEVER:**
- Use `deliver_now` in controllers (use `deliver_later`)
- Send emails without unsubscribe links (legal requirement)
- Hardcode email content (use I18n)

**✅ INSTEAD:**
- Always use `deliver_later` for async delivery
- Include unsubscribe mechanism
- Use translation keys for multi-language support
