---
paths: app/channels/**/*.rb
---

# Action Cable Channel Patterns

Apply to all files in `app/channels/**/*.rb`

## Naming Convention

**Always end with `Channel`:**
```ruby
# ✅ CORRECT
ChatChannel
NotificationsChannel
PresenceChannel

# ❌ WRONG
Chat  # Missing "Channel" suffix
ChatWebSocket  # Wrong pattern
```

## Standard Channel Structure

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Authorization check FIRST
    reject unless current_user

    # Subscribe to stream
    stream_from "chat_#{params[:room_id]}"
  end

  def unsubscribed
    # Cleanup when client disconnects
    # Called automatically when connection closes
  end

  def speak(data)
    # Receive message from client
    ActionCable.server.broadcast(
      "chat_#{params[:room_id]}",
      message: data['message'],
      user: current_user.name
    )
  end
end
```

## Stream Patterns

### stream_from (Broadcasting Name)

**Basic usage:**
```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room_id]}"
  end
end
```

**With callback when data received:**
```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room_id]}", coder: ActiveSupport::JSON do |message|
      # Called when data is broadcast to this stream
      # Use for logging, filtering, or transforming data
      Rails.logger.info "Message received: #{message}"
    end
  end
end
```

**Custom coder (default is ActiveSupport::JSON):**
```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Use MessagePack instead of JSON for better performance
    stream_from "chat_#{params[:room_id]}", coder: MessagePackCoder
  end
end
```

### stream_for (Model-based Broadcasting)

**Automatically generates broadcasting names from models:**
```ruby
class CommentsChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:id])

    # Generates broadcasting name like "comments:Post:1"
    stream_for post
  end
end

# Broadcasting from elsewhere:
CommentsChannel.broadcast_to(@post, comment: @comment)
```

**Why use stream_for?**
- Consistent naming convention
- Type-safe (ensures model exists)
- Easier to broadcast from models/services

### stop_all_streams

**Unsubscribe from all streams:**
```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_global"
    stream_from "chat_#{params[:room_id]}"
  end

  def leave_room
    # Stop streaming from room, but keep global stream
    stop_all_streams
    stream_from "chat_global"  # Re-subscribe to global only
  end
end
```

## Lifecycle Callbacks

**4 callback hooks available:**

```ruby
class ChatChannel < ApplicationCable::Channel
  before_subscribe :check_permissions
  after_subscribe :log_subscription
  before_unsubscribe :cleanup_data
  after_unsubscribe :log_unsubscription

  def subscribed
    stream_from "chat_#{params[:room_id]}"
  end

  private

  def check_permissions
    # Runs BEFORE subscribed method
    # Reject if user lacks permissions
    reject unless current_user.can_access_room?(params[:room_id])
  end

  def log_subscription
    # Runs AFTER subscribed method completes successfully
    Rails.logger.info "User #{current_user.id} subscribed to room #{params[:room_id]}"
  end

  def cleanup_data
    # Runs BEFORE unsubscribed method
    # Clean up temporary data
    Redis.current.del("user_typing_#{current_user.id}")
  end

  def log_unsubscription
    # Runs AFTER unsubscribed method completes
    Rails.logger.info "User #{current_user.id} unsubscribed"
  end
end
```

**Callback Execution Order:**

1. `before_subscribe` callbacks
2. `subscribed` method
3. `after_subscribe` callbacks
4. [client sends/receives data]
5. `before_unsubscribe` callbacks
6. `unsubscribed` method
7. `after_unsubscribe` callbacks

**Conditional Callbacks:**
```ruby
class ChatChannel < ApplicationCable::Channel
  before_subscribe :log_subscription, if: :logging_enabled?
  after_unsubscribe :notify_admin, unless: :test_environment?

  private

  def logging_enabled?
    Rails.env.production?
  end

  def test_environment?
    Rails.env.test?
  end
end
```

## Authorization Patterns

**ALWAYS authorize in `subscribed` method:**

```ruby
class PrivateConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find(params[:id])

    # ✅ CORRECT: Reject unauthorized users
    reject unless conversation.participant?(current_user)

    stream_for conversation
  end
end
```

**Complex authorization:**
```ruby
class AdminChannel < ApplicationCable::Channel
  def subscribed
    # Multiple conditions
    reject unless current_user
    reject unless current_user.admin?
    reject unless current_user.active?

    stream_from "admin_notifications"
  end
end
```

## Broadcasting Patterns

### From Controllers/Services

```ruby
# In controller or service
class PostsController < ApplicationController
  def create
    @post = current_user.posts.create(post_params)

    # Broadcast to specific channel
    ActionCable.server.broadcast(
      "posts_#{current_user.id}",
      action: 'new_post',
      post: @post
    )
  end
end
```

### From Models (Callbacks)

```ruby
class Comment < ApplicationRecord
  belongs_to :post

  after_create_commit { broadcast_new_comment }

  private

  def broadcast_new_comment
    CommentsChannel.broadcast_to(
      post,
      comment: self,
      action: 'comment_created'
    )
  end
end
```

### From Background Jobs

```ruby
class NotificationJob < ApplicationJob
  def perform(user_id, message)
    ActionCable.server.broadcast(
      "notifications_#{user_id}",
      type: 'alert',
      message: message,
      timestamp: Time.current
    )
  end
end
```

## Client Action Methods

**Receive client-initiated actions:**

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room_id]}"
  end

  # Client calls: channel.perform('send_message', {text: 'Hello'})
  def send_message(data)
    # Validate data
    return unless data['text'].present?

    # Broadcast to all subscribers
    ActionCable.server.broadcast(
      "chat_#{params[:room_id]}",
      user: current_user.name,
      message: data['text'],
      timestamp: Time.current
    )
  end

  # Client calls: channel.perform('typing', {typing: true})
  def typing(data)
    # Broadcast typing indicator (don't persist)
    ActionCable.server.broadcast(
      "chat_#{params[:room_id]}_typing",
      user: current_user.name,
      typing: data['typing']
    )
  end
end
```

## Performance Considerations

### Avoid N+1 Queries in Callbacks

```ruby
# ❌ BAD: N+1 query if callback called in loop
class CommentsChannel < ApplicationCable::Channel
  after_subscribe :increment_viewer_count

  def increment_viewer_count
    post = Post.find(params[:post_id])  # Query for each subscription!
    post.increment!(:viewer_count)
  end
end

# ✅ GOOD: Use counter cache or background job
class CommentsChannel < ApplicationCable::Channel
  after_subscribe :schedule_viewer_count_update

  def schedule_viewer_count_update
    UpdateViewerCountJob.perform_later(params[:post_id])
  end
end
```

### Stream Naming Conventions

**Use consistent, predictable patterns:**

```ruby
# ✅ GOOD: Clear, consistent naming
stream_from "posts:#{post.id}:comments"
stream_from "users:#{user.id}:notifications"
stream_from "chat:room:#{room_id}"

# ❌ BAD: Inconsistent or unclear naming
stream_from "post_#{post.id}_comments"  # Inconsistent separator
stream_from "notifications_for_user_#{user.id}"  # Too verbose
stream_from "room#{room_id}"  # Missing namespace
```

## Common Pitfalls

### 1. Data Loss on Disconnect

**Problem:** Clients may disconnect before receiving broadcasts

**Solution:** Persist critical data, use broadcasts for notifications only

```ruby
# ❌ BAD: Only broadcast, don't persist
def create_message(data)
  ActionCable.server.broadcast(
    "chat_#{params[:room_id]}",
    message: data['text']  # Lost if client disconnected!
  )
end

# ✅ GOOD: Persist first, then broadcast
def create_message(data)
  message = Message.create!(
    room_id: params[:room_id],
    user: current_user,
    text: data['text']
  )

  # Now broadcast (clients can fetch from DB if missed)
  ActionCable.server.broadcast(
    "chat_#{params[:room_id]}",
    message: message
  )
end
```

### 2. Callback Execution Assumptions

**Don't assume callbacks always run:**

```ruby
# ❌ BAD: Assuming after_subscribe always runs
class ChatChannel < ApplicationCable::Channel
  after_subscribe :mark_user_online

  def subscribed
    stream_from "chat_global"
    # If this raises error, after_subscribe won't run!
    raise "Error!" if bad_condition
  end
end

# ✅ GOOD: Critical logic in subscribed method
class ChatChannel < ApplicationCable::Channel
  def subscribed
    mark_user_online  # Runs even if stream setup fails later
    stream_from "chat_global"
  end
end
```

### 3. Forgetting to Reject Unauthorized Users

**Always explicitly reject:**

```ruby
# ❌ BAD: Silent failure (still subscribed!)
def subscribed
  return unless current_user.admin?  # Still subscribed!
  stream_from "admin_channel"
end

# ✅ GOOD: Explicit rejection
def subscribed
  reject unless current_user.admin?  # Connection closed
  stream_from "admin_channel"
end
```

## Testing Action Cable Channels

**RSpec example:**

```ruby
# spec/channels/chat_channel_spec.rb
RSpec.describe ChatChannel, type: :channel do
  let(:user) { create(:user) }
  let(:room) { create(:room) }

  before { stub_connection(current_user: user) }

  describe '#subscribed' do
    it 'subscribes to chat stream' do
      subscribe(room_id: room.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("chat_#{room.id}")
    end

    it 'rejects unauthorized users' do
      stub_connection(current_user: nil)
      subscribe(room_id: room.id)

      expect(subscription).to be_rejected
    end
  end

  describe '#send_message' do
    it 'broadcasts message to room' do
      subscribe(room_id: room.id)

      expect {
        perform :send_message, text: 'Hello'
      }.to have_broadcasted_to("chat_#{room.id}").with(
        user: user.name,
        message: 'Hello'
      )
    end
  end
end
```

## Anti-Patterns

**❌ NEVER:**
- Skip authorization in `subscribed`
- Broadcast sensitive data without filtering
- Use channels for non-real-time features
- Assume client received broadcast (persist critical data)
- Use dynamic stream names without validation
- Put heavy processing in channel methods
- Forget to test authorization logic

**✅ INSTEAD:**
- Always authorize subscriptions with `reject unless`
- Filter data before broadcasting
- Use background jobs for async work, channels for real-time updates
- Persist data in database, broadcast as notification
- Validate and sanitize stream parameters
- Delegate heavy work to background jobs
- Write comprehensive channel specs
