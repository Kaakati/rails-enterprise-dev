---
name: "Localization iOS"
description: "Comprehensive internationalization and localization patterns for iOS/tvOS applications"
version: "2.0.0"
---

# Localization for iOS/tvOS

Complete guide to implementing internationalization (i18n) and localization (l10n) in SwiftUI and UIKit applications with support for multiple languages, RTL layouts, and SwiftGen integration.

## Core Concepts

### Localization Architecture

**Key Components:**
- `.lproj` directories for each supported language
- `Localizable.strings` files for translated strings
- `InfoPlist.strings` for app metadata
- `LanguageManager` for runtime language switching
- SwiftGen for type-safe string access

**Supported Languages:**
- LTR (Left-to-Right): English, Spanish, French, German, etc.
- RTL (Right-to-Left): Arabic, Hebrew, Persian, Urdu

### Directory Structure

```
YourApp/
├── Resources/
│   ├── en.lproj/
│   │   ├── Localizable.strings
│   │   ├── InfoPlist.strings
│   │   └── Localizable.stringsdict (plurals)
│   ├── es.lproj/
│   │   ├── Localizable.strings
│   │   └── Localizable.stringsdict
│   ├── ar.lproj/
│   │   ├── Localizable.strings
│   │   └── Localizable.stringsdict
│   └── fr.lproj/
│       ├── Localizable.strings
│       └── Localizable.stringsdict
└── Generated/
    └── Strings.swift (SwiftGen generated)
```

## LanguageManager Pattern

### Singleton LanguageManager

```swift
@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published private(set) var currentLanguage: Language = .english
    @Published private(set) var isRTL: Bool = false

    private let languageKey = "selectedLanguage"

    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case spanish = "es"
        case arabic = "ar"
        case french = "fr"
        case hebrew = "he"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .arabic: return "العربية"
            case .french: return "Français"
            case .hebrew: return "עברית"
            }
        }

        var isRTL: Bool {
            self == .arabic || self == .hebrew
        }

        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }

    private init() {
        loadSavedLanguage()
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
        isRTL = language.isRTL

        // Save preference
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)

        // Update app language
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Post notification for UI updates
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    private func loadSavedLanguage() {
        guard let savedLanguageCode = UserDefaults.standard.string(forKey: languageKey),
              let language = Language(rawValue: savedLanguageCode) else {
            // Use system language as default
            currentLanguage = detectSystemLanguage()
            isRTL = currentLanguage.isRTL
            return
        }

        currentLanguage = language
        isRTL = language.isRTL
    }

    private func detectSystemLanguage() -> Language {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(preferredLanguage.prefix(2))

        return Language(rawValue: languageCode) ?? .english
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
```

## Localizable.strings Format

### Basic Strings File

**en.lproj/Localizable.strings:**
```
/* General */
"app.name" = "My App";
"app.tagline" = "Welcome to the future";

/* Navigation */
"nav.home" = "Home";
"nav.profile" = "Profile";
"nav.settings" = "Settings";

/* Authentication */
"auth.login.title" = "Log In";
"auth.login.email" = "Email Address";
"auth.login.password" = "Password";
"auth.login.button" = "Sign In";
"auth.login.forgot_password" = "Forgot Password?";
"auth.signup.title" = "Create Account";
"auth.logout.button" = "Log Out";

/* Errors */
"error.network.title" = "Network Error";
"error.network.message" = "Please check your connection and try again.";
"error.validation.email" = "Please enter a valid email address.";
"error.validation.password_short" = "Password must be at least 8 characters.";

/* Actions */
"action.save" = "Save";
"action.cancel" = "Cancel";
"action.delete" = "Delete";
"action.edit" = "Edit";
"action.confirm" = "Confirm";

/* Formatting with parameters */
"user.greeting" = "Hello, %@!";
"items.count" = "You have %d item(s)";
"download.progress" = "Downloading... %d%%";
"user.age" = "%@ is %d years old";
```

**es.lproj/Localizable.strings:**
```
/* General */
"app.name" = "Mi App";
"app.tagline" = "Bienvenido al futuro";

/* Navigation */
"nav.home" = "Inicio";
"nav.profile" = "Perfil";
"nav.settings" = "Configuración";

/* Authentication */
"auth.login.title" = "Iniciar Sesión";
"auth.login.email" = "Correo Electrónico";
"auth.login.password" = "Contraseña";
"auth.login.button" = "Entrar";
```

**ar.lproj/Localizable.strings:**
```
/* General */
"app.name" = "تطبيقي";
"app.tagline" = "مرحباً بك في المستقبل";

/* Navigation */
"nav.home" = "الرئيسية";
"nav.profile" = "الملف الشخصي";
"nav.settings" = "الإعدادات";

/* Authentication */
"auth.login.title" = "تسجيل الدخول";
"auth.login.email" = "البريد الإلكتروني";
"auth.login.password" = "كلمة المرور";
"auth.login.button" = "دخول";
```

## NSLocalizedString Usage

### Basic Usage

```swift
// Without SwiftGen (traditional approach)
let title = NSLocalizedString("auth.login.title", comment: "Login screen title")
let email = NSLocalizedString("auth.login.email", comment: "Email field label")

// With parameters
let greeting = String(format: NSLocalizedString("user.greeting", comment: ""), userName)
let itemCount = String(format: NSLocalizedString("items.count", comment: ""), count)
```

### Helper Extension

```swift
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// Usage
let title = "auth.login.title".localized
let greeting = "user.greeting".localized(with: userName)
let age = "user.age".localized(with: userName, userAge)
```

## SwiftGen L10n Integration

### SwiftGen Configuration

**swiftgen.yml:**
```yaml
strings:
  inputs:
    - Resources/en.lproj/Localizable.strings
  outputs:
    - templateName: structured-swift5
      output: Generated/Strings.swift
      params:
        publicAccess: true
        lookupFunction: tr
```

### Generated Code Usage

```swift
// SwiftGen generated enum structure
// Before SwiftGen
let title = NSLocalizedString("auth.login.title", comment: "")

// After SwiftGen
let title = L10n.Auth.Login.title

// With parameters
let greeting = L10n.User.greeting("John")
let itemCount = L10n.Items.count(5)
let userAge = L10n.User.age("Alice", 25)
```

### SwiftUI Integration

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.Auth.Login.title)
                .font(.largeTitle)

            TextField(L10n.Auth.Login.email, text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)

            SecureField(L10n.Auth.Login.password, text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)

            Button(L10n.Auth.Login.button) {
                // Login action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Pluralization Support

### Localizable.stringsdict Format

**en.lproj/Localizable.stringsdict:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items.count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@item_count@</string>
        <key>item_count</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string>No items</string>
            <key>one</key>
            <string>1 item</string>
            <key>other</key>
            <string>%d items</string>
        </dict>
    </dict>

    <key>notifications.count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@notification_count@</string>
        <key>notification_count</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string>No notifications</string>
            <key>one</key>
            <string>1 new notification</string>
            <key>other</key>
            <string>%d new notifications</string>
        </dict>
    </dict>
</dict>
</plist>
```

**ar.lproj/Localizable.stringsdict:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items.count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@item_count@</string>
        <key>item_count</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string>لا توجد عناصر</string>
            <key>one</key>
            <string>عنصر واحد</string>
            <key>two</key>
            <string>عنصران</string>
            <key>few</key>
            <string>%d عناصر</string>
            <key>many</key>
            <string>%d عنصراً</string>
            <key>other</key>
            <string>%d عنصر</string>
        </dict>
    </dict>
</dict>
</plist>
```

### Usage in Code

```swift
// Pluralization is automatic
let message = String.localizedStringWithFormat(
    NSLocalizedString("items.count", comment: ""),
    itemCount
)

// 0 → "No items"
// 1 → "1 item"
// 5 → "5 items"

// Arabic: 0, 1, 2, 3-10, 11-99, 100+ all have different forms
```

## RTL (Right-to-Left) Support

### Layout Mirroring

```swift
struct RTLAwareView: View {
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        HStack {
            Image(systemName: "chevron.right")
                .flipsForRightToLeftLayoutDirection(true)

            Text("Next")
        }
        .environment(\.layoutDirection, languageManager.isRTL ? .rightToLeft : .leftToRight)
    }
}
```

### Manual RTL Handling

```swift
extension View {
    func leadingAlignment() -> some View {
        self.frame(maxWidth: .infinity, alignment: LanguageManager.shared.isRTL ? .trailing : .leading)
    }

    func trailingAlignment() -> some View {
        self.frame(maxWidth: .infinity, alignment: LanguageManager.shared.isRTL ? .leading : .trailing)
    }
}

// Usage
Text("Left-aligned text")
    .leadingAlignment()

Text("Right-aligned text")
    .trailingAlignment()
```

### RTL-Safe Padding

```swift
extension View {
    func leadingPadding(_ value: CGFloat) -> some View {
        self.padding(LanguageManager.shared.isRTL ? .trailing : .leading, value)
    }

    func trailingPadding(_ value: CGFloat) -> some View {
        self.padding(LanguageManager.shared.isRTL ? .leading : .trailing, value)
    }
}
```

## Runtime Language Switching

### Language Picker View

```swift
struct LanguagePickerView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showRestartAlert = false

    var body: some View {
        Form {
            Section {
                ForEach(LanguageManager.Language.allCases) { language in
                    Button {
                        changeLanguage(to: language)
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text(L10n.Settings.language)
            }
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please restart the app to apply the language change.")
        }
    }

    private func changeLanguage(to language: LanguageManager.Language) {
        languageManager.setLanguage(language)
        showRestartAlert = true
    }
}
```

### App Restart for Language Change

```swift
@main
struct YourApp: App {
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environment(\.layoutDirection, languageManager.isRTL ? .rightToLeft : .leftToLeft)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                    // Trigger UI refresh
                }
        }
    }
}
```

## Date and Number Formatting

### Locale-Aware Formatting

```swift
struct LocalizedFormattingHelpers {
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }

    static func formatNumber(_ number: Double, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    static func formatCurrency(_ amount: Double, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// Usage
let dateString = LocalizedFormattingHelpers.formatDate(Date()) // "Jan 11, 2026" (en) or "11 ene 2026" (es)
let numberString = LocalizedFormattingHelpers.formatNumber(1234.56) // "1,234.56" (en) or "1.234,56" (es)
let priceString = LocalizedFormattingHelpers.formatCurrency(99.99) // "$99.99" (en) or "99,99 $" (es)
```

## Testing Localization

### Unit Tests

```swift
final class LocalizationTests: XCTestCase {
    func testAllStringKeysExist() {
        let languages = ["en", "es", "ar", "fr"]

        for language in languages {
            let bundle = Bundle(for: type(of: self))
            guard let path = bundle.path(forResource: language, ofType: "lproj"),
                  let langBundle = Bundle(path: path) else {
                XCTFail("Missing \(language).lproj")
                continue
            }

            // Test key exists
            let localizedString = NSLocalizedString("auth.login.title", bundle: langBundle, comment: "")
            XCTAssertFalse(localizedString.isEmpty, "\(language): Missing translation for auth.login.title")
            XCTAssertNotEqual(localizedString, "auth.login.title", "\(language): Translation not found")
        }
    }

    func testPluralizationWorks() {
        let counts = [0, 1, 2, 5, 100]

        for count in counts {
            let formatted = String.localizedStringWithFormat(
                NSLocalizedString("items.count", comment: ""),
                count
            )
            XCTAssertFalse(formatted.isEmpty)
            print("items.count(\(count)) = \(formatted)")
        }
    }

    func testRTLDetection() {
        let arabicLang = LanguageManager.Language.arabic
        XCTAssertTrue(arabicLang.isRTL)

        let englishLang = LanguageManager.Language.english
        XCTAssertFalse(englishLang.isRTL)
    }
}
```

### UI Tests for RTL

```swift
final class RTLUITests: XCTestCase {
    func testRTLLayoutMirroring() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ar)"]
        app.launch()

        // Verify navigation bar elements are mirrored
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.exists)

        // Take screenshots for visual regression
        let screenshot = app.screenshot()
        // Compare with baseline
    }
}
```

## Pseudo-Localization for QA

### Pseudo-Language Generator

```swift
struct PseudoLocalizer {
    static func pseudolocalize(_ input: String) -> String {
        // Add brackets and accents to make strings longer and test UI layout
        let accented = input.map { char -> String in
            switch char {
            case "a": return "á"
            case "e": return "é"
            case "i": return "í"
            case "o": return "ó"
            case "u": return "ú"
            case "A": return "Á"
            case "E": return "É"
            case "I": return "Í"
            case "O": return "Ó"
            case "U": return "Ú"
            default: return String(char)
            }
        }.joined()

        // Add 30% extra characters to test layout with longer strings
        let padding = String(repeating: "~", count: max(1, input.count / 3))

        return "[[\(accented)\(padding)]]"
    }
}

// Usage in debug builds
#if DEBUG
extension String {
    var pseudolocalized: String {
        PseudoLocalizer.pseudolocalize(self)
    }
}
#endif
```

### Enable Pseudo-Localization

**Xcode Scheme → Arguments:**
```
-AppleLanguages (en-PSEUDO)
-NSDoubleLocalizedStrings YES
```

## Best Practices

### 1. Use Meaningful Keys

```swift
// ✅ Good: Descriptive, hierarchical keys
"auth.login.title"
"auth.login.email_placeholder"
"error.network.timeout"

// ❌ Avoid: Generic or unclear keys
"title"
"placeholder"
"error"
```

### 2. Always Provide Comments

```swift
// ✅ Good
NSLocalizedString("auth.login.button", comment: "Primary button to submit login form")

// ❌ Avoid
NSLocalizedString("auth.login.button", comment: "")
```

### 3. Avoid String Concatenation

```swift
// ❌ Bad: Doesn't work for different word orders
let message = NSLocalizedString("hello", comment: "") + " " + userName

// ✅ Good: Use format strings
let message = String(format: NSLocalizedString("user.greeting", comment: ""), userName)
```

### 4. Test All Languages

```swift
// Test each language thoroughly
// - Run app in each supported language
// - Check for truncated text
// - Verify RTL layouts
// - Test pluralization rules
```

### 5. Extract Strings Regularly

```bash
# Use genstrings to find new strings
find . -name "*.swift" | xargs genstrings -o en.lproj
```

## Troubleshooting

### Strings Not Updating

```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Re-build project
xcodebuild clean build
```

### Missing Translations

```bash
# Find missing keys across languages
# Compare en.lproj with other languages
diff en.lproj/Localizable.strings es.lproj/Localizable.strings
```

### RTL Layout Issues

```swift
// Always use leading/trailing instead of left/right
.padding(.leading, 16) // ✅ Good
.padding(.left, 16)    // ❌ Avoid
```

## References

- [Apple Internationalization Guide](https://developer.apple.com/internationalization/)
- [SwiftGen Strings Documentation](https://github.com/SwiftGen/SwiftGen)
- [Unicode CLDR Plural Rules](http://cldr.unicode.org/index/cldr-spec/plural-rules)
