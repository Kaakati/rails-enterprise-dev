---
name: "Action Cable & WebSocket Patterns"
description: "Complete guide to implementing real-time WebSocket features with Action Cable in Ruby on Rails. Use this skill when: (1) Building real-time chat applications, (2) Implementing live notifications and presence tracking, (3) Creating collaborative features, (4) Broadcasting model updates, (5) Setting up WebSocket authentication and authorization, (6) Testing Action Cable channels. Trigger keywords: Action Cable, WebSocket, real-time, channels, broadcasting, stream, subscriptions, presence, live updates, cable"
---

# Action Cable & WebSocket Patterns Skill

This skill provides comprehensive guidance for implementing real-time WebSocket features with Action Cable in Rails applications.

## When to Use This Skill

- Creating real-time chat features
- Implementing live notifications
- Building presence tracking (who's online)
- Broadcasting model updates
- Collaborative editing features
- Live dashboards and analytics
- Setting up channel authorization
- Testing WebSocket functionality

## External Documentation

**Official Guides**: https://guides.rubyonrails.org/action_cable_overview.html
**API Documentation**: https://api.rubyonrails.org/classes/ActionCable.html

```bash
# Always check official documentation for:
# - Action Cable Overview: https://guides.rubyonrails.org/action_cable_overview.html
# - Channel API: https://api.rubyonrails.org/classes/ActionCable/Channel/Base.html
# - Streams API: https://api.rubyonrails.org/classes/ActionCable/Channel/Streams.html
# - Testing: https://guides.rubyonrails.org/testing.html#testing-action-cable
```

## Pre-Work Inspection

```bash
# Check existing channels
ls app/channels/ 2>/dev/null

# Check channel naming conventions
find app/channels -name '*_channel.rb' -exec head -20 {} \; | head -50

# Check Action Cable configuration
cat config/cable.yml 2>/dev/null
cat config/environments/production.rb | grep -A 5 'action_cable' 2>/dev/null

# Check for existing broadcasting patterns
grep -r 'ActionCable.server.broadcast\|broadcast_to' app/ --include='*.rb' | head -10

# Check JavaScript/TypeScript consumer setup
find app/javascript -name 'cable.js' -o -name 'consumer.js' 2>/dev/null
```

## Core Principles

### 1. Authorization First (CRITICAL)

**ALWAYS authorize in `subscribed` method** - reject unauthorized users explicitly.

```ruby
# WRONG - No authorization (security vulnerability!)
class PrivateChannel < ApplicationCable::Channel
  def subscribed
    stream_from "private_data"  # Anyone can subscribe!
  end
end

# CORRECT - Explicit authorization
class PrivateChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user
    reject unless current_user.admin?

    stream_from "private_data"
  end
end
```

### 2. Persist First, Broadcast Second

**Never rely on broadcasts alone** - clients may disconnect before receiving data.

```ruby
# WRONG - Only broadcast (data lost if client offline)
def create_message(data)
  ActionCable.server.broadcast(
    "chat_#{params[:room_id]}",
    message: data['text']  # Lost forever if client disconnected!
  )
end

# CORRECT - Persist then broadcast
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

### 3. Use `stream_for` for Model Broadcasting

**Prefer `stream_for` over `stream_from`** for model-based streams.

```ruby
# WRONG - Manual broadcasting names (error-prone)
stream_from "posts:#{params[:id]}"
ActionCable.server.broadcast("posts:#{@post.id}", data)  # Typo-prone!

# CORRECT - Type-safe model broadcasting
stream_for @post
PostsChannel.broadcast_to(@post, data)  # Automatic naming
```

## Channel Structure Template

```ruby
# app/channels/notifications_channel.rb
class NotificationsChannel < ApplicationCable::Channel
  # Lifecycle callbacks (optional)
  before_subscribe :authenticate_user
  after_subscribe :log_subscription
  before_unsubscribe :cleanup_presence
  after_unsubscribe :log_unsubscription

  def subscribed
    # 1. Authorization (REQUIRED)
    reject unless current_user

    # 2. Subscribe to personal stream
    stream_from "notifications_#{current_user.id}"

    # 3. Mark user as online (optional)
    mark_online
  end

  def unsubscribed
    # Cleanup when client disconnects
    mark_offline
  end

  # Client-initiated action: channel.perform('mark_as_read', {id: 123})
  def mark_as_read(data)
    notification = current_user.notifications.find(data['id'])
    notification.mark_as_read!

    # Broadcast updated count to user
    ActionCable.server.broadcast(
      "notifications_#{current_user.id}",
      action: 'count_updated',
      unread_count: current_user.notifications.unread.count
    )
  end

  private

  def authenticate_user
    reject unless current_user
  end

  def log_subscription
    Rails.logger.info "User #{current_user.id} subscribed to notifications"
  end

  def cleanup_presence
    PresenceService.mark_offline(current_user)
  end

  def mark_online
    PresenceService.mark_online(current_user)
  end

  def mark_offline
    PresenceService.mark_offline(current_user)
  end
end
```

## Stream Patterns

### Pattern 1: Personal User Streams

```ruby
class UserChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user

    # Each user gets their own stream
    stream_from "user_#{current_user.id}"
  end
end

# Broadcasting from elsewhere
ActionCable.server.broadcast(
  "user_#{user.id}",
  type: 'notification',
  message: 'You have a new message'
)
```

### Pattern 2: Model-based Streams

```ruby
class PostChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:id])
    reject unless post.published? || post.author == current_user

    # Generates stream name: "posts:Post:123"
    stream_for post
  end
end

# Broadcasting from model
class Post < ApplicationRecord
  after_update_commit { broadcast_changes }

  private

  def broadcast_changes
    PostChannel.broadcast_to(
      self,
      action: 'updated',
      post: self.as_json(only: [:id, :title, :body])
    )
  end
end
```

### Pattern 3: Room/Group Streams

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    reject unless room.member?(current_user)

    stream_from "chat_room_#{room.id}"
  end

  def speak(data)
    room = Room.find(params[:room_id])
    message = room.messages.create!(
      user: current_user,
      text: data['text']
    )

    ActionCable.server.broadcast(
      "chat_room_#{room.id}",
      action: 'new_message',
      message: message,
      user: current_user.as_json(only: [:id, :name])
    )
  end
end
```

### Pattern 4: Presence Tracking

```ruby
class PresenceChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user

    # Subscribe to room presence
    @room_id = params[:room_id]
    stream_from "presence_room_#{@room_id}"

    # Add user to room
    add_to_room
  end

  def unsubscribed
    remove_from_room
  end

  def heartbeat
    # Client sends periodic heartbeat
    Redis.current.setex(
      "presence:user:#{current_user.id}:room:#{@room_id}",
      30, # 30 second TTL
      Time.current.to_i
    )
  end

  private

  def add_to_room
    Redis.current.sadd("room:#{@room_id}:members", current_user.id)

    # Broadcast updated member list
    ActionCable.server.broadcast(
      "presence_room_#{@room_id}",
      action: 'user_joined',
      user: current_user.as_json(only: [:id, :name]),
      member_count: room_member_count
    )
  end

  def remove_from_room
    Redis.current.srem("room:#{@room_id}:members", current_user.id)

    ActionCable.server.broadcast(
      "presence_room_#{@room_id}",
      action: 'user_left',
      user_id: current_user.id,
      member_count: room_member_count
    )
  end

  def room_member_count
    Redis.current.scard("room:#{@room_id}:members")
  end
end
```

## Broadcasting Strategies

### From Controllers (Synchronous)

```ruby
class CommentsController < ApplicationController
  def create
    @comment = @post.comments.create!(comment_params)

    # Broadcast immediately after creation
    CommentsChannel.broadcast_to(
      @post,
      action: 'comment_created',
      comment: @comment.as_json,
      total_count: @post.comments.count
    )

    render json: @comment, status: :created
  end
end
```

### From Models (After Commit)

```ruby
class Notification < ApplicationRecord
  belongs_to :user

  # Use after_commit to ensure transaction completes
  after_create_commit { broadcast_notification }

  private

  def broadcast_notification
    ActionCable.server.broadcast(
      "notifications_#{user_id}",
      action: 'notification_created',
      notification: self.as_json,
      unread_count: user.notifications.unread.count
    )
  end
end
```

### From Background Jobs (Async)

```ruby
class BroadcastUpdateJob < ApplicationJob
  queue_as :broadcasts

  def perform(model_class, model_id, action, data = {})
    model = model_class.constantize.find(model_id)
    channel_class = "#{model_class}Channel".constantize

    channel_class.broadcast_to(
      model,
      action: action,
      data: data
    )
  end
end

# Usage
BroadcastUpdateJob.perform_later('Post', post.id, 'updated', { likes_count: post.likes.count })
```

## Connection Authentication

### app/channels/application_cable/connection.rb

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Cookie-based authentication (default Rails)
      if verified_user = User.find_by(id: cookies.encrypted[:user_id])
        verified_user
      # Token-based authentication (for API clients)
      elsif verified_user = find_user_from_token
        verified_user
      else
        reject_unauthorized_connection
      end
    end

    def find_user_from_token
      # Extract token from query params or headers
      token = request.params[:token] || extract_token_from_headers
      return nil unless token

      # Verify JWT or session token
      payload = JWT.decode(token, Rails.application.secret_key_base).first
      User.find_by(id: payload['user_id'])
    rescue JWT::DecodeError
      nil
    end

    def extract_token_from_headers
      # Extract from Authorization header if present
      if request.headers['Authorization'].present?
        request.headers['Authorization'].split(' ').last
      end
    end
  end
end
```

## Client-Side Integration (JavaScript)

### Consumer Setup

```javascript
// app/javascript/channels/consumer.js
import { createConsumer } from "@rails/actioncable"

export default createConsumer()
```

### Channel Subscription

```javascript
// app/javascript/channels/notifications_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("NotificationsChannel", {
  connected() {
    console.log("Connected to notifications channel")
  },

  disconnected() {
    console.log("Disconnected from notifications channel")
  },

  received(data) {
    // Handle received data
    console.log("Received:", data)

    switch(data.action) {
      case 'notification_created':
        this.showNotification(data.notification)
        this.updateBadge(data.unread_count)
        break
      case 'count_updated':
        this.updateBadge(data.unread_count)
        break
    }
  },

  // Client-initiated actions
  markAsRead(notificationId) {
    this.perform('mark_as_read', { id: notificationId })
  },

  showNotification(notification) {
    // Display notification in UI
  },

  updateBadge(count) {
    // Update unread count badge
  }
})
```

### Parametrized Channels

```javascript
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

const roomId = document.getElementById('room-id').value

consumer.subscriptions.create({ channel: "ChatChannel", room_id: roomId }, {
  received(data) {
    if (data.action === 'new_message') {
      this.appendMessage(data.message)
    }
  },

  speak(message) {
    this.perform('speak', { text: message })
  },

  appendMessage(message) {
    const messagesEl = document.getElementById('messages')
    messagesEl.insertAdjacentHTML('beforeend', `
      <div class="message">
        <strong>${message.user.name}:</strong> ${message.text}
      </div>
    `)
  }
})
```

## Testing Action Cable

### Channel Specs (RSpec)

```ruby
# spec/channels/notifications_channel_spec.rb
require 'rails_helper'

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  before do
    # Stub the connection with current_user
    stub_connection(current_user: user)
  end

  describe '#subscribed' do
    it 'subscribes to user notification stream' do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("notifications_#{user.id}")
    end

    it 'rejects unauthenticated users' do
      stub_connection(current_user: nil)
      subscribe

      expect(subscription).to be_rejected
    end
  end

  describe '#mark_as_read' do
    let!(:notification) { create(:notification, user: user) }

    it 'marks notification as read' do
      subscribe

      perform :mark_as_read, id: notification.id

      expect(notification.reload).to be_read
    end

    it 'broadcasts updated count' do
      subscribe

      expect {
        perform :mark_as_read, id: notification.id
      }.to have_broadcasted_to("notifications_#{user.id}").with(
        action: 'count_updated',
        unread_count: 0
      )
    end
  end
end
```

### Connection Specs

```ruby
# spec/channels/application_cable/connection_spec.rb
require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }

  it 'successfully connects with valid user' do
    cookies.encrypted[:user_id] = user.id

    connect '/cable'

    expect(connection.current_user).to eq(user)
  end

  it 'rejects connection without user' do
    expect { connect '/cable' }.to have_rejected_connection
  end

  it 'successfully connects with valid token' do
    token = generate_jwt_token(user)

    connect "/cable?token=#{token}"

    expect(connection.current_user).to eq(user)
  end
end
```

### Integration Testing

```ruby
# spec/system/chat_spec.rb
require 'rails_helper'

RSpec.describe 'Chat functionality', type: :system, js: true do
  let(:user) { create(:user) }
  let(:room) { create(:room) }

  before do
    sign_in user
    room.add_member(user)
  end

  it 'receives messages in real-time' do
    visit room_path(room)

    # Simulate another user sending a message
    ChatChannel.broadcast_to(
      room,
      action: 'new_message',
      message: { text: 'Hello from test!', user: { name: 'Test User' } }
    )

    # Verify message appears
    expect(page).to have_content('Hello from test!')
  end
end
```

## Performance Optimization

### 1. Filter Broadcast Data

```ruby
# WRONG - Broadcasting full objects
ActionCable.server.broadcast(
  "posts",
  post: @post  # Serializes entire object with all attributes!
)

# CORRECT - Only broadcast what's needed
ActionCable.server.broadcast(
  "posts",
  post: @post.as_json(only: [:id, :title, :updated_at])
)
```

### 2. Use Redis Adapter in Production

```yaml
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: myapp_production
```

### 3. Batch Broadcasts

```ruby
# WRONG - N broadcasts in loop
posts.each do |post|
  ActionCable.server.broadcast("posts", post: post)
end

# CORRECT - Single broadcast with batch
ActionCable.server.broadcast(
  "posts",
  action: 'batch_update',
  posts: posts.as_json(only: [:id, :title])
)
```

## Common Pitfalls

### 1. Missing Authorization

```ruby
# WRONG - No authorization check
def subscribed
  stream_from "admin_channel"  # Anyone can subscribe!
end

# CORRECT - Explicit authorization
def subscribed
  reject unless current_user&.admin?
  stream_from "admin_channel"
end
```

### 2. Broadcasting Before Persistence

```ruby
# WRONG - Broadcast before save (transaction may rollback)
def create_post
  post = Post.new(params)
  ActionCable.server.broadcast("posts", post: post)  # Not saved yet!
  post.save!
end

# CORRECT - Use after_commit callback
class Post < ApplicationRecord
  after_create_commit { broadcast_creation }

  def broadcast_creation
    ActionCable.server.broadcast("posts", post: self)
  end
end
```

### 3. Memory Leaks from Subscriptions

```javascript
// WRONG - Creating new subscription on every render
function ChatComponent() {
  const subscription = consumer.subscriptions.create("ChatChannel", {
    received(data) { /* ... */ }
  })
  // Subscription never cleaned up!
}

// CORRECT - Cleanup on unmount
function ChatComponent() {
  useEffect(() => {
    const subscription = consumer.subscriptions.create("ChatChannel", {
      received(data) { /* ... */ }
    })

    return () => subscription.unsubscribe()  // Cleanup
  }, [])
}
```

## Production Deployment

### Nginx Configuration

```nginx
# nginx.conf
upstream cable {
  server localhost:28080;
}

map $http_upgrade $connection_upgrade {
  default upgrade;
  '' close;
}

server {
  location /cable {
    proxy_pass http://cable;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
  }
}
```

### Environment Variables

```ruby
# config/environments/production.rb
config.action_cable.url = ENV.fetch('ACTION_CABLE_URL') { 'wss://example.com/cable' }
config.action_cable.allowed_request_origins = [
  'https://example.com',
  'https://www.example.com'
]

# Mount Action Cable on separate server (recommended)
config.action_cable.mount_path = nil  # Don't mount in main app
```

## Anti-Patterns to Avoid

**❌ NEVER:**
- Skip authorization in `subscribed`
- Broadcast before database commit
- Send sensitive data without filtering
- Use Action Cable for HTTP request/response patterns
- Create subscriptions without cleanup
- Broadcast large objects (>1KB)
- Use channels for batch processing

**✅ INSTEAD:**
- Always use `reject unless` for authorization
- Use `after_commit` callbacks for broadcasts
- Filter data with `as_json(only: [...])`
- Use regular HTTP endpoints for request/response
- Always unsubscribe on component unmount
- Only broadcast IDs and essential fields
- Use Sidekiq jobs for batch processing

## Key Takeaways

1. **Authorization is mandatory** - Always reject unauthorized users
2. **Persist first, broadcast second** - Don't rely on broadcasts alone
3. **Use `stream_for` for models** - Type-safe, conventional broadcasting
4. **Filter broadcast data** - Only send what clients need
5. **Test authorization thoroughly** - Security vulnerabilities are common
6. **Clean up subscriptions** - Prevent memory leaks on client
7. **Use Redis in production** - Required for multi-process deployments
