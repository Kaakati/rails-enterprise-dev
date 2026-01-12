---
name: "SwiftGen Integration"
description: "Type-safe asset code generation with SwiftGen for iOS/tvOS development"
version: "2.0.0"
---

# SwiftGen Integration for iOS/tvOS

Complete guide to implementing SwiftGen for type-safe access to assets, colors, strings, fonts, and storyboards in iOS/tvOS applications.

## Installation

### CocoaPods

```ruby
# Podfile
target 'YourApp' do
  pod 'SwiftGen', '~> 6.6'
end
```

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/SwiftGen/SwiftGen.git", from: "6.6.0")
]
```

### Homebrew

```bash
brew install swiftgen
```

## Configuration File

### swiftgen.yml

```yaml
# swiftgen.yml - Complete configuration

## Input/Output paths
input_dir: Resources/
output_dir: Generated/

## Strings
strings:
  inputs: Resources/Localizable.strings
  outputs:
    - templateName: structured-swift5
      output: Generated/Strings.swift
      params:
        publicAccess: true

## Assets
xcassets:
  inputs: Resources/Assets.xcassets
  outputs:
    - templateName: swift5
      output: Generated/Assets.swift
      params:
        publicAccess: true
        allValues: true

## Colors
colors:
  inputs: Resources/Colors.xcassets
  outputs:
    - templateName: swift5
      output: Generated/Colors.swift
      params:
        publicAccess: true
        enumName: ColorAsset

## Fonts
fonts:
  inputs: Resources/Fonts
  outputs:
    - templateName: swift5
      output: Generated/Fonts.swift
      params:
        publicAccess: true
        preservePath: true

## Storyboards
ib:
  inputs: Resources/Storyboards
  outputs:
    - templateName: scenes-swift5
      output: Generated/Storyboards.swift
      params:
        publicAccess: true

## Plists
plist:
  inputs: Resources/Configuration.plist
  outputs:
    - templateName: runtime-swift5
      output: Generated/Configuration.swift
```

## Assets (Images)

### Asset Catalog Structure

```
Assets.xcassets/
├── Icons/
│   ├── home.imageset/
│   ├── profile.imageset/
│   └── settings.imageset/
├── Images/
│   ├── logo.imageset/
│   └── splash.imageset/
└── Backgrounds/
    └── gradient.imageset/
```

### Generated Code Usage

```swift
// Before SwiftGen
let image = UIImage(named: "home") // ⚠️ Stringly-typed, crash if typo

// After SwiftGen
let image = Asset.Icons.home.image // ✅ Type-safe, compile-time checked

// SwiftUI
Image(asset: Asset.Icons.home)
// or
Image(Asset.Icons.home.name)

// UIKit
let uiImage = Asset.Icons.home.image
imageView.image = uiImage
```

### Custom Asset Extensions

```swift
extension Image {
    init(asset: ImageAsset) {
        self.init(asset.name)
    }
}

// Usage
struct ContentView: View {
    var body: some View {
        Image(asset: Asset.Icons.home)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
```

## Colors

### Color Asset Catalog

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

### Generated Color Usage

```swift
// SwiftUI
struct ThemedView: View {
    var body: some View {
        VStack {
            Text("Hello")
                .foregroundColor(Color(asset: Asset.Colors.text))
        }
        .background(Color(asset: Asset.Colors.background))
    }
}

// UIKit
let backgroundColor = Asset.Colors.background.color
view.backgroundColor = backgroundColor

// Extension for convenience
extension Color {
    static let appPrimary = Color(asset: Asset.Colors.primary)
    static let appSecondary = Color(asset: Asset.Colors.secondary)
    static let appBackground = Color(asset: Asset.Colors.background)
}
```

### Dark Mode Support

Colors in asset catalog automatically support dark mode variants:

```json
// Primary.colorset/Contents.json
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
  ]
}
```

## Localized Strings

### Localizable.strings

```
Resources/
├── en.lproj/
│   └── Localizable.strings
├── es.lproj/
│   └── Localizable.strings
└── ar.lproj/
    └── Localizable.strings
```

**en.lproj/Localizable.strings:**
```
// General
"app.name" = "My App";
"app.tagline" = "Welcome to the future";

// Authentication
"auth.login.title" = "Log In";
"auth.login.email" = "Email Address";
"auth.login.password" = "Password";
"auth.login.button" = "Sign In";

// Errors
"error.network.title" = "Network Error";
"error.network.message" = "Please check your connection";

// Pluralization
"items.count" = "%d item(s)";
```

### Generated String Usage

```swift
// Before SwiftGen
let title = NSLocalizedString("auth.login.title", comment: "") // ⚠️ Stringly-typed

// After SwiftGen
let title = L10n.Auth.Login.title // ✅ Type-safe

// With parameters
let message = L10n.Items.count(5) // "5 item(s)"

// SwiftUI
struct LoginView: View {
    var body: some View {
        VStack {
            Text(L10n.Auth.Login.title)
            TextField(L10n.Auth.Login.email, text: $email)
            SecureField(L10n.Auth.Login.password, text: $password)
            Button(L10n.Auth.Login.button) {
                // Login
            }
        }
    }
}
```

### Structured Strings Template

```yaml
strings:
  inputs: Resources/en.lproj/Localizable.strings
  outputs:
    - templateName: structured-swift5
      output: Generated/Strings.swift
```

**Generated code structure:**
```swift
enum L10n {
    enum App {
        static let name = L10n.tr("Localizable", "app.name")
        static let tagline = L10n.tr("Localizable", "app.tagline")
    }
    enum Auth {
        enum Login {
            static let title = L10n.tr("Localizable", "auth.login.title")
            static let email = L10n.tr("Localizable", "auth.login.email")
            static let password = L10n.tr("Localizable", "auth.login.password")
            static let button = L10n.tr("Localizable", "auth.login.button")
        }
    }
}
```

## Fonts

### Custom Fonts Setup

**1. Add fonts to project:**
```
Resources/
└── Fonts/
    ├── Roboto-Regular.ttf
    ├── Roboto-Bold.ttf
    └── Roboto-Light.ttf
```

**2. Register in Info.plist:**
```xml
<key>UIAppFonts</key>
<array>
    <string>Roboto-Regular.ttf</string>
    <string>Roboto-Bold.ttf</string>
    <string>Roboto-Light.ttf</string>
</array>
```

**3. SwiftGen configuration:**
```yaml
fonts:
  inputs: Resources/Fonts
  outputs:
    - templateName: swift5
      output: Generated/Fonts.swift
```

### Generated Font Usage

```swift
// SwiftUI
struct StyledText: View {
    var body: some View {
        Text("Hello")
            .font(FontFamily.Roboto.regular.swiftUIFont(size: 17))
    }
}

// UIKit
let font = FontFamily.Roboto.bold.font(size: 20)
label.font = font

// Extensions for convenience
extension Font {
    static func appRegular(size: CGFloat) -> Font {
        FontFamily.Roboto.regular.swiftUIFont(size: size)
    }

    static func appBold(size: CGFloat) -> Font {
        FontFamily.Roboto.bold.swiftUIFont(size: size)
    }
}
```

## Xcode Build Phase Integration

### Run Script Phase

**Build Phases → New Run Script Phase:**
```bash
if which swiftgen >/dev/null; then
  swiftgen config run --config swiftgen.yml
else
  echo "warning: SwiftGen not installed, download it from https://github.com/SwiftGen/SwiftGen"
fi
```

**Input Files:**
```
$(SRCROOT)/swiftgen.yml
$(SRCROOT)/Resources/Assets.xcassets
$(SRCROOT)/Resources/en.lproj/Localizable.strings
$(SRCROOT)/Resources/Colors.xcassets
```

**Output Files:**
```
$(DERIVED_FILE_DIR)/Generated/Assets.swift
$(DERIVED_FILE_DIR)/Generated/Strings.swift
$(DERIVED_FILE_DIR)/Generated/Colors.swift
```

## SwiftGen Validation

### Linting Configuration

**swiftgen.yml:**
```yaml
# Linting configuration
lint:
  missing-keys: error
  duplicate-keys: error
  unused-keys: warning
```

### Command Line Linting

```bash
# Lint all configurations
swiftgen config lint

# Lint specific template
swiftgen strings --lint Resources/en.lproj/Localizable.strings
```

## Best Practices

### 1. Organize by Feature

```
Resources/
├── Assets.xcassets/
│   ├── Authentication/
│   ├── Dashboard/
│   └── Settings/
├── en.lproj/
│   └── Localizable.strings
└── Colors.xcassets/
```

### 2. Use Namespacing

```swift
// Group related assets
enum Asset {
    enum Icons {
        static let home = ImageAsset(name: "home")
        static let profile = ImageAsset(name: "profile")
    }

    enum Images {
        static let logo = ImageAsset(name: "logo")
    }
}
```

### 3. Version Control

**Add to .gitignore:**
```
# Generated files
Generated/
*.generated.swift
```

**Commit configuration:**
```
# Commit these
swiftgen.yml
Resources/Assets.xcassets
Resources/Localizable.strings
```

### 4. Type-Safe Access Everywhere

```swift
// ✅ Good
Image(asset: Asset.Icons.home)
Color(asset: Asset.Colors.primary)
Text(L10n.Auth.Login.title)

// ❌ Avoid
Image("home")
Color("Primary")
Text("auth.login.title")
```

## Testing

### Unit Tests

```swift
final class SwiftGenTests: XCTestCase {
    func testAssetsExist() {
        XCTAssertNotNil(Asset.Icons.home.image)
        XCTAssertNotNil(Asset.Colors.primary.color)
    }

    func testStringsExist() {
        XCTAssertFalse(L10n.Auth.Login.title.isEmpty)
        XCTAssertTrue(L10n.Auth.Login.title.contains("Log"))
    }

    func testFontsExist() {
        let font = FontFamily.Roboto.regular.font(size: 12)
        XCTAssertNotNil(font)
    }
}
```

### Snapshot Tests

```swift
func testThemedViewAppearance() {
    let view = ThemedView()
        .background(Color(asset: Asset.Colors.background))

    assertSnapshot(matching: view, as: .image)
}
```

## Troubleshooting

### Common Issues

**1. SwiftGen not found:**
```bash
# Check installation
which swiftgen

# Install via Homebrew
brew install swiftgen
```

**2. Generated files not updating:**
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Re-run SwiftGen
swiftgen config run --config swiftgen.yml
```

**3. Build phase errors:**
- Ensure Input Files and Output Files are correctly specified
- Check file permissions on swiftgen.yml
- Verify paths in configuration file

**4. Import errors:**
```swift
// Ensure Generated folder is added to project
// Check target membership in File Inspector
```

## References

- [SwiftGen Documentation](https://github.com/SwiftGen/SwiftGen)
- [SwiftGen Templates](https://github.com/SwiftGen/SwiftGen/tree/stable/templates)
- [Asset Catalog Format Reference](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/)
