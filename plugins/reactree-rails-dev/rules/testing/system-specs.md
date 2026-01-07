---
paths: spec/system/**/*_spec.rb
---

# System Spec Patterns

Apply to all files in `spec/system/**/*_spec.rb`

## Purpose

System specs test the application from the user's perspective using a real browser (Selenium/Cupybara).

## Standard Structure

```ruby
# spec/system/posts_spec.rb
RSpec.describe "Posts", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  describe "creating a post" do
    it "allows user to create a post" do
      visit new_post_path

      fill_in "Title", with: "My First Post"
      fill_in "Body", with: "Post content here"
      click_button "Create Post"

      expect(page).to have_text("Post was successfully created")
      expect(page).to have_text("My First Post")
    end
  end

  describe "editing a post" do
    let!(:post) { create(:post, user: user) }

    it "allows user to edit their post" do
      visit edit_post_path(post)

      fill_in "Title", with: "Updated Title"
      click_button "Update Post"

      expect(page).to have_text("Post was successfully updated")
      expect(page).to have_text("Updated Title")
    end
  end
end
```

## Capybara Helpers

**Navigation:**
- `visit "/path"` - Navigate to URL
- `click_link "Link Text"` - Click link
- `click_button "Button Text"` - Click button

**Forms:**
- `fill_in "Field Label", with: "value"` - Fill text field
- `select "Option", from: "Select Label"` - Select dropdown
- `check "Checkbox Label"` - Check checkbox
- `uncheck "Checkbox Label"` - Uncheck checkbox
- `choose "Radio Label"` - Choose radio button

**Assertions:**
- `expect(page).to have_text("text")` - Text present
- `expect(page).to have_css(".class")` - CSS selector present
- `expect(page).to have_current_path("/path")` - URL check

## Anti-Patterns

**❌ NEVER:**
- Use system specs for non-user-facing features
- Test every edge case (use request/model specs)
- Skip JavaScript testing

**✅ INSTEAD:**
- Focus on critical user journeys
- Test happy paths and major errors
- Use `:selenium_chrome_headless` for JS features
