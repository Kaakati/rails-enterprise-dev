---
paths: "**/DesignSystem/Components/**/*.swift"
---

# Design System Component Conventions

Follow Atomic Design: Atoms → Molecules → Organisms

```swift
// Atom
struct AppText: View {
    let text: String
    var body: some View { Text(text) }
}

// Molecule
struct AppCard: View {
    let title: String
    var body: some View {
        VStack {
            AppImage()
            AppText(text: title)
        }
    }
}
```
