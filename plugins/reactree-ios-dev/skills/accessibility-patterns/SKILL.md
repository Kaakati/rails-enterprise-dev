---
name: "Accessibility Patterns"
description: "Comprehensive accessibility implementation for iOS/tvOS including VoiceOver, Dynamic Type, and WCAG 2.1 Level AA compliance"
version: "2.0.0"
---

# Accessibility Patterns for iOS/tvOS

Complete guide to implementing accessible iOS/tvOS applications with VoiceOver support, Dynamic Type, color contrast compliance, and WCAG 2.1 Level AA standards.

## VoiceOver Support

### Accessibility Labels

```swift
// SwiftUI
struct ProfileView: View {
    let user: User

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .accessibilityLabel("Profile picture")

            Text(user.name)
                .accessibilityLabel("User name: \(user.name)")

            Button(action: { /* ... */ }) {
                Image(systemName: "envelope")
            }
            .accessibilityLabel("Send message to \(user.name)")
        }
    }
}

// UIKit
let imageView = UIImageView(image: UIImage(systemName: "person.circle.fill"))
imageView.isAccessibilityElement = true
imageView.accessibilityLabel = "Profile picture"

let button = UIButton()
button.accessibilityLabel = "Send message to \(user.name)"
```

### Accessibility Hints

```swift
// SwiftUI
Button("Submit") {
    submitForm()
}
.accessibilityLabel("Submit form")
.accessibilityHint("Double tap to submit the registration form")

// UIKit
button.accessibilityLabel = "Submit form"
button.accessibilityHint = "Double tap to submit the registration form"
```

### Accessibility Traits

```swift
// SwiftUI
struct CustomButton: View {
    let title: String
    let action: () -> Void
    let isSelected: Bool

    var body: some View {
        Button(title, action: action)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityRemoveTraits(.isImage)  // If button contains image
    }
}

// Common traits
Text("Breaking News")
    .accessibilityAddTraits(.isHeader)

Toggle("Notifications", isOn: $notificationsEnabled)
    .accessibilityAddTraits(.isToggle)  // Automatically applied

Image("banner")
    .accessibilityAddTraits(.isImage)

// UIKit
button.accessibilityTraits = .button
if isSelected {
    button.accessibilityTraits.insert(.selected)
}

headerLabel.accessibilityTraits = .header
```

### Grouping Elements

```swift
// SwiftUI - Group related elements
struct NewsCard: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.headline)

            Text(article.summary)
                .font(.body)

            Text(article.date, style: .date)
                .font(.caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title). \(article.summary). Published \(article.date.formatted())")
    }
}

// UIKit - Container groups
let containerView = UIView()
containerView.isAccessibilityElement = false
containerView.shouldGroupAccessibilityChildren = true
```

## Dynamic Type Support

### Scaling Text

```swift
// SwiftUI - Text automatically scales
Text("Hello, World!")
    .font(.body)  // Scales with Dynamic Type

Text("Fixed Size")
    .font(.system(size: 17))  // Does NOT scale

Text("Custom Scaling")
    .font(.system(size: 17, weight: .regular, design: .default))
    .dynamicTypeSize(.large)  // Limit scaling

// Limit text scaling range
Text("Constrained")
    .dynamicTypeSize(.medium ... .xxxLarge)

// UIKit
let label = UILabel()
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true

// Custom font with scaling
let customFont = UIFont(name: "CustomFont", size: 17)!
label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
```

### Layout Adaptat

ion

```swift
// SwiftUI - Adaptive layout based on text size
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var body: some View {
    if dynamicTypeSize >= .xxxLarge {
        VStack(alignment: .leading) {
            // Vertical layout for large text
            profileImage
            userInfo
        }
    } else {
        HStack {
            // Horizontal layout for normal text
            profileImage
            userInfo
        }
    }
}

// Listen to Dynamic Type changes in UIKit
NotificationCenter.default.addObserver(
    forName: UIContentSizeCategory.didChangeNotification,
    object: nil,
    queue: .main
) { _ in
    updateLayout()
}
```

## Color Contrast

### Meeting WCAG AA Standards

```swift
// WCAG AA requires:
// - Normal text (< 18pt): 4.5:1 contrast ratio
// - Large text (≥ 18pt or 14pt bold): 3:1 contrast ratio

extension Color {
    // Ensure sufficient contrast
    func contrastingTextColor() -> Color {
        // Calculate luminance and return black or white
        let luminance = self.luminance()
        return luminance > 0.5 ? .black : .white
    }

    private func luminance() -> Double {
        // Implement relative luminance calculation
        // Based on WCAG formula
        0.0  // Simplified
    }

    // Check if colors meet WCAG AA
    func meetsWCAGAA(with background: Color, fontSize: CGFloat, isBold: Bool) -> Bool {
        let requiredRatio: Double = (fontSize >= 18 || (fontSize >= 14 && isBold)) ? 3.0 : 4.5
        let actualRatio = self.contrastRatio(with: background)
        return actualRatio >= requiredRatio
    }
}

// Use high contrast when enabled
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var body: some View {
    VStack {
        Text("Content")
    }
    .background(reduceTransparency ? Color.black : Color.black.opacity(0.8))
}
```

### Accessibility-Aware Colors

```swift
// SwiftUI - Different colors for accessibility
extension Color {
    static let accessiblePrimary = Color("Primary", bundle: .main)

    static var adaptiveText: Color {
        Color.primary  // Automatically adjusts for dark mode and high contrast
    }
}

// Asset catalog with high contrast variants
// Colors.xcassets/Primary.colorset/Contents.json
{
  "colors": [
    {
      "idiom": "universal",
      "color": { "color-space": "srgb", "components": { "red": "0.0", "green": "0.478", "blue": "1.0" }}
    },
    {
      "idiom": "universal",
      "appearances": [{ "appearance": "luminosity", "value": "dark" }],
      "color": { "color-space": "srgb", "components": { "red": "0.039", "green": "0.518", "blue": "1.0" }}
    },
    {
      "idiom": "universal",
      "appearances": [{ "appearance": "contrast", "value": "high" }],
      "color": { "color-space": "srgb", "components": { "red": "0.0", "green": "0.0", "blue": "0.8" }}
    }
  ]
}
```

## Focus Management

### Custom Focus Order

```swift
// SwiftUI
struct FormView: View {
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email, password, confirmPassword
    }

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .focused($focusedField, equals: .email)
                .accessibilitySortPriority(3)

            SecureField("Password", text: $password)
                .focused($focusedField, equals: .password)
                .accessibilitySortPriority(2)

            SecureField("Confirm", text: $confirmPassword)
                .focused($focusedField, equals: .confirmPassword)
                .accessibilitySortPriority(1)
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                submitForm()
            default:
                break
            }
        }
    }
}

// UIKit
override var accessibilityElements: [Any]? {
    get { [emailField, passwordField, submitButton] }
    set { }
}
```

### Focus Notifications

```swift
// UIKit - Post focus notification
UIAccessibility.post(notification: .screenChanged, argument: errorLabel)

// Announce message without changing focus
UIAccessibility.post(notification: .announcement, argument: "Form submitted successfully")

// Layout changed (smaller change than screen changed)
UIAccessibility.post(notification: .layoutChanged, argument: newElement)

// SwiftUI
struct ContentView: View {
    @AccessibilityFocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Text("Important Message")
                .accessibilityFocused($isFocused)
                .onAppear {
                    // Set focus when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFocused = true
                    }
                }
        }
    }
}
```

## Custom Accessibility Actions

### Custom Actions

```swift
// SwiftUI
struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack {
            Text(message.content)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.content)
        .accessibilityAction(named: "Reply") {
            replyToMessage(message)
        }
        .accessibilityAction(named: "Delete") {
            deleteMessage(message)
        }
        .accessibilityAction(named: "Forward") {
            forwardMessage(message)
        }
    }
}

// UIKit
let replyAction = UIAccessibilityCustomAction(
    name: "Reply",
    target: self,
    selector: #selector(replyToMessage)
)

let deleteAction = UIAccessibilityCustomAction(
    name: "Delete",
    target: self,
    selector: #selector(deleteMessage)
)

cell.accessibilityCustomActions = [replyAction, deleteAction]
```

### Adjustable Values

```swift
// SwiftUI
struct VolumeControl: View {
    @State private var volume: Double = 0.5

    var body: some View {
        Slider(value: $volume, in: 0...1)
            .accessibilityLabel("Volume")
            .accessibilityValue("\(Int(volume * 100)) percent")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    volume = min(1.0, volume + 0.1)
                case .decrement:
                    volume = max(0.0, volume - 0.1)
                @unknown default:
                    break
                }
            }
    }
}

// UIKit
class VolumeView: UIView {
    var volume: Double = 0.5

    override var accessibilityTraits: UIAccessibilityTraits {
        get { .adjustable }
        set { }
    }

    override var accessibilityValue: String? {
        get { "\(Int(volume * 100)) percent" }
        set { }
    }

    override func accessibilityIncrement() {
        volume = min(1.0, volume + 0.1)
    }

    override func accessibilityDecrement() {
        volume = max(0.0, volume - 0.1)
    }
}
```

## Reduce Motion

### Respecting Reduce Motion

```swift
// SwiftUI
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    VStack {
        if reduceMotion {
            // Simplified animation or no animation
            Image("logo")
                .transition(.opacity)
        } else {
            // Full animation
            Image("logo")
                .transition(.scale.combined(with: .slide))
        }
    }
    .animation(.default, value: isPresented)
}

// UIKit
let reduceMotion = UIAccessibility.isReduceMotionEnabled

if reduceMotion {
    // Snap to final state
    view.alpha = 1.0
} else {
    // Animate
    UIView.animate(withDuration: 0.3) {
        self.view.alpha = 1.0
    }
}

// Listen for changes
NotificationCenter.default.addObserver(
    forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
    object: nil,
    queue: .main
) { _ in
    updateAnimations()
}
```

## Accessibility Testing

### Automated Testing

```swift
final class AccessibilityTests: XCTestCase {
    func testButtonHasLabel() {
        let app = XCUIApplication()
        app.launch()

        let button = app.buttons["Submit"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "Submit form")
    }

    func testVoiceOverReading() {
        let button = app.buttons.firstMatch
        XCTAssertNotNil(button.label)
        XCTAssertFalse(button.label.isEmpty)
    }

    func testDynamicTypeScaling() {
        // Test with different text sizes
        for size in [UIContentSizeCategory.small, .large, .xxxLarge] {
            app.launchArguments = ["-UIPreferredContentSizeCategoryName", size.rawValue]
            app.launch()

            // Verify layout doesn't break
            XCTAssertTrue(app.buttons["Submit"].exists)
        }
    }

    func testColorContrast() {
        // Enable high contrast
        app.launchArguments = ["-UIAccessibilityDarkerSystemColorsEnabled", "1"]
        app.launch()

        // Verify elements are still visible
        XCTAssertTrue(app.staticTexts["Title"].exists)
    }
}
```

### Manual Testing Checklist

```markdown
## Accessibility Manual Testing Checklist

### VoiceOver
- [ ] All interactive elements have labels
- [ ] Labels are descriptive and concise
- [ ] Hints provide context when needed
- [ ] Images have meaningful labels (or are hidden if decorative)
- [ ] Custom actions are available where appropriate
- [ ] Focus order is logical
- [ ] No unnecessary swipes needed

### Dynamic Type
- [ ] All text scales appropriately
- [ ] Layout adapts to larger text sizes
- [ ] No text truncation at xxxLarge
- [ ] Buttons remain tappable at all sizes
- [ ] Custom fonts scale using UIFontMetrics

### Color & Contrast
- [ ] WCAG AA contrast ratios met (4.5:1 for normal text, 3:1 for large)
- [ ] App works in both light and dark mode
- [ ] Information not conveyed by color alone
- [ ] High contrast mode supported

### Motion
- [ ] Reduce Motion setting respected
- [ ] Essential animations have reduced alternatives
- [ ] No auto-playing videos with Reduce Motion on

### Additional
- [ ] Landscape and portrait orientations supported
- [ ] Touch targets at least 44x44 points
- [ ] Forms clearly indicate required fields
- [ ] Error messages are descriptive
```

## Best Practices

### 1. Meaningful Labels

```swift
// ✅ Good: Descriptive label
Button {
    deleteItem()
}
.accessibilityLabel("Delete \(item.name)")

// ❌ Avoid: Generic labels
Button {
    deleteItem()
}
.accessibilityLabel("Button")
```

### 2. Combine Related Elements

```swift
// ✅ Good: Combined for context
VStack {
    Text("John Doe")
    Text("Software Engineer")
    Text("San Francisco")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("John Doe, Software Engineer, San Francisco")

// ❌ Avoid: Separate announcements
// VoiceOver reads each line separately, losing context
```

### 3. Use Semantic Controls

```swift
// ✅ Good: Semantic controls have built-in accessibility
Toggle("Notifications", isOn: $enabled)
Picker("Theme", selection: $theme) {
    Text("Light").tag(Theme.light)
    Text("Dark").tag(Theme.dark)
}

// ❌ Avoid: Custom controls without accessibility
Button {
    enabled.toggle()
} label: {
    HStack {
        Text("Notifications")
        Image(systemName: enabled ? "checkmark" : "xmark")
    }
}
// Missing toggle trait and value
```

### 4. Test with Real Users

```markdown
- Run Accessibility Inspector (Xcode)
- Use VoiceOver on real devices
- Test with different Dynamic Type sizes
- Enable high contrast mode
- Try with Reduce Motion enabled
- Consider hiring accessibility consultants
- Include people with disabilities in user testing
```

## WCAG 2.1 Level AA Compliance

### Perceivable

```swift
// 1.1 Text Alternatives
Image("logo")
    .accessibilityLabel("Company logo")

// 1.4.3 Contrast (Minimum) - 4.5:1
extension Color {
    static let accessibleBlue = Color(red: 0, green: 0.4, blue: 1)  // Passes WCAG AA
}

// 1.4.4 Resize Text
Text("Content")
    .font(.body)  // Scales with Dynamic Type
```

### Operable

```swift
// 2.1 Keyboard Accessible
// All interactive elements reachable via VoiceOver

// 2.4.7 Focus Visible
TextField("Email", text: $email)
    .focused($focusedField, equals: .email)

// 2.5.5 Target Size
Button("Submit") { }
    .frame(minWidth: 44, minHeight: 44)  // Minimum tap target
```

### Understandable

```swift
// 3.1 Readable
Text("Content")
    .accessibilityLabel("Clear, simple language")

// 3.3 Input Assistance
TextField("Email", text: $email)
    .accessibilityHint("Enter a valid email address")
```

### Robust

```swift
// 4.1.2 Name, Role, Value
Button("Submit") { }
    .accessibilityLabel("Submit form")  // Name
    .accessibilityAddTraits(.isButton)  // Role
    .accessibilityValue(isSubmitting ? "Submitting" : "Ready")  // Value
```

## tvOS-Specific Accessibility

### Focus Engine

```swift
struct FocusableCard: View {
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Text("Card Content")
        }
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut, value: isFocused)
    }
}
```

## References

- [Apple Accessibility Guide](https://developer.apple.com/accessibility/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [VoiceOver Testing Guide](https://developer.apple.com/documentation/accessibility/voiceover)
- [Dynamic Type Guide](https://developer.apple.com/design/human-interface-guidelines/accessibility/overview/text-size-and-weight/)
- [Accessibility Inspector](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXTestingApps.html)
