---
paths: app/controllers/**/*.rb
---

# Rails Controller Conventions

Apply to all files in `app/controllers/**/*.rb`

## RESTful Actions Only

**Standard REST Actions:**
- `index` - List collection
- `show` - Display single resource
- `new` - Display form for creating resource
- `create` - Create new resource
- `edit` - Display form for updating resource
- `update` - Update existing resource
- `destroy` - Delete resource

**Custom Actions:**
- Custom actions →  Use services or create separate specialized controllers
- Example: Instead of `PostsController#publish`, create `Post::PublicationsController#create`

## Controller Structure

**Standard Controller Template:**

```ruby
class PostsController < ApplicationController
  # == Filters ==============================================================
  before_action :authenticate_user!
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post, only: [:edit, :update, :destroy]

  # == Actions ==============================================================

  # GET /posts
  def index
    @posts = Post.published
                 .page(params[:page])
                 .per(params[:per_page] || 25)
  end

  # GET /posts/:id
  def show
    # @post set by before_action
  end

  # GET /posts/new
  def new
    @post = current_user.posts.build
  end

  # POST /posts
  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /posts/:id/edit
  def edit
    # @post set by before_action
  end

  # PATCH/PUT /posts/:id
  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/:id
  def destroy
    @post.destroy
    redirect_to posts_url, notice: "Post was successfully destroyed."
  end

  # == Private ==============================================================
  private

  def set_post
    @post = current_user.posts.find(params[:id])
  end

  def authorize_post
    redirect_to root_path, alert: "Not authorized" unless @post.owned_by?(current_user)
  end

  def post_params
    params.require(:post).permit(:title, :body, :published, :category_id)
  end
end
```

## Strong Parameters

**Always use strong parameters** to prevent mass assignment vulnerabilities:

```ruby
# Basic
def post_params
  params.require(:post).permit(:title, :body, :published)
end

# Nested attributes
def post_params
  params.require(:post).permit(
    :title,
    :body,
    :published,
    author_attributes: [:name, :email],
    tag_ids: []
  )
end

# Arrays and hashes
def post_params
  params.require(:post).permit(
    :title,
    tags: [],                      # Array
    metadata: {}                   # Hash (permits all keys)
  )
end

# Conditional permissions
def post_params
  permitted = [:title, :body]
  permitted << :published if current_user.admin?
  params.require(:post).permit(permitted)
end
```

**❌ NEVER permit all parameters:**
```ruby
# WRONG: Security vulnerability
params.require(:post).permit!
```

## Response Formats

**HTML Responses:**
```ruby
def create
  if @post.save
    redirect_to @post, notice: "Success"
  else
    render :new, status: :unprocessable_entity  # Must include status for Turbo
  end
end
```

**JSON API Responses:**
```ruby
def create
  @post = Post.new(post_params)

  if @post.save
    render json: @post, status: :created, location: @post
  else
    render json: { errors: @post.errors }, status: :unprocessable_entity
  end
end
```

**Turbo Stream Responses:**
```ruby
def create
  @post = Post.new(post_params)

  respond_to do |format|
    if @post.save
      format.turbo_stream  # renders create.turbo_stream.erb
      format.html { redirect_to @post, notice: "Success" }
    else
      format.turbo_stream { render :form_update, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

## Before Actions

**Common before_action patterns:**

```ruby
# Authentication
before_action :authenticate_user!

# Set resource (DRY principle)
before_action :set_post, only: [:show, :edit, :update, :destroy]

# Authorization
before_action :authorize_post, only: [:edit, :update, :destroy]

# Pagination defaults
before_action :set_pagination_params, only: [:index]

# Scoping to tenant
before_action :scope_to_account
```

**Skip actions for specific endpoints:**
```ruby
skip_before_action :verify_authenticity_token, only: [:webhook]
skip_before_action :authenticate_user!, only: [:index, :show]
```

## Delegation to Services

**Complex operations should use Service Objects:**

```ruby
# ❌ BAD: Complex logic in controller
def create
  @order = Order.new(order_params)
  @order.calculate_total
  @order.apply_discount(params[:coupon_code])
  @order.charge_payment(params[:payment_token])
  @order.send_confirmation_email

  if @order.save
    # ...
  end
end

# ✅ GOOD: Delegate to service
def create
  result = Orders::CreateService.new(
    user: current_user,
    params: order_params,
    coupon_code: params[:coupon_code],
    payment_token: params[:payment_token]
  ).call

  if result.success?
    redirect_to result.order, notice: "Order created!"
  else
    @order = result.order
    flash.now[:alert] = result.error
    render :new, status: :unprocessable_entity
  end
end
```

## Concerns

**Extract shared controller behavior to concerns:**

```ruby
# app/controllers/concerns/paginatable.rb
module Paginatable
  extend ActiveSupport::Concern

  included do
    before_action :set_pagination_params
  end

  private

  def set_pagination_params
    @page = params[:page] || 1
    @per_page = params[:per_page] || 25
  end
end

# Usage
class PostsController < ApplicationController
  include Paginatable

  def index
    @posts = Post.page(@page).per(@per_page)
  end
end
```

## API Controllers

**Use API base controller for API endpoints:**

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :authenticate

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

    private

    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        @current_user = User.find_by(api_token: token)
      end
    end

    def not_found
      render json: { error: "Not found" }, status: :not_found
    end

    def unprocessable_entity(exception)
      render json: { errors: exception.record.errors }, status: :unprocessable_entity
    end
  end
end

# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < Api::BaseController
      def index
        @posts = Post.all
        render json: @posts
      end
    end
  end
end
```

## Error Handling

**Use rescue_from for common errors:**

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized

  private

  def not_found
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/404.html", status: :not_found }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  def bad_request
    render json: { error: "Bad request" }, status: :bad_request
  end

  def unauthorized
    redirect_to root_path, alert: "You are not authorized to perform this action."
  end
end
```

## Flash Messages

**Use appropriate flash keys:**

```ruby
# Success
redirect_to @post, notice: "Post created successfully"
flash[:notice] = "Post created successfully"

# Error
redirect_to posts_path, alert: "Failed to create post"
flash[:alert] = "Failed to create post"

# Info
flash[:info] = "Processing your request..."

# Using flash.now (doesn't persist to next request)
flash.now[:alert] = "Invalid form submission"
render :new, status: :unprocessable_entity
```

## Anti-Patterns

**❌ NEVER:**
- Create fat controllers (>100 lines = extract to services/concerns)
- Put business logic in controllers (use Service Objects)
- Expose multiple instance variables to views (use presenters)
- Skip strong parameters (security risk)
- Use `params.permit!` (allows all parameters - security risk)
- Create custom actions when RESTful routing works (use nested resources)
- Query the database directly in views (preload in controller)
- Use instance variables in before_actions (return values or use private methods)

**✅ INSTEAD:**
- Skinny controllers (<100 lines)
- Service Objects for business logic
- Single instance variable or presenter pattern
- Strong parameters with explicit allow-lists
- Nested RESTful resources for related actions
- Eager loading in controller: `@posts = Post.includes(:author, :comments)`
- Private methods that return values

## Example: Namespaced Admin Controller

```ruby
# app/controllers/admin/posts_controller.rb
module Admin
  class PostsController < Admin::BaseController
    before_action :set_post, only: [:edit, :update, :destroy, :publish]

    def index
      @posts = Post.includes(:author)
                   .order(created_at: :desc)
                   .page(params[:page])
    end

    def publish
      if @post.publish!
        redirect_to [:admin, @post], notice: "Post published"
      else
        redirect_to [:admin, @post], alert: "Failed to publish post"
      end
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :body, :published, :featured)
    end
  end
end
```

## Testing Controllers

Controllers should be tested with **request specs** (not controller specs):

```ruby
# spec/requests/posts_spec.rb
RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.token}" } }

  describe "GET /posts" do
    it "returns posts" do
      create_list(:post, 3)

      get "/posts", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("posts")
    end
  end
end
```
