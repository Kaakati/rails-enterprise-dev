---
paths: "**/Core/**/*Manager.swift"
---

# Manager Conventions

Managers use Singleton pattern.

```swift
final class SessionManager {
    static let shared = SessionManager()
    private init() {}

    var accessToken: String? { get { ... } }
}
```
