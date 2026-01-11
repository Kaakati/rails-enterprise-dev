---
paths: "**/Core/**/*Service.swift"
---

# Service Layer Conventions

Apply Protocol-Oriented Programming for all services.

## Structure

```swift
protocol UserServiceProtocol {
    func fetchUser(id: String) async -> Result<User, NetworkError>
}

final class UserService: UserServiceProtocol {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
}
```

**Rules:**
- All services have a protocol
- Use dependency injection
- Mark final if not subclassed
- Use async/await for async operations
