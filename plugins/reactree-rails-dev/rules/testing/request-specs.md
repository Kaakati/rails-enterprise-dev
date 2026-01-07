---
paths: spec/requests/**/*_spec.rb
---

# Request Spec Patterns

Apply to all files in `spec/requests/**/*_spec.rb`

## Purpose

Request specs test the HTTP layer - routes, controllers, responses, and integration with middleware.

## Standard Structure

```ruby
# spec/requests/posts_spec.rb
RSpec.describe "Posts API", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.token}" } }
  let(:json_response) { JSON.parse(response.body) }

  describe "GET /api/v1/posts" do
    it "returns posts" do
      create_list(:post, 3, published: true)

      get "/api/v1/posts", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response["data"].size).to eq(3)
    end

    it "paginates results" do
      create_list(:post, 30, published: true)

      get "/api/v1/posts", params: { page: 2, per_page: 10 }, headers: headers

      expect(json_response["data"].size).to eq(10)
      expect(json_response["meta"]["current_page"]).to eq(2)
    end
  end

  describe "POST /api/v1/posts" do
    context "with valid params" do
      let(:valid_params) { { post: { title: "New Post", body: "Content" } } }

      it "creates a post" do
        expect {
          post "/api/v1/posts", params: valid_params, headers: headers
        }.to change(Post, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { post: { title: "" } } }

      it "returns validation errors" do
        post "/api/v1/posts", params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("title")
      end
    end
  end

  describe "DELETE /api/v1/posts/:id" do
    let(:post_record) { create(:post, user: user) }

    it "deletes the post" do
      expect {
        delete "/api/v1/posts/#{post_record.id}", headers: headers
      }.to change(Post, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
```

## Test All HTTP Methods

**Standard REST endpoints:**
- `GET /resources` (index)
- `GET /resources/:id` (show)
- `POST /resources` (create)
- `PATCH/PUT /resources/:id` (update)
- `DELETE /resources/:id` (destroy)

## Authentication Testing

```ruby
describe "authentication" do
  context "without authentication" do
    it "returns unauthorized" do
      get "/api/v1/posts"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with invalid token" do
    let(:headers) { { "Authorization" => "Bearer invalid_token" } }

    it "returns unauthorized" do
      get "/api/v1/posts", headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with valid token" do
    it "returns success" do
      get "/api/v1/posts", headers: headers

      expect(response).to have_http_status(:ok)
    end
  end
end
```

## Authorization Testing

```ruby
describe "authorization" do
  let(:other_user) { create(:user) }
  let(:post_record) { create(:post, user: other_user) }

  it "prevents users from modifying others' posts" do
    patch "/api/v1/posts/#{post_record.id}",
          params: { post: { title: "Hacked" } },
          headers: headers

    expect(response).to have_http_status(:forbidden)
  end
end
```

## Anti-Patterns

**❌ NEVER:**
- Test controller implementation details (use system specs)
- Skip authentication/authorization tests
- Hardcode response values

**✅ INSTEAD:**
- Test HTTP layer (status codes, responses)
- Test all auth scenarios
- Use factories and dynamic data
