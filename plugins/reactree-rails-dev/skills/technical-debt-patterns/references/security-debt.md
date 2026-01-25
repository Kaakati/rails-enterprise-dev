# Security Debt Reference

Comprehensive guide to detecting and addressing security vulnerabilities in Rails applications.

## Brakeman Security Scanner

### Installation and Basic Usage

```bash
# Install
gem install brakeman

# Basic scan
brakeman

# Quiet mode (warnings only)
brakeman -q

# JSON output for parsing
brakeman -f json -o brakeman_report.json

# Only high confidence warnings
brakeman -w3

# Specific checks only
brakeman --only SQLi,XSS,CSRF
```

### Warning Categories

| Category | Description | Typical Severity |
|----------|-------------|------------------|
| SQL Injection | Unsanitized input in queries | Critical |
| Cross-Site Scripting (XSS) | Unescaped output | High |
| Mass Assignment | Unprotected attributes | High |
| Command Injection | Shell command with user input | Critical |
| File Access | Path traversal vulnerabilities | High |
| Remote Code Execution | eval/send with user input | Critical |
| Session Settings | Insecure session configuration | Medium |
| SSL Verification | Disabled certificate verification | High |
| Denial of Service | ReDoS, resource exhaustion | Medium |

### Confidence Levels

| Level | Meaning | Action |
|-------|---------|--------|
| High | Strong indicator of vulnerability | Immediate fix |
| Medium | Likely vulnerable, needs verification | Priority review |
| Weak | Possible issue, may be false positive | Review when possible |

---

## SQL Injection

### Detection Patterns

```bash
# Brakeman check
brakeman --only SQLi

# Manual grep patterns
grep -rn "where(\"" app/
grep -rn "find_by_sql" app/
grep -rn "execute(" app/
grep -rn "\.order(\"" app/
grep -rn "\.select(\"" app/
```

### Vulnerable Patterns

**Direct String Interpolation**:
```ruby
# VULNERABLE
User.where("name = '#{params[:name]}'")
User.where("status = #{params[:status]}")
Order.find_by_sql("SELECT * FROM orders WHERE user_id = #{user_id}")
```

**Using `.order` with User Input**:
```ruby
# VULNERABLE
Product.order("#{params[:sort]} #{params[:direction]}")
```

**Raw SQL with User Input**:
```ruby
# VULNERABLE
ActiveRecord::Base.connection.execute(
  "UPDATE users SET status = '#{status}' WHERE id = #{id}"
)
```

### Secure Patterns

```ruby
# SECURE - Parameterized queries
User.where("name = ?", params[:name])
User.where(name: params[:name])

# SECURE - Sanitize for LIKE
User.where("name LIKE ?", "%#{User.sanitize_sql_like(params[:search])}%")

# SECURE - Whitelist for order
ALLOWED_SORT = %w[name created_at price].freeze
ALLOWED_DIR = %w[asc desc].freeze

sort = ALLOWED_SORT.include?(params[:sort]) ? params[:sort] : 'created_at'
dir = ALLOWED_DIR.include?(params[:direction]) ? params[:direction] : 'asc'
Product.order("#{sort} #{dir}")

# SECURE - Using Arel
User.where(User.arel_table[:name].eq(params[:name]))
```

---

## Cross-Site Scripting (XSS)

### Detection Patterns

```bash
# Brakeman check
brakeman --only XSS

# Manual grep for raw output
grep -rn "raw(" app/views/
grep -rn "html_safe" app/
grep -rn "<%==" app/views/
grep -rn "sanitize(" app/views/  # Check usage
```

### Vulnerable Patterns

```erb
<%# VULNERABLE - raw output %>
<%= raw @user.bio %>
<%= @user.bio.html_safe %>

<%# VULNERABLE - unescaped content tag %>
<%= content_tag :div, @user_input.html_safe %>

<%# VULNERABLE - JavaScript context %>
<script>
  var data = <%= @user_data.to_json %>;  // May need escaping
</script>
```

### Secure Patterns

```erb
<%# SECURE - Default escaping %>
<%= @user.bio %>

<%# SECURE - Explicit sanitization with allowed tags %>
<%= sanitize @user.bio, tags: %w[p br strong em], attributes: %w[class] %>

<%# SECURE - JSON in script tags %>
<script>
  var data = <%= json_escape(@user_data.to_json) %>;
  // Or in Rails 4.1+
  var data = <%= @user_data.to_json.html_safe %>;
</script>

<%# SECURE - In data attributes %>
<div data-config="<%= j @config.to_json %>">
```

---

## Mass Assignment

### Detection Patterns

```bash
# Brakeman check
brakeman --only MassAssignment

# Check for permit usage
grep -rn "params\[" app/controllers/ | grep -v "permit\|require"

# Check models for attr_accessible (Rails 3)
grep -rn "attr_accessible" app/models/
```

### Vulnerable Patterns

```ruby
# VULNERABLE - No strong parameters
def create
  @user = User.create(params[:user])
end

# VULNERABLE - Permitting too much
def user_params
  params.require(:user).permit!
end

# VULNERABLE - Including sensitive attributes
def user_params
  params.require(:user).permit(:name, :email, :admin, :role)
end
```

### Secure Patterns

```ruby
# SECURE - Explicit permit
def user_params
  params.require(:user).permit(:name, :email, :password, :password_confirmation)
end

# SECURE - Role-based parameters
def user_params
  permitted = [:name, :email, :password, :password_confirmation]
  permitted += [:admin, :role] if current_user.admin?
  params.require(:user).permit(permitted)
end

# SECURE - Nested attributes
def order_params
  params.require(:order).permit(
    :customer_id,
    items_attributes: [:product_id, :quantity, :_destroy]
  )
end
```

---

## Command Injection

### Detection Patterns

```bash
# Brakeman check
brakeman --only CommandInjection,Execute

# Manual grep
grep -rn "system(" app/
grep -rn "exec(" app/
grep -rn "popen" app/
grep -rn "\`.*\`" app/
grep -rn "%x{" app/
```

### Vulnerable Patterns

```ruby
# VULNERABLE - Backticks with user input
`ls #{params[:dir]}`

# VULNERABLE - system with interpolation
system("convert #{params[:filename]} output.png")

# VULNERABLE - Open with pipe
IO.popen("cat #{filename}")

# VULNERABLE - Kernel.exec
exec("script.sh #{user_input}")
```

### Secure Patterns

```ruby
# SECURE - Array form (no shell interpolation)
system("ls", "-la", user_dir)

# SECURE - Shellwords escaping
require 'shellwords'
system("convert #{Shellwords.escape(filename)} output.png")

# SECURE - Open3 with array
require 'open3'
stdout, stderr, status = Open3.capture3("convert", filename, "output.png")

# SECURE - Avoid shell entirely
Dir.entries(user_dir)  # Instead of `ls`
FileUtils.cp(src, dest)  # Instead of shell cp
```

---

## File Access Vulnerabilities

### Detection Patterns

```bash
# Brakeman check
brakeman --only FileAccess

# Manual grep
grep -rn "File.read" app/
grep -rn "File.open" app/
grep -rn "send_file" app/
grep -rn "render.*file:" app/
```

### Vulnerable Patterns

```ruby
# VULNERABLE - Path traversal
def download
  send_file "#{Rails.root}/uploads/#{params[:filename]}"
end

# VULNERABLE - Arbitrary file read
def show
  @content = File.read(params[:path])
end

# VULNERABLE - render with user path
render file: params[:template]
```

### Secure Patterns

```ruby
# SECURE - Basename only
def download
  filename = File.basename(params[:filename])
  path = Rails.root.join('uploads', filename)

  if File.exist?(path) && path.to_s.start_with?(Rails.root.join('uploads').to_s)
    send_file path
  else
    head :not_found
  end
end

# SECURE - Whitelist approach
ALLOWED_FILES = %w[terms privacy faq].freeze

def show
  return head(:not_found) unless ALLOWED_FILES.include?(params[:page])
  render template: "static/#{params[:page]}"
end

# SECURE - ActiveStorage
def download
  attachment = current_user.attachments.find(params[:id])
  redirect_to rails_blob_path(attachment, disposition: "attachment")
end
```

---

## Session Security

### Configuration Checklist

```ruby
# config/initializers/session_store.rb

# SECURE settings
Rails.application.config.session_store :cookie_store,
  key: '_app_session',
  secure: Rails.env.production?,      # HTTPS only in production
  httponly: true,                     # Prevent JS access
  same_site: :lax,                    # CSRF protection
  expire_after: 30.minutes            # Session timeout
```

### Common Issues

| Issue | Risk | Fix |
|-------|------|-----|
| `secure: false` in production | Session hijacking | Set `secure: true` |
| Missing `httponly` | XSS session theft | Set `httponly: true` |
| No `same_site` | CSRF attacks | Set `same_site: :lax` or `:strict` |
| Long/no expiration | Stale sessions | Set reasonable `expire_after` |
| Weak secret key | Session forgery | Use strong random key |

---

## CSRF Protection

### Verification

```ruby
# Ensure CSRF is enabled (default in Rails)
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# For APIs using sessions
class ApiController < ApplicationController
  protect_from_forgery with: :null_session
end

# For APIs with tokens only (no CSRF needed)
class ApiController < ActionController::API
  # No CSRF protection needed - using token auth
end
```

### Common Mistakes

```ruby
# VULNERABLE - Skipping CSRF globally
class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token  # NEVER do this
end

# SOMETIMES OK - Specific actions with token auth
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:stripe]

  def stripe
    # Verify Stripe signature instead
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    # ...
  end
end
```

---

## Severity Scoring for Security Debt

| Factor | Critical | High | Medium | Low |
|--------|----------|------|--------|-----|
| Exploitability | Remote, no auth | Remote, auth required | Local only | Theoretical |
| Impact | Data breach, RCE | Data modification | Info disclosure | Minor |
| Affected Users | All users | Subset | Single user | None |
| Brakeman Confidence | High | High/Medium | Medium | Weak |

### SLA by Severity

| Severity | SLA | Example |
|----------|-----|---------|
| Critical | 24-48 hours | SQL injection in login |
| High | 1 week | XSS in user profile |
| Medium | 1 sprint | Missing CSRF on low-risk action |
| Low | Quarterly | Informational header missing |

---

## CI Integration

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  push:
    branches: [main, develop]
  pull_request:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  brakeman:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Brakeman
        uses: artplan1/brakeman-action@v1
        with:
          flags: "-w3 --no-pager"

  bundle-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Run bundler-audit
        run: |
          gem install bundler-audit
          bundle-audit check --update
```
