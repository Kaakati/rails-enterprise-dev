---
name: "Swift Conventions & Best Practices"
description: "Swift 5 naming conventions, file structure, code organization, and SwiftLint rules for iOS/tvOS development"
version: "1.0.0"
---

# Swift Conventions & Best Practices

## Naming Conventions

**Files**: `PascalCase.swift`
```
UserViewModel.swift
NetworkClient.swift
SessionManager.swift
```

**Classes/Structs/Enums**: `PascalCase`
```swift
class UserViewModel
struct User
enum NetworkError
```

**Variables/Functions**: `camelCase`
```swift
var userName: String
func fetchUserData()
```

**Constants**:
```swift
// Instance constants: camelCase
let maxRetries = 3

// Static/Global constants: SCREAMING_SNAKE_CASE or camelCase
static let BASE_URL = "https://api.example.com"
static let defaultTimeout: TimeInterval = 30
```

**Protocols**: Descriptive names, often ending with `Protocol`
```swift
protocol NetworkClientProtocol { }
protocol UserServiceProtocol { }
```

## File Structure

```swift
//
//  FileName.swift
//  ProjectName
//

import Foundation
import Combine

// MARK: - Main Type Definition

class/struct/enum TypeName {

    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Public Methods

    // MARK: - Private Methods
}

// MARK: - Extensions

extension TypeName {
    // Extension content
}

// MARK: - Protocol Conformance

extension TypeName: ProtocolName {
    // Protocol implementation
}
```

## Code Organization

**Property Order:**
1. Type properties (static)
2. Instance properties (stored)
3. Computed properties
4. Property observers

**Method Order:**
1. Lifecycle methods (init, deinit)
2. Public methods
3. Private methods

## SwiftLint Key Rules

**Line Length**: 120 characters max
```swift
// ✅ Good
let user = User(id: id, name: name, email: email)

// ❌ Too long
let user = User(id: userId, name: userName, email: userEmail, phoneNumber: userPhoneNumber, address: userAddress)
```

**Force Unwrapping**: Avoid `!` except in tests or guaranteed scenarios
```swift
// ❌ Dangerous
let name = user.name!

// ✅ Safe
guard let name = user.name else { return }
```

**Trailing Closures**: Use for single trailing closure
```swift
// ✅ Good
items.map { $0.id }

// ❌ Avoid
items.map({ $0.id })
```

## Swift 5 Modern Features

**Async/Await**:
```swift
func fetchUser(id: String) async throws -> User {
    let request = UserAPI.fetchUser(id: id)
    return try await networkClient.request(request)
}
```

**Result Type**:
```swift
func fetchUser(id: String) async -> Result<User, NetworkError> {
    do {
        let user = try await performFetch(id)
        return .success(user)
    } catch {
        return .failure(.networkError(error))
    }
}
```

**Property Wrappers**:
```swift
@Published var items: [Item] = []
@State private var isPresented = false
@Binding var selectedItem: Item?
```

## Access Control

```swift
// Public: API surface
public class NetworkClient { }

// Internal: Default, module-wide
class UserViewModel { }

// Private: File-scoped
private func helper() { }

// Private(set): Read public, write private
private(set) var count: Int = 0
```

## Error Handling

```swift
// Custom error enum
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingFailed(Error)
}

// Throwing function
func fetchData() throws -> Data {
    guard let url = URL(string: urlString) else {
        throw NetworkError.invalidURL
    }
    return try Data(contentsOf: url)
}

// Async throws
func fetchUser() async throws -> User {
    try await networkClient.request(.fetchUser)
}
```

## Protocol-Oriented Programming

```swift
// Protocol definition
protocol UserServiceProtocol {
    func fetchUser(id: String) async -> Result<User, NetworkError>
}

// Implementation
final class UserService: UserServiceProtocol {
    func fetchUser(id: String) async -> Result<User, NetworkError> {
        // Implementation
    }
}

// Dependency injection
class UserViewModel {
    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
}
```
