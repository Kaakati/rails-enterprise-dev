---
paths: app/jobs/**/*.rb
---

# Sidekiq Job Patterns

Apply to all files in `app/jobs/**/*.rb`

## Naming Convention

**Always end with `Job`:**
```ruby
# ✅ CORRECT
SendEmailJob
ProcessReportJob
ImportDataJob

# ❌ WRONG
SendEmail  # Missing "Job" suffix
EmailSender  # Wrong pattern
```

## Standard Job Structure

```ruby
# app/jobs/send_email_job.rb
class SendEmailJob < ApplicationJob
  queue_as :default  # or :mailers, :reports, etc.

  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(user_id, email_type)
    user = User.find(user_id)
    UserMailer.send(email_type, user).deliver_now
  end
end
```

## Queue Configuration

**Use descriptive queue names:**
```ruby
class HighPriorityJob < ApplicationJob
  queue_as :critical  # Processed first
end

class EmailJob < ApplicationJob
  queue_as :mailers  # Dedicated queue for emails
end

class ReportJob < ApplicationJob
  queue_as :reports  # Lower priority, batch processing
end

# config/sidekiq.yml
:queues:
  - [critical, 10]  # Weight: process 10x more often
  - [default, 5]
  - [mailers, 3]
  - [reports, 1]
```

## Retry and Error Handling

```ruby
class ImportDataJob < ApplicationJob
  # Retry with exponential backoff
  retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 10

  # Retry specific errors immediately
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Discard jobs that will never succeed
  discard_on ActiveJob::DeserializationError
  discard_on CustomBusinessError

  # Custom error handling
  rescue_from(StandardError) do |exception|
    Rails.logger.error("Job failed: #{exception.message}")
    ErrorNotifier.notify(exception, job: self)
    raise  # Re-raise to let Sidekiq handle retry logic
  end

  def perform(file_path)
    ImportService.new(file_path).call
  end
end
```

## Idempotency

**Design jobs to be safely retried:**
```ruby
class ProcessPaymentJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)

    # Idempotency check
    return if order.payment_processed?

    # Process payment
    result = PaymentService.new(order).process

    # Mark as processed
    order.update!(payment_processed_at: Time.current) if result.success?
  end
end
```

## Scheduled Jobs

```ruby
# Recurring jobs with Sidekiq Cron or sidekiq-scheduler
class DailyReportJob < ApplicationJob
  queue_as :reports

  def perform
    Report.generate_daily
  end
end

# config/schedule.yml (sidekiq-scheduler)
DailyReportJob:
  cron: '0 6 * * *'  # Every day at 6 AM
  class: DailyReportJob

# Or use perform_later with delay
ExpirationCheckJob.set(wait: 1.hour).perform_later
```

## Job Arguments

**Pass simple serializable data:**
```ruby
# ✅ GOOD: Pass IDs
ProcessOrderJob.perform_later(order.id)

# ❌ BAD: Pass ActiveRecord objects (can cause stale data)
ProcessOrderJob.perform_later(order)

# ✅ GOOD: Pass primitive values
SendEmailJob.perform_later(user_id, "welcome", { name: "John" })
```

## Batching

```ruby
class BulkEmailJob < ApplicationJob
  def perform(user_ids)
    User.where(id: user_ids).find_each do |user|
      UserMailer.newsletter(user).deliver_now
    end
  end
end

# Enqueue with batched IDs
User.active.pluck(:id).each_slice(1000) do |batch|
  BulkEmailJob.perform_later(batch)
end
```

## Anti-Patterns

**❌ NEVER:**
- Pass ActiveRecord objects as arguments (pass IDs)
- Use jobs for synchronous operations (use services)
- Perform long-running tasks without monitoring
- Skip idempotency checks
- Ignore job failures silently

**✅ INSTEAD:**
- Pass IDs and serialize in `perform`
- Use jobs for async, background work
- Set appropriate timeouts and monitoring
- Design for safe retries
- Log errors and send notifications
