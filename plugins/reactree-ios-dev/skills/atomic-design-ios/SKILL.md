---
name: "Atomic Design iOS"
description: "Atomic Design methodology for building scalable component libraries in iOS/tvOS applications"
version: "2.0.0"
---

# Atomic Design for iOS/tvOS

Complete guide to implementing Atomic Design methodology in SwiftUI applications, creating reusable component libraries from atoms to templates.

## Atomic Design Principles

### Component Hierarchy

**Brad Frost's Atomic Design:**
1. **Atoms** - Basic building blocks (buttons, text fields, labels)
2. **Molecules** - Simple combinations of atoms (search bars, form inputs)
3. **Organisms** - Complex UI components (navigation bars, card lists)
4. **Templates** - Page layouts without real data
5. **Pages** - Specific instances with real content

### Benefits for iOS/tvOS

- **Reusability** - Components used across multiple screens
- **Consistency** - Unified design language
- **Scalability** - Easy to add new features
- **Testability** - Isolated component testing
- **Documentation** - Self-documenting with previews

## Atoms (Basic Building Blocks)

### Button Atoms

```swift
// MARK: - Primary Button Atom

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }

    private var backgroundColor: Color {
        isEnabled && !isLoading ? Color.blue : Color.gray
    }
}

// MARK: - Secondary Button Atom

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
        }
    }
}

// MARK: - Icon Button Atom

struct IconButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 24

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .frame(width: size, height: size)
                .foregroundColor(.blue)
        }
    }
}
```

### Text Field Atoms

```swift
// MARK: - Standard Text Field Atom

struct StandardTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// MARK: - Secure Text Field Atom

struct SecureTextField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecure: Bool = true

    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
```

### Label Atoms

```swift
// MARK: - Title Label Atom

struct TitleLabel: View {
    let text: String
    var style: Style = .large

    enum Style {
        case large, medium, small

        var font: Font {
            switch self {
            case .large: return .largeTitle
            case .medium: return .title
            case .small: return .headline
            }
        }
    }

    var body: some View {
        Text(text)
            .font(style.font)
            .foregroundColor(.primary)
    }
}

// MARK: - Badge Atom

struct Badge: View {
    let text: String
    var color: Color = .blue

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}
```

## Molecules (Simple Combinations)

### Search Bar Molecule

```swift
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSearch: () -> Void = {}

    var body: some View {
        HStack {
            // Icon (Atom)
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            // Text Field (Atom)
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            // Clear Button (Atom)
            if !text.isEmpty {
                IconButton(systemName: "xmark.circle.fill") {
                    text = ""
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onSubmit(onSearch)
    }
}
```

### Card Molecule

```swift
struct Card<Content: View>: View {
    let content: Content
    var shadowRadius: CGFloat = 4

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
}

// Usage
Card {
    VStack(alignment: .leading, spacing: 8) {
        TitleLabel(text: "Card Title", style: .medium)
        Text("Card description goes here")
            .font(.body)
            .foregroundColor(.secondary)
    }
}
```

### Form Input Molecule

```swift
struct FormInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label (Atom)
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)

            // Text Field (Atom)
            StandardTextField(placeholder: placeholder, text: $text)

            // Error Message (Atom)
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
```

### Tag List Molecule

```swift
struct TagList: View {
    let tags: [String]
    var onTagTap: ((String) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Badge(text: tag)
                        .onTapGesture {
                            onTagTap?(tag)
                        }
                }
            }
        }
    }
}
```

## Organisms (Complex Components)

### Navigation Bar Organism

```swift
struct CustomNavigationBar: View {
    let title: String
    var leftAction: (() -> Void)?
    var rightAction: (() -> Void)?
    var leftIcon: String = "chevron.left"
    var rightIcon: String?

    var body: some View {
        HStack {
            // Left Button (Molecule)
            if let leftAction = leftAction {
                IconButton(systemName: leftIcon, action: leftAction)
            }

            Spacer()

            // Title (Atom)
            TitleLabel(text: title, style: .medium)

            Spacer()

            // Right Button (Molecule)
            if let rightAction = rightAction, let rightIcon = rightIcon {
                IconButton(systemName: rightIcon, action: rightAction)
            } else {
                // Spacer to balance layout
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}
```

### Product Card Organism

```swift
struct ProductCard: View {
    let product: Product
    var onAddToCart: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                // Product Image
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(8)

                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    TitleLabel(text: product.name, style: .small)

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Spacer()

                        if product.inStock {
                            Badge(text: "In Stock", color: .green)
                        } else {
                            Badge(text: "Out of Stock", color: .red)
                        }
                    }
                }

                // Add to Cart Button (Molecule)
                PrimaryButton(title: "Add to Cart", action: onAddToCart, isEnabled: product.inStock)
            }
        }
    }
}

struct Product {
    let id: String
    let name: String
    let description: String
    let price: Double
    let imageURL: URL?
    let inStock: Bool
}
```

### List Organism

```swift
struct ItemList<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    var onRefresh: (() async -> Void)?

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content, onRefresh: (() async -> Void)? = nil) {
        self.items = items
        self.content = content
        self.onRefresh = onRefresh
    }

    var body: some View {
        List(items) { item in
            content(item)
        }
        .listStyle(.plain)
        .refreshable {
            if let onRefresh = onRefresh {
                await onRefresh()
            }
        }
    }
}
```

## Templates (Page Layouts)

### Standard Page Template

```swift
struct StandardPageTemplate<Content: View>: View {
    let title: String
    let content: Content
    var onBack: (() -> Void)?

    init(title: String, onBack: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onBack = onBack
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar (Organism)
            CustomNavigationBar(
                title: title,
                leftAction: onBack
            )

            // Content Area
            ScrollView {
                content
                    .padding()
            }
        }
    }
}
```

### Form Template

```swift
struct FormTemplate<Content: View>: View {
    let title: String
    let submitButtonTitle: String
    let onSubmit: () -> Void
    let content: Content
    var isLoading: Bool = false

    init(
        title: String,
        submitButtonTitle: String,
        isLoading: Bool = false,
        onSubmit: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.submitButtonTitle = submitButtonTitle
        self.isLoading = isLoading
        self.onSubmit = onSubmit
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            TitleLabel(text: title, style: .large)
                .padding()

            // Form Content
            ScrollView {
                VStack(spacing: 20) {
                    content
                }
                .padding()
            }

            // Submit Button
            PrimaryButton(
                title: submitButtonTitle,
                action: onSubmit,
                isLoading: isLoading
            )
            .padding()
        }
    }
}
```

## Design Tokens Integration

### Color Tokens

```swift
extension Color {
    // Brand Colors
    static let brandPrimary = Color("BrandPrimary")
    static let brandSecondary = Color("BrandSecondary")
    static let brandAccent = Color("BrandAccent")

    // Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue

    // Neutral Colors
    static let neutral100 = Color(.systemGray6)
    static let neutral200 = Color(.systemGray5)
    static let neutral300 = Color(.systemGray4)
}
```

### Typography Tokens

```swift
extension Font {
    // Display
    static let displayLarge = Font.system(size: 57, weight: .bold)
    static let displayMedium = Font.system(size: 45, weight: .bold)

    // Headings
    static let heading1 = Font.system(size: 34, weight: .bold)
    static let heading2 = Font.system(size: 28, weight: .bold)
    static let heading3 = Font.system(size: 22, weight: .semibold)

    // Body
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyRegular = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
}
```

### Spacing Tokens

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

## Preview Providers

### Atom Previews

```swift
#Preview("Primary Button") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Enabled", action: {})
        PrimaryButton(title: "Loading", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isEnabled: false)
    }
    .padding()
}

#Preview("Text Fields") {
    VStack(spacing: 16) {
        StandardTextField(placeholder: "Email", text: .constant(""))
        SecureTextField(placeholder: "Password", text: .constant(""))
    }
    .padding()
}
```

### Molecule Previews

```swift
#Preview("Search Bar") {
    SearchBar(text: .constant(""))
        .padding()
}

#Preview("Form Input") {
    VStack {
        FormInput(label: "Email", placeholder: "Enter your email", text: .constant(""))
        FormInput(label: "Password", placeholder: "Enter password", text: .constant(""), errorMessage: "Password is too short")
    }
    .padding()
}
```

### Organism Previews

```swift
#Preview("Product Card") {
    ProductCard(
        product: Product(
            id: "1",
            name: "iPhone 15 Pro",
            description: "The most powerful iPhone ever",
            price: 999.99,
            imageURL: nil,
            inStock: true
        ),
        onAddToCart: {}
    )
    .padding()
}
```

## Component Library Organization

### File Structure

```
DesignSystem/
├── Atoms/
│   ├── Buttons/
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   └── IconButton.swift
│   ├── TextFields/
│   │   ├── StandardTextField.swift
│   │   └── SecureTextField.swift
│   └── Labels/
│       ├── TitleLabel.swift
│       └── Badge.swift
├── Molecules/
│   ├── SearchBar.swift
│   ├── Card.swift
│   ├── FormInput.swift
│   └── TagList.swift
├── Organisms/
│   ├── CustomNavigationBar.swift
│   ├── ProductCard.swift
│   └── ItemList.swift
├── Templates/
│   ├── StandardPageTemplate.swift
│   └── FormTemplate.swift
└── Tokens/
    ├── Colors.swift
    ├── Typography.swift
    └── Spacing.swift
```

## Best Practices

### 1. Keep Atoms Pure

```swift
// ✅ Good: Simple, reusable
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
}

// ❌ Avoid: Too much logic in atom
struct PrimaryButton: View {
    @EnvironmentObject var authManager: AuthManager
    // Atoms should not know about app state
}
```

### 2. Use View Builders

```swift
// ✅ Good: Flexible content
struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}
```

### 3. Provide Previews

```swift
// Always include previews for documentation
#Preview("Component Name") {
    ComponentView()
}
```

### 4. Use Design Tokens

```swift
// ✅ Good: Uses tokens
.padding(Spacing.md)
.foregroundColor(Color.brandPrimary)

// ❌ Avoid: Hard-coded values
.padding(16)
.foregroundColor(.blue)
```

## References

- [Atomic Design by Brad Frost](https://atomicdesign.bradfrost.com/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Design Systems Guide](https://www.designsystems.com/)
