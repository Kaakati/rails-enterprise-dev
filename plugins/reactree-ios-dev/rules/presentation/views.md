---
paths: "**/Presentation/**/*View.swift"
---

# SwiftUI View Conventions

```swift
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            // Content
        }
    }
}
```

- Use @StateObject for owned ViewModels
- Use @ObservedObject for injected ViewModels
- Extract complex views to separate components
