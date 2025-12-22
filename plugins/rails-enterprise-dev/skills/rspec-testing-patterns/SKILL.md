---
name: "RSpec Testing Patterns"
description: "Complete guide to testing Ruby on Rails applications with RSpec. Use this skill when writing unit tests, integration tests, system tests, or when setting up test infrastructure including factories, shared examples, and mocking strategies."
---

# RSpec Testing Patterns Skill

This skill provides comprehensive guidance for testing Rails applications with RSpec.

## When to Use This Skill

- Writing new specs (unit, integration, system)
- Setting up test factories
- Creating shared examples
- Mocking external services
- Testing ViewComponents
- Testing background jobs

## Directory Structure

```
spec/
├── rails_helper.rb
├── spec_helper.rb
├── support/
│   ├── factory_bot.rb
│   ├── database_cleaner.rb
│   ├── shared_contexts/
│   └── shared_examples/
├── factories/
│   ├── tasks.rb
│   ├── users.rb
│   └── ...
├── models/
├── services/
├── controllers/
├── requests/
├── system/
├── components/
└── jobs/
```

## Basic Spec Structure

```ruby
# spec/models/task_spec.rb
require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:merchant) }
    it { is_expected.to have_many(:timelines) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Task::STATUSES) }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:pending_task) { create(:task, status: 'pending') }
      let!(:completed_task) { create(:task, status: 'completed') }

      it 'returns only non-completed tasks' do
        expect(Task.active).to include(pending_task)
        expect(Task.active).not_to include(completed_task)
      end
    end
  end

  describe '#completable?' do
    context 'when task is pending' do
      let(:task) { build(:task, status: 'pending') }

      it 'returns true' do
        expect(task.completable?).to be true
      end
    end

    context 'when task is completed' do
      let(:task) { build(:task, status: 'completed') }

      it 'returns false' do
        expect(task.completable?).to be false
      end
    end
  end
end
```

## Factories (FactoryBot)

### Basic Factory

```ruby
# spec/factories/tasks.rb
FactoryBot.define do
  factory :task do
    account
    merchant
    recipient

    sequence(:tracking_number) { |n| "TRK#{n.to_s.rjust(8, '0')}" }
    status { 'pending' }
    description { Faker::Lorem.sentence }
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }

    # Traits
    trait :completed do
      status { 'completed' }
      completed_at { Time.current }
      carrier
    end

    trait :with_carrier do
      carrier
    end

    trait :express do
      task_type { 'express' }
    end

    trait :next_day do
      task_type { 'next_day' }
    end

    trait :with_photos do
      after(:create) do |task|
        create_list(:photo, 2, task: task)
      end
    end

    # Callbacks
    after(:create) do |task|
      task.timelines.create!(status: task.status, created_at: task.created_at)
    end
  end
end
```

### Factory with Associations

```ruby
# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
    subdomain { name.parameterize }
    active { true }
  end
end

# spec/factories/merchants.rb
FactoryBot.define do
  factory :merchant do
    account
    sequence(:name) { |n| "Merchant #{n}" }
    email { Faker::Internet.email }

    trait :with_branches do
      after(:create) do |merchant|
        create_list(:branch, 2, merchant: merchant)
      end
    end
  end
end
```

### Transient Attributes

```ruby
FactoryBot.define do
  factory :bundle do
    account
    carrier

    transient do
      task_count { 5 }
    end

    after(:create) do |bundle, evaluator|
      create_list(:task, evaluator.task_count, bundle: bundle, account: bundle.account)
    end
  end
end

# Usage
create(:bundle, task_count: 10)
```

## Service Specs

```ruby
# spec/services/tasks_manager/create_task_spec.rb
require 'rails_helper'

RSpec.describe TasksManager::CreateTask do
  let(:account) { create(:account) }
  let(:merchant) { create(:merchant, account: account) }
  let(:recipient) { create(:recipient, account: account) }

  let(:valid_params) do
    {
      recipient_id: recipient.id,
      description: "Test delivery",
      amount: 100.00,
      address: "123 Test St"
    }
  end

  describe '.call' do
    subject(:service_call) do
      described_class.call(
        account: account,
        merchant: merchant,
        params: valid_params
      )
    end

    context 'with valid params' do
      it 'creates a task' do
        expect { service_call }.to change(Task, :count).by(1)
      end

      it 'returns the created task' do
        expect(service_call).to be_a(Task)
        expect(service_call).to be_persisted
      end

      it 'associates with correct account' do
        expect(service_call.account).to eq(account)
      end

      it 'schedules notification job' do
        expect { service_call }
          .to have_enqueued_job(TaskNotificationJob)
                .with(kind_of(Integer))
      end
    end

    context 'with invalid params' do
      context 'when recipient is missing' do
        let(:valid_params) { super().except(:recipient_id) }

        it 'raises ArgumentError' do
          expect { service_call }.to raise_error(ArgumentError, /Recipient required/)
        end
      end

      context 'when address is missing' do
        let(:valid_params) { super().except(:address) }

        it 'raises ArgumentError' do
          expect { service_call }.to raise_error(ArgumentError, /Address required/)
        end
      end
    end

    context 'with service result pattern' do
      # For services returning ServiceResult
      subject(:result) { described_class.call(...) }

      context 'on success' do
        it 'returns success result' do
          expect(result).to be_success
        end

        it 'includes the task in data' do
          expect(result.data).to be_a(Task)
        end
      end

      context 'on failure' do
        it 'returns failure result' do
          expect(result).to be_failure
        end

        it 'includes error message' do
          expect(result.error).to eq("Expected error message")
        end
      end
    end
  end
end
```

## Request Specs

```ruby
# spec/requests/api/v1/tasks_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/tasks" do
    let!(:tasks) { create_list(:task, 3, account: account) }
    let!(:other_task) { create(:task) }  # Different account

    before { get api_v1_tasks_path, headers: headers }

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end

    it "returns tasks for current account only" do
      expect(json_response['data'].size).to eq(3)
    end

    it "does not include other account tasks" do
      ids = json_response['data'].pluck('id')
      expect(ids).not_to include(other_task.id)
    end
  end

  describe "POST /api/v1/tasks" do
    let(:merchant) { create(:merchant, account: account) }
    let(:recipient) { create(:recipient, account: account) }

    let(:valid_params) do
      {
        task: {
          merchant_id: merchant.id,
          recipient_id: recipient.id,
          description: "New task",
          amount: 50.00
        }
      }
    end

    context "with valid params" do
      it "creates a task" do
        expect {
          post api_v1_tasks_path, params: valid_params, headers: headers
        }.to change(Task, :count).by(1)
      end

      it "returns created status" do
        post api_v1_tasks_path, params: valid_params, headers: headers
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { task: { description: "" } } }

      it "returns unprocessable entity" do
        post api_v1_tasks_path, params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns errors" do
        post api_v1_tasks_path, params: invalid_params, headers: headers
        expect(json_response['errors']).to be_present
      end
    end
  end

  # Helper for JSON response
  def json_response
    JSON.parse(response.body)
  end
end
```

## ViewComponent Specs

```ruby
# spec/components/metrics/kpi_card_component_spec.rb
require 'rails_helper'

RSpec.describe Metrics::KpiCardComponent, type: :component do
  let(:title) { "Total Orders" }
  let(:value) { 1234 }

  subject(:component) do
    described_class.new(title: title, value: value)
  end

  describe "#render" do
    before { render_inline(component) }

    it "renders the title" do
      expect(page).to have_css("h3", text: title)
    end

    it "renders the value" do
      expect(page).to have_text("1,234")
    end
  end

  describe "#formatted_value" do
    it "formats large numbers with delimiter" do
      component = described_class.new(title: "Test", value: 1234567)
      expect(component.formatted_value).to eq("1,234,567")
    end
  end

  context "with trend" do
    let(:component) do
      described_class.new(title: title, value: value, trend: :up)
    end

    before { render_inline(component) }

    it "shows trend indicator" do
      expect(page).to have_css(".text-green-500")
    end
  end

  context "with content block" do
    before do
      render_inline(component) do
        "Additional content"
      end
    end

    it "renders the block content" do
      expect(page).to have_text("Additional content")
    end
  end
end
```

## System Specs (Capybara)

```ruby
# spec/system/tasks_spec.rb
require 'rails_helper'

RSpec.describe "Tasks", type: :system do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before do
    sign_in(user)
  end

  describe "viewing tasks" do
    let!(:tasks) { create_list(:task, 5, account: account) }

    it "displays all tasks" do
      visit tasks_path

      tasks.each do |task|
        expect(page).to have_content(task.tracking_number)
      end
    end
  end

  describe "creating a task" do
    let!(:merchant) { create(:merchant, account: account) }
    let!(:recipient) { create(:recipient, account: account) }

    it "creates a new task" do
      visit new_task_path

      select merchant.name, from: "Merchant"
      select recipient.name, from: "Recipient"
      fill_in "Description", with: "Test delivery"
      fill_in "Amount", with: "100.00"

      click_button "Create Task"

      expect(page).to have_content("Task created successfully")
      expect(page).to have_content("Test delivery")
    end
  end

  describe "with Turbo" do
    it "updates task status via Turbo Stream" do
      task = create(:task, account: account, status: 'pending')

      visit tasks_path

      within("#task_#{task.id}") do
        click_button "Start"
      end

      # Wait for Turbo Stream update
      expect(page).to have_css("#task_#{task.id} .status", text: "In Progress")
    end
  end
end
```

## Job Specs

```ruby
# spec/jobs/task_notification_job_spec.rb
require 'rails_helper'

RSpec.describe TaskNotificationJob, type: :job do
  let(:task) { create(:task) }

  describe "#perform" do
    it "sends SMS notification" do
      expect(SmsService).to receive(:send).with(
        to: task.recipient.phone,
        message: include(task.tracking_number)
      )

      described_class.perform_now(task.id)
    end

    context "when task doesn't exist" do
      it "handles gracefully" do
        expect { described_class.perform_now(0) }.not_to raise_error
      end
    end
  end

  describe "enqueuing" do
    it "enqueues in correct queue" do
      expect {
        described_class.perform_later(task.id)
      }.to have_enqueued_job.on_queue("notifications")
    end
  end
end
```

## Shared Examples

```ruby
# spec/support/shared_examples/tenant_scoped.rb
RSpec.shared_examples "tenant scoped" do
  describe "tenant scoping" do
    let(:account) { create(:account) }
    let(:other_account) { create(:account) }

    let!(:scoped_record) { create(described_class.model_name.singular, account: account) }
    let!(:other_record) { create(described_class.model_name.singular, account: other_account) }

    it "scopes to current account" do
      Current.account = account
      expect(described_class.all).to include(scoped_record)
      expect(described_class.all).not_to include(other_record)
    end
  end
end

# Usage
RSpec.describe Task do
  it_behaves_like "tenant scoped"
end
```

```ruby
# spec/support/shared_examples/api_authentication.rb
RSpec.shared_examples "requires authentication" do
  context "without authentication" do
    let(:headers) { {} }

    it "returns unauthorized" do
      make_request
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

# Usage
RSpec.describe "Api::V1::Tasks" do
  describe "GET /api/v1/tasks" do
    it_behaves_like "requires authentication" do
      let(:make_request) { get api_v1_tasks_path, headers: headers }
    end
  end
end
```

## Shared Contexts

```ruby
# spec/support/shared_contexts/authenticated_user.rb
RSpec.shared_context "authenticated user" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before do
    sign_in(user)
    Current.account = account
  end
end

# Usage
RSpec.describe TasksController do
  include_context "authenticated user"

  # tests with authenticated user...
end
```

## Mocking External Services

```ruby
# spec/support/webmock_helpers.rb
module WebmockHelpers
  def stub_shipping_api_success
    stub_request(:post, "https://shipping.example.com/api/labels")
      .to_return(
        status: 200,
        body: { tracking_number: "SHIP123", label_url: "https://..." }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_shipping_api_failure
    stub_request(:post, "https://shipping.example.com/api/labels")
      .to_return(status: 500, body: { error: "Server error" }.to_json)
  end
end

RSpec.configure do |config|
  config.include WebmockHelpers
end

# Usage in spec
describe "creating shipping label" do
  before { stub_shipping_api_success }

  it "creates label successfully" do
    # test...
  end
end
```

## Test Helpers

```ruby
# spec/support/helpers/auth_helpers.rb
module AuthHelpers
  def auth_headers(user)
    token = user.generate_jwt_token
    { 'Authorization' => "Bearer #{token}" }
  end

  def sign_in(user)
    login_as(user, scope: :user)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :system
end
```

## Configuration

```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("Running in production!") if Rails.env.production?

require 'rspec/rails'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_path = Rails.root.join('spec/fixtures')
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Shoulda matchers
  Shoulda::Matchers.configure do |shoulda_config|
    shoulda_config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end
```
