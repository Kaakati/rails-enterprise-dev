---
paths: "**/*.rb"
---

# Security Best Practices

Apply to all Ruby files

## SQL Injection Prevention

```ruby
# ❌ NEVER: String interpolation in SQL
User.where("email = '#{params[:email]}'")  # DANGEROUS!

# ✅ ALWAYS: Parameterized queries
User.where("email = ?", params[:email])

# ✅ BETTER: Hash conditions
User.where(email: params[:email])
```

## Mass Assignment Protection

```ruby
# ❌ NEVER: Permit all parameters
def user_params
  params.require(:user).permit!  # SECURITY RISK!
end

# ✅ ALWAYS: Explicit allow-list
def user_params
  params.require(:user).permit(:name, :email, :password)
end
```

## Authentication

```ruby
# ✅ Use Devise or has_secure_password
class User < ApplicationRecord
  has_secure_password
end

# ❌ NEVER store passwords in plain text
# ❌ NEVER use MD5/SHA1 for passwords (use bcrypt)
```

## XSS Prevention

```erb
<%# ✅ SAFE: ERB auto-escapes by default %>
<%= user.name %>

<%# ❌ DANGEROUS: html_safe on user input %>
<%= user.bio.html_safe %>  # XSS vulnerability!

<%# ✅ SAFE: Sanitize user HTML %>
<%= sanitize(user.bio, tags: %w[p br strong em]) %>
```

## Secrets Management

```ruby
# ❌ NEVER hardcode secrets
API_KEY = "sk_live_123456"  # WRONG!

# ✅ ALWAYS use encrypted credentials
Rails.application.credentials.stripe[:api_key]

# ✅ Or environment variables
ENV['STRIPE_API_KEY']
```

## CSRF Protection

```ruby
# ✅ CSRF protection enabled by default in Rails
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# ⚠️ Only skip for API endpoints
class Api::BaseController < ActionController::API
  # CSRF not needed for stateless JWT auth
end
```

## Authorization

```ruby
# ✅ Always verify ownership before actions
def edit
  @post = current_user.posts.find(params[:id])  # Scoped to current user
end

# ❌ NEVER skip authorization
def edit
  @post = Post.find(params[:id])  # Anyone can edit any post!
end
```
