---
name: "SwiftUI Patterns"
description: "SwiftUI view composition, state management, and platform-specific patterns for iOS/tvOS"
version: "1.0.0"
---

# SwiftUI Patterns

## State Management

**@State**: View-local state
```swift
@State private var isPresented = false
```

**@Binding**: Two-way binding to parent state
```swift
struct ChildView: View {
    @Binding var text: String
}
```

**@ObservedObject**: External reference type
```swift
@ObservedObject var viewModel: UserViewModel
```

**@StateObject**: Ownership of ObservableObject
```swift
@StateObject private var viewModel = UserViewModel()
```

**@EnvironmentObject**: Shared app-wide state
```swift
@EnvironmentObject var sessionState: SessionState
```

## Platform-Specific Patterns

**tvOS Focus Management:**
```swift
@FocusState private var focusedField: Field?

Button("Login") { }
    .focusable()
    .focused($focusedField, equals: .login)
```

**iOS vs tvOS Conditionals:**
```swift
#if os(tvOS)
    LargeCardView()
#else
    CompactCardView()
#endif
```

## View Modifiers

```swift
Text("Hello")
    .font(.title)
    .foregroundColor(.primary)
    .padding()
    .background(Color.blue)
    .cornerRadius(8)
```
