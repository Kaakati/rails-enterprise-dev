---
name: "Theme Management"
description: "Comprehensive theme management, dark mode, and dynamic styling patterns for iOS/tvOS"
version: "2.0.0"
---

# Theme Management for iOS/tvOS

Complete guide to implementing theme systems, dark mode support, dynamic colors, and custom theming in SwiftUI applications.

## Core ThemeManager Pattern

### Singleton ThemeManager

```swift
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: Theme = .system
    @Published private(set) var colors: ThemeColors
    @Published private(set) var typography: ThemeTypography

    private let themeKey = "selectedTheme"

    private init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = Theme(rawValue: savedTheme) {
            self.currentTheme = theme
        }

        // Initialize colors based on theme
        self.colors = ThemeColors(theme: currentTheme)
        self.typography = ThemeTypography()
    }

    func setTheme(_ theme: Theme) {
        currentTheme = theme
        colors = ThemeColors(theme: theme)
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)

        // Notify system of theme change
        applyTheme(theme)
    }

    private func applyTheme(_ theme: Theme) {
        // Apply theme to UIKit components if needed
        switch theme {
        case .light:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        case .dark:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        case .system:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
        }
    }
}

enum Theme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
```

## Dark Mode Support

### Environment-Based Dark Mode

```swift
struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Current mode: \(colorScheme == .dark ? "Dark" : "Light")")
                .foregroundColor(textColor)
                .background(backgroundColor)
        }
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
}
```

### Adaptive Colors

```swift
struct ThemeColors {
    let theme: Theme

    // Primary colors
    var primary: Color {
        switch theme {
        case .light:
            return Color(hex: "#007AFF")
        case .dark:
            return Color(hex: "#0A84FF")
        case .system:
            return Color.accentColor
        }
    }

    var secondary: Color {
        switch theme {
        case .light:
            return Color(hex: "#5856D6")
        case .dark:
            return Color(hex: "#5E5CE6")
        case .system:
            return Color.secondary
        }
    }

    // Background colors
    var background: Color {
        Color(.systemBackground)
    }

    var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }

    var tertiaryBackground: Color {
        Color(.tertiarySystemBackground)
    }

    // Text colors
    var text: Color {
        Color(.label)
    }

    var secondaryText: Color {
        Color(.secondaryLabel)
    }

    var tertiaryText: Color {
        Color(.tertiaryLabel)
    }

    // Semantic colors
    var success: Color {
        Color(.systemGreen)
    }

    var warning: Color {
        Color(.systemOrange)
    }

    var error: Color {
        Color(.systemRed)
    }

    var info: Color {
        Color(.systemBlue)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

## SwiftGen Integration

### Assets.xcassets Configuration

**Colors.xcassets structure:**
```
Colors.xcassets/
├── Primary.colorset/
│   └── Contents.json
├── Secondary.colorset/
│   └── Contents.json
├── Background.colorset/
│   └── Contents.json
└── Text.colorset/
    └── Contents.json
```

**Contents.json example:**
```json
{
  "colors": [
    {
      "idiom": "universal",
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.000",
          "green": "0.478",
          "blue": "1.000",
          "alpha": "1.000"
        }
      }
    },
    {
      "idiom": "universal",
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.039",
          "green": "0.518",
          "blue": "1.000",
          "alpha": "1.000"
        }
      }
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

### SwiftGen Generated Colors

**swiftgen.yml:**
```yaml
colors:
  inputs: Resources/Colors.xcassets
  outputs:
    - templateName: swift5
      output: Generated/Colors.swift
```

**Usage:**
```swift
// Generated code usage
Text("Hello")
    .foregroundColor(Asset.Colors.primary.swiftUIColor)
    .background(Asset.Colors.background.swiftUIColor)

// Extension for convenience
extension Color {
    static let themePrimary = Asset.Colors.primary.swiftUIColor
    static let themeSecondary = Asset.Colors.secondary.swiftUIColor
    static let themeBackground = Asset.Colors.background.swiftUIColor
}
```

## Dynamic Color Systems

### Asset Catalog Colors

```swift
extension Color {
    // Automatically adapts to light/dark mode
    static let appPrimary = Color("AppPrimary")
    static let appSecondary = Color("AppSecondary")
    static let appBackground = Color("AppBackground")
    static let appText = Color("AppText")
}

// Usage
struct ThemedView: View {
    var body: some View {
        VStack {
            Text("Title")
                .foregroundColor(.appText)
        }
        .background(Color.appBackground)
    }
}
```

### Custom Dynamic Colors

```swift
extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// Usage
let customColor = Color.dynamic(
    light: Color(hex: "#007AFF"),
    dark: Color(hex: "#0A84FF")
)
```

## Typography System

### ThemeTypography

```swift
struct ThemeTypography {
    // Title styles
    let largeTitle: Font = .system(size: 34, weight: .bold)
    let title1: Font = .system(size: 28, weight: .bold)
    let title2: Font = .system(size: 22, weight: .bold)
    let title3: Font = .system(size: 20, weight: .semibold)

    // Body styles
    let body: Font = .system(size: 17, weight: .regular)
    let bodyBold: Font = .system(size: 17, weight: .semibold)
    let callout: Font = .system(size: 16, weight: .regular)

    // Supporting styles
    let caption1: Font = .system(size: 12, weight: .regular)
    let caption2: Font = .system(size: 11, weight: .regular)
    let footnote: Font = .system(size: 13, weight: .regular)

    // Custom app fonts
    static func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom("YourAppFont", size: size)
            .weight(weight)
    }
}

// Environment injection
struct ThemeTypographyKey: EnvironmentKey {
    static let defaultValue = ThemeTypography()
}

extension EnvironmentValues {
    var typography: ThemeTypography {
        get { self[ThemeTypographyKey.self] }
        set { self[ThemeTypographyKey.self] = newValue }
    }
}

// Usage
struct StyledText: View {
    @Environment(\.typography) var typography

    var body: some View {
        Text("Styled Text")
            .font(typography.title1)
    }
}
```

## Theme Switching

### Theme Picker View

```swift
struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Section {
                ForEach(Theme.allCases) { theme in
                    Button {
                        themeManager.setTheme(theme)
                    } label: {
                        HStack {
                            Image(systemName: theme.icon)
                                .foregroundColor(themeManager.colors.primary)

                            Text(theme.displayName)
                                .foregroundColor(themeManager.colors.text)

                            Spacer()

                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.colors.primary)
                            }
                        }
                    }
                }
            } header: {
                Text("Appearance")
            }
        }
    }
}
```

### Animated Theme Transitions

```swift
extension ThemeManager {
    func setTheme(_ theme: Theme, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTheme = theme
                colors = ThemeColors(theme: theme)
            }
        } else {
            currentTheme = theme
            colors = ThemeColors(theme: theme)
        }

        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        applyTheme(theme)
    }
}
```

## Custom Theme Creation

### User-Defined Themes

```swift
struct CustomTheme: Codable, Identifiable {
    let id: UUID
    let name: String
    let primaryColor: String
    let secondaryColor: String
    let backgroundColor: String
    let textColor: String

    var colors: ThemeColors {
        ThemeColors(
            primary: Color(hex: primaryColor),
            secondary: Color(hex: secondaryColor),
            background: Color(hex: backgroundColor),
            text: Color(hex: textColor)
        )
    }
}

extension ThemeManager {
    @Published var customThemes: [CustomTheme] = []

    func addCustomTheme(_ theme: CustomTheme) {
        customThemes.append(theme)
        saveCustomThemes()
    }

    func applyCustomTheme(_ theme: CustomTheme) {
        colors = theme.colors
    }

    private func saveCustomThemes() {
        if let encoded = try? JSONEncoder().encode(customThemes) {
            UserDefaults.standard.set(encoded, forKey: "customThemes")
        }
    }

    private func loadCustomThemes() {
        if let data = UserDefaults.standard.data(forKey: "customThemes"),
           let decoded = try? JSONDecoder().decode([CustomTheme].self, from: data) {
            customThemes = decoded
        }
    }
}
```

## Accessibility Considerations

### Color Contrast Validation

```swift
extension Color {
    func contrastRatio(with other: Color) -> CGFloat {
        let luminance1 = self.relativeLuminance()
        let luminance2 = other.relativeLuminance()

        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance() -> CGFloat {
        // Convert to RGB components
        guard let components = UIColor(self).cgColor.components else { return 0 }

        let r = linearize(components[0])
        let g = linearize(components[1])
        let b = linearize(components[2])

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func linearize(_ value: CGFloat) -> CGFloat {
        if value <= 0.03928 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }

    func meetsWCAGAA(on background: Color) -> Bool {
        return contrastRatio(with: background) >= 4.5
    }

    func meetsWCAGAAA(on background: Color) -> Bool {
        return contrastRatio(with: background) >= 7.0
    }
}
```

### High Contrast Mode Support

```swift
struct ThemedButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    let title: String

    var body: some View {
        Button(title) {
            // Action
        }
        .foregroundColor(.white)
        .background(buttonColor)
        .overlay(
            differentiateWithoutColor ?
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary, lineWidth: 2)
                : nil
        )
    }

    private var buttonColor: Color {
        differentiateWithoutColor ? .gray : .blue
    }
}
```

## Best Practices

### 1. Use System Colors When Possible

```swift
// ✅ Good: Uses adaptive system colors
Color(.systemBackground)
Color(.label)
Color(.systemBlue)

// ❌ Avoid: Hard-coded colors
Color.white
Color.black
Color(red: 0, green: 0, blue: 1)
```

### 2. Respect User Preferences

```swift
@Environment(\.colorScheme) var colorScheme
@Environment(\.colorSchemeContrast) var contrast
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var background: some View {
    if reduceTransparency {
        Color.systemBackground
    } else {
        Color.systemBackground.opacity(0.95)
    }
}
```

### 3. Test in Both Modes

```swift
#Preview("Light Mode") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
```

### 4. Provide Theme Toggle

```swift
struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Picker("Appearance", selection: $themeManager.currentTheme) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
        }
    }
}
```

## Testing Themes

```swift
final class ThemeManagerTests: XCTestCase {
    var sut: ThemeManager!

    override func setUp() {
        super.setUp()
        sut = ThemeManager()
    }

    func testSetLightTheme() {
        sut.setTheme(.light)
        XCTAssertEqual(sut.currentTheme, .light)
    }

    func testSetDarkTheme() {
        sut.setTheme(.dark)
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testColorContrast() {
        let white = Color.white
        let black = Color.black

        XCTAssertTrue(white.meetsWCAGAAA(on: black))
        XCTAssertTrue(black.meetsWCAGAAA(on: white))
    }
}
```

## References

- [Human Interface Guidelines - Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [Color Assets](https://developer.apple.com/documentation/xcode/asset-management)
- [SwiftGen Documentation](https://github.com/SwiftGen/SwiftGen)
