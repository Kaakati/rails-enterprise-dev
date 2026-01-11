---
paths: "**/Presentation/**/*Model.swift"
---

# Model Conventions

```swift
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
}
```

- Use structs for models
- Conform to Codable for JSON
- Conform to Identifiable for SwiftUI lists
