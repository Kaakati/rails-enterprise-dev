---
paths: spec/models/**/*_spec.rb
---

# Model Spec Patterns

Apply to all files in `spec/models/**/*_spec.rb`

## Standard Model Spec Structure

**Organize specs in this order:**

1. **Associations** - Test all `belongs_to`, `has_many`, `has_one` relationships
2. **Validations** - Test all `validates` declarations
3. **Enums** - Test enum values and methods
4. **Scopes** - Test all named scopes
5. **Callbacks** - Test callback behavior
6. **Class methods** - Test `self.method_name` methods
7. **Instance methods** - Test public instance methods

## Complete Model Spec Template

```ruby
# spec/models/task_spec.rb
RSpec.describe Task, type: :model do
  # == Associations =========================================================
  describe 'associations' do
    it { should belong_to(:account) }
    it { should belong_to(:merchant) }
    it { should belong_to(:carrier).optional }
    it { should belong_to(:recipient) }
    it { should belong_to(:zone).optional }

    it { should have_many(:timelines).dependent(:destroy) }
    it { should have_many(:task_actions).dependent(:destroy) }
    it { should have_many(:photos).dependent(:destroy) }
  end

  # == Validations ==========================================================
  describe 'validations' do
    subject { build(:task) }  # Use build for validation tests (doesn't save)

    it { should validate_presence_of(:tracking_number) }
    it { should validate_presence_of(:status) }
    it { should validate_uniqueness_of(:tracking_number).scoped_to(:account_id) }
  end

  # == Enums ================================================================
  describe 'enums' do
    it {
      should define_enum_for(:status)
        .with_values(pending: 0, in_progress: 1, completed: 2, failed: 3, cancelled: 4)
        .with_prefix(true)
    }

    describe 'enum methods' do
      let(:task) { create(:task, status: :pending) }

      it 'generates predicate methods' do
        expect(task.pending_status?).to be true
        expect(task.completed_status?).to be false
      end

      it 'generates bang methods' do
        task.completed_status!
        expect(task.reload.status).to eq('completed')
      end

      it 'generates scopes' do
        pending_task = create(:task, status: :pending)
        completed_task = create(:task, status: :completed)

        expect(Task.pending_status).to include(pending_task)
        expect(Task.pending_status).not_to include(completed_task)
      end
    end
  end

  # == Scopes ===============================================================
  describe 'scopes' do
    describe '.active' do
      it 'returns tasks that are not completed, failed, or cancelled' do
        active_task = create(:task, status: :pending)
        completed_task = create(:task, status: :completed)
        failed_task = create(:task, status: :failed)

        expect(Task.active).to include(active_task)
        expect(Task.active).not_to include(completed_task, failed_task)
      end
    end

    describe '.for_carrier' do
      it 'returns tasks for the specified carrier' do
        carrier = create(:carrier)
        carrier_task = create(:task, carrier: carrier)
        other_task = create(:task, carrier: create(:carrier))

        expect(Task.for_carrier(carrier)).to include(carrier_task)
        expect(Task.for_carrier(carrier)).not_to include(other_task)
      end
    end

    describe '.created_between' do
      it 'returns tasks created within the date range' do
        old_task = create(:task, created_at: 10.days.ago)
        recent_task = create(:task, created_at: 3.days.ago)

        result = Task.created_between(5.days.ago, 1.day.ago)

        expect(result).to include(recent_task)
        expect(result).not_to include(old_task)
      end
    end
  end

  # == Callbacks ============================================================
  describe 'callbacks' do
    describe 'before_validation :generate_tracking_number' do
      it 'generates tracking number on create' do
        task = build(:task, tracking_number: nil)
        task.valid?
        expect(task.tracking_number).to be_present
      end

      it 'does not override existing tracking number' do
        task = build(:task, tracking_number: 'EXISTING123')
        task.valid?
        expect(task.tracking_number).to eq('EXISTING123')
      end
    end

    describe 'after_commit :notify_recipient' do
      it 'enqueues notification job after create' do
        expect {
          create(:task)
        }.to have_enqueued_job(TaskNotificationJob)
      end
    end
  end

  # == Class Methods ========================================================
  describe '.search' do
    it 'finds tasks by tracking number' do
      task = create(:task, tracking_number: 'ABC123')
      expect(Task.search('ABC')).to include(task)
    end

    it 'finds tasks by description' do
      task = create(:task, description: 'Deliver package')
      expect(Task.search('package')).to include(task)
    end

    it 'is case-insensitive' do
      task = create(:task, tracking_number: 'ABC123')
      expect(Task.search('abc')).to include(task)
    end
  end

  # == Instance Methods =====================================================
  describe '#completable?' do
    it 'returns true for pending tasks' do
      task = create(:task, status: :pending)
      expect(task.completable?).to be true
    end

    it 'returns true for in_progress tasks' do
      task = create(:task, status: :in_progress)
      expect(task.completable?).to be true
    end

    it 'returns false for completed tasks' do
      task = create(:task, status: :completed)
      expect(task.completable?).to be false
    end
  end

  describe '#complete!' do
    let(:task) { create(:task, status: :pending) }

    it 'sets status to completed' do
      task.complete!
      expect(task.reload.status).to eq('completed')
    end

    it 'sets completed_at timestamp' do
      freeze_time do
        task.complete!
        expect(task.reload.completed_at).to be_within(1.second).of(Time.current)
      end
    end
  end
end
```

## Shoulda Matchers

**Use shoulda-matchers for concise association and validation tests:**

### Association Matchers

```ruby
# belongs_to
it { should belong_to(:account) }
it { should belong_to(:carrier).optional }  # Rails 5+ optional
it { should belong_to(:merchant).counter_cache(true) }
it { should belong_to(:bundle).touch(true) }

# has_many
it { should have_many(:timelines) }
it { should have_many(:timelines).dependent(:destroy) }
it { should have_many(:photos).through(:timeline) }
it { should have_many(:active_photos).class_name('Photo') }

# has_one
it { should have_one(:profile).dependent(:destroy) }

# has_and_belongs_to_many
it { should have_and_belong_to_many(:tags) }
```

### Validation Matchers

```ruby
# Presence
it { should validate_presence_of(:email) }

# Uniqueness
it { should validate_uniqueness_of(:email) }
it { should validate_uniqueness_of(:tracking_number).scoped_to(:account_id) }
it { should validate_uniqueness_of(:email).case_insensitive }

# Length
it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }
it { should validate_length_of(:password).is_at_least(8) }

# Numericality
it { should validate_numericality_of(:age).is_greater_than(0) }
it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
it { should validate_numericality_of(:quantity).only_integer }

# Inclusion
it { should validate_inclusion_of(:status).in_array(%w[pending active completed]) }

# Format
it { should allow_value('test@example.com').for(:email) }
it { should_not allow_value('invalid').for(:email) }

# Custom validations
it { should validate_acceptance_of(:terms_of_service) }
it { should validate_confirmation_of(:password) }
```

### Enum Matchers

```ruby
it {
  should define_enum_for(:status)
    .with_values(pending: 0, active: 1, completed: 2)
}

it {
  should define_enum_for(:status)
    .with_values(pending: 0, active: 1)
    .with_prefix(true)
    .with_suffix(false)
}
```

## Factory Usage

**Use FactoryBot factories for test data:**

```ruby
# spec/factories/tasks.rb
FactoryBot.define do
  factory :task do
    association :account
    association :merchant
    association :recipient

    tracking_number { SecureRandom.hex(8).upcase }
    description { Faker::Lorem.sentence }
    status { :pending }

    trait :in_progress do
      status { :in_progress }
    end

    trait :completed do
      status { :completed }
      completed_at { Time.current }
    end

    trait :with_photos do
      after(:create) do |task|
        create_list(:photo, 3, task: task)
      end
    end
  end
end

# Usage in specs
describe Task do
  let(:task) { create(:task) }
  let(:completed_task) { create(:task, :completed) }
  let(:task_with_photos) { create(:task, :with_photos) }
end
```

## Testing Database Constraints

```ruby
describe 'database constraints' do
  it 'enforces NOT NULL on status' do
    expect {
      Task.create!(tracking_number: 'TEST123', status: nil)
    }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it 'enforces uniqueness at database level' do
    create(:task, tracking_number: 'DUPLICATE', account_id: 1)

    expect {
      Task.create!(tracking_number: 'DUPLICATE', account_id: 1, status: :pending)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
```

## Testing Callbacks with Mocks

```ruby
describe 'callbacks' do
  describe 'after_create :send_notification' do
    it 'calls NotificationService' do
      task = build(:task)

      expect(NotificationService).to receive(:notify).with(task)

      task.save!
    end
  end

  describe 'before_destroy :archive_related_records' do
    it 'archives timelines before destroying task' do
      task = create(:task, :with_timelines)

      expect(task).to receive(:archive_related_records)

      task.destroy
    end
  end
end
```

## Coverage Requirements

**Models require 100% test coverage:**

- All associations
- All validations
- All enum values and generated methods
- All scopes
- All callbacks
- All class methods
- All public instance methods
- Edge cases and error conditions

**Use SimpleCov to track coverage:**

```ruby
# spec/spec_helper.rb
require 'simplecov'
SimpleCov.start 'rails' do
  minimum_coverage 100  # Enforce 100% for models
  minimum_coverage_by_file 80  # Allow some flexibility per file
end
```

## Anti-Patterns

**❌ NEVER:**
- Test private methods (test behavior through public interface)
- Use `save(validate: false)` in tests (bypasses validations you're testing)
- Create records when `build` would suffice (slower tests)
- Test Rails framework code (e.g., don't test that `belongs_to` works)
- Skip testing edge cases (nil values, empty strings, boundary conditions)
- Use `let!` when `let` would work (eager evaluation is slower)
- Hardcode IDs or timestamps (use factories and Timecop/freeze_time)

**✅ INSTEAD:**
- Test public methods only
- Always validate records in tests
- Use `build` for validation tests, `create` when persistence is needed
- Test your custom code, trust Rails associations work
- Include edge case tests
- Use lazy `let` by default, `let!` only when needed
- Use factories and time helpers

## Example: Complete Model Spec with All Patterns

```ruby
RSpec.describe Task, type: :model do
  subject(:task) { build(:task) }

  # Associations
  it { should belong_to(:account) }
  it { should have_many(:timelines).dependent(:destroy) }

  # Validations
  it { should validate_presence_of(:tracking_number) }
  it { should validate_uniqueness_of(:tracking_number).scoped_to(:account_id) }

  # Enums
  it { should define_enum_for(:status).with_values(pending: 0, in_progress: 1, completed: 2) }

  # Scopes
  describe '.active' do
    it 'excludes completed tasks' do
      active = create(:task, :in_progress)
      completed = create(:task, :completed)

      expect(Task.active).to include(active)
      expect(Task.active).not_to include(completed)
    end
  end

  # Instance methods
  describe '#completable?' do
    it 'returns true when status allows completion' do
      expect(build(:task, :pending).completable?).to be true
      expect(build(:task, :completed).completable?).to be false
    end
  end

  # Callbacks
  describe 'callbacks' do
    it 'generates tracking number before validation' do
      task = build(:task, tracking_number: nil)
      task.valid?
      expect(task.tracking_number).to match(/\A[A-F0-9]{16}\z/)
    end
  end

  # Edge cases
  describe 'edge cases' do
    it 'handles nil description gracefully' do
      task = create(:task, description: nil)
      expect(task.description).to be_nil
    end

    it 'prevents duplicate tracking numbers within same account' do
      create(:task, tracking_number: 'DUPLICATE', account: task.account)

      duplicate = build(:task, tracking_number: 'DUPLICATE', account: task.account)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tracking_number]).to include('has already been taken')
    end
  end
end
```
