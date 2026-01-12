---
name: "Dependency Injection"
description: "Dependency injection patterns for iOS/tvOS including constructor injection, protocol-based DI, and SwiftUI environment injection"
version: "2.0.0"
---

# Dependency Injection for iOS/tvOS

Complete guide to implementing dependency injection in Swift and SwiftUI applications using constructor injection, protocol-based patterns, environment objects, and DI containers.

## Constructor Injection

### Basic Constructor Injection

```swift
// Protocol defining dependency
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
}

// Concrete implementation
final class UserService: UserServiceProtocol {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchUser(id: String) async throws -> User {
        try await networkManager.request(.getUser(id: id))
    }
}

// ViewModel with constructor injection
@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User?
    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    func loadUser(id: String) async {
        do {
            user = try await userService.fetchUser(id: id)
        } catch {
            print("Error: \(error)")
        }
    }
}

// Usage
let networkManager = NetworkManager()
let userService = UserService(networkManager: networkManager)
let viewModel = UserViewModel(userService: userService)
```

### Default Parameters for Flexibility

```swift
@MainActor
final class UserViewModel: ObservableObject {
    private let userService: UserServiceProtocol
    private let analytics: AnalyticsProtocol

    init(
        userService: UserServiceProtocol = UserService.shared,
        analytics: AnalyticsProtocol = Analytics.shared
    ) {
        self.userService = userService
        self.analytics = analytics
    }
}

// Production usage (uses defaults)
let viewModel = UserViewModel()

// Testing usage (injects mocks)
let viewModel = UserViewModel(
    userService: MockUserService(),
    analytics: MockAnalytics()
)
```

## Protocol-Based Dependency Injection

### Defining Protocols

```swift
// Service protocol
protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
    func refreshToken() async throws -> String
}

// Repository protocol
protocol UserRepositoryProtocol {
    func getUser(id: String) async throws -> User
    func saveUser(_ user: User) async throws
    func deleteUser(id: String) async throws
}

// Network protocol
protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}
```

### Concrete Implementations

```swift
final class AuthenticationService: AuthenticationServiceProtocol {
    private let networkManager: NetworkManagerProtocol
    private let sessionManager: SessionManagerProtocol

    init(
        networkManager: NetworkManagerProtocol,
        sessionManager: SessionManagerProtocol
    ) {
        self.networkManager = networkManager
        self.sessionManager = sessionManager
    }

    func login(email: String, password: String) async throws -> User {
        let credentials = LoginCredentials(email: email, password: password)
        let response: LoginResponse = try await networkManager.request(.login(credentials))

        await sessionManager.saveToken(response.token)
        return response.user
    }

    func logout() async throws {
        try await networkManager.request(.logout)
        await sessionManager.clearSession()
    }

    func refreshToken() async throws -> String {
        let response: TokenResponse = try await networkManager.request(.refreshToken)
        await sessionManager.saveToken(response.token)
        return response.token
    }
}
```

## SwiftUI Environment Injection

### @EnvironmentObject

```swift
// AppDependencies as EnvironmentObject
final class AppDependencies: ObservableObject {
    let userService: UserServiceProtocol
    let authService: AuthenticationServiceProtocol
    let analytics: AnalyticsProtocol

    init(
        userService: UserServiceProtocol = UserService(),
        authService: AuthenticationServiceProtocol = AuthenticationService(),
        analytics: AnalyticsProtocol = Analytics()
    ) {
        self.userService = userService
        self.authService = authService
        self.analytics = analytics
    }
}

// App setup
@main
struct MyApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
        }
    }
}

// View consuming dependencies
struct UserListView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @State private var users: [User] = []

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .task {
            do {
                users = try await dependencies.userService.fetchAllUsers()
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

### Custom Environment Keys

```swift
// Define environment key
private struct UserServiceKey: EnvironmentKey {
    static let defaultValue: UserServiceProtocol = UserService.shared
}

extension EnvironmentValues {
    var userService: UserServiceProtocol {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

// Inject dependency
struct ContentView: View {
    var body: some View {
        UserListView()
            .environment(\.userService, UserService())
    }
}

// Consume dependency
struct UserListView: View {
    @Environment(\.userService) var userService

    var body: some View {
        List {
            // ...
        }
        .task {
            let users = try? await userService.fetchAllUsers()
        }
    }
}
```

## Dependency Injection Container

### Simple DI Container

```swift
final class DependencyContainer {
    static let shared = DependencyContainer()

    private init() {
        registerDependencies()
    }

    // Registered services
    private(set) lazy var networkManager: NetworkManagerProtocol = NetworkManager()
    private(set) lazy var sessionManager: SessionManagerProtocol = SessionManager()
    private(set) lazy var userService: UserServiceProtocol = UserService(
        networkManager: networkManager
    )
    private(set) lazy var authService: AuthenticationServiceProtocol = AuthenticationService(
        networkManager: networkManager,
        sessionManager: sessionManager
    )

    private func registerDependencies() {
        // Additional setup if needed
    }

    // Factory methods for scoped instances
    func makeUserViewModel() -> UserViewModel {
        UserViewModel(userService: userService)
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authService: authService)
    }
}

// Usage
let container = DependencyContainer.shared
let viewModel = container.makeUserViewModel()
```

### Protocol-Based Container

```swift
protocol DependencyContainerProtocol {
    var userService: UserServiceProtocol { get }
    var authService: AuthenticationServiceProtocol { get }
    var analytics: AnalyticsProtocol { get }
}

final class AppDependencyContainer: DependencyContainerProtocol {
    lazy var userService: UserServiceProtocol = UserService()
    lazy var authService: AuthenticationServiceProtocol = AuthenticationService()
    lazy var analytics: AnalyticsProtocol = Analytics()
}

final class TestDependencyContainer: DependencyContainerProtocol {
    lazy var userService: UserServiceProtocol = MockUserService()
    lazy var authService: AuthenticationServiceProtocol = MockAuthService()
    lazy var analytics: AnalyticsProtocol = MockAnalytics()
}
```

## Factory Pattern

### Simple Factory

```swift
protocol ViewModelFactory {
    func makeUserViewModel() -> UserViewModel
    func makeLoginViewModel() -> LoginViewModel
    func makeProfileViewModel(user: User) -> ProfileViewModel
}

final class DefaultViewModelFactory: ViewModelFactory {
    private let container: DependencyContainerProtocol

    init(container: DependencyContainerProtocol) {
        self.container = container
    }

    func makeUserViewModel() -> UserViewModel {
        UserViewModel(userService: container.userService)
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authService: container.authService)
    }

    func makeProfileViewModel(user: User) -> ProfileViewModel {
        ProfileViewModel(
            user: user,
            userService: container.userService,
            analytics: container.analytics
        )
    }
}
```

### Factory with Builder Pattern

```swift
final class ViewModelBuilder {
    private var userService: UserServiceProtocol?
    private var authService: AuthenticationServiceProtocol?
    private var analytics: AnalyticsProtocol?

    func with(userService: UserServiceProtocol) -> Self {
        self.userService = userService
        return self
    }

    func with(authService: AuthenticationServiceProtocol) -> Self {
        self.authService = authService
        return self
    }

    func with(analytics: AnalyticsProtocol) -> Self {
        self.analytics = analytics
        return self
    }

    func build() -> UserViewModel {
        UserViewModel(
            userService: userService ?? UserService.shared,
            authService: authService ?? AuthenticationService.shared,
            analytics: analytics ?? Analytics.shared
        )
    }
}

// Usage
let viewModel = ViewModelBuilder()
    .with(userService: UserService())
    .with(analytics: Analytics())
    .build()
```

## Mock Injection for Testing

### Mock Implementations

```swift
// Mock user service
final class MockUserService: UserServiceProtocol {
    var users: [User] = []
    var shouldThrowError = false
    var fetchUserCallCount = 0

    func fetchUser(id: String) async throws -> User {
        fetchUserCallCount += 1

        if shouldThrowError {
            throw NetworkError.serverError(statusCode: 500, message: nil)
        }

        guard let user = users.first(where: { $0.id == id }) else {
            throw NetworkError.notFound
        }

        return user
    }

    func fetchAllUsers() async throws -> [User] {
        if shouldThrowError {
            throw NetworkError.serverError(statusCode: 500, message: nil)
        }
        return users
    }
}

// Testing with mocks
@MainActor
final class UserViewModelTests: XCTestCase {
    func testLoadUserSuccess() async {
        // Given
        let mockService = MockUserService()
        mockService.users = [User(id: "123", name: "John")]

        let viewModel = UserViewModel(userService: mockService)

        // When
        await viewModel.loadUser(id: "123")

        // Then
        XCTAssertNotNil(viewModel.user)
        XCTAssertEqual(viewModel.user?.name, "John")
        XCTAssertEqual(mockService.fetchUserCallCount, 1)
    }

    func testLoadUserFailure() async {
        // Given
        let mockService = MockUserService()
        mockService.shouldThrowError = true

        let viewModel = UserViewModel(userService: mockService)

        // When
        await viewModel.loadUser(id: "123")

        // Then
        XCTAssertNil(viewModel.user)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
```

## Singleton vs Dependency Injection

### When to Use Singletons

```swift
// ✅ Good: Singleton for truly global state
final class AppConfiguration {
    static let shared = AppConfiguration()

    let apiBaseURL: String
    let environment: Environment

    private init() {
        #if DEBUG
        self.environment = .development
        self.apiBaseURL = "https://dev.api.example.com"
        #else
        self.environment = .production
        self.apiBaseURL = "https://api.example.com"
        #endif
    }
}

// ❌ Avoid: Singleton for testable services
final class UserService {
    static let shared = UserService()  // Hard to test!

    func fetchUser(id: String) async throws -> User {
        // ...
    }
}
```

### Converting Singleton to DI

```swift
// Before: Singleton
final class UserService {
    static let shared = UserService()

    private init() {}

    func fetchUser(id: String) async throws -> User {
        // Implementation
    }
}

// After: Dependency injection
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
}

final class UserService: UserServiceProtocol {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchUser(id: String) async throws -> User {
        // Implementation
    }
}

// Shared instance for convenience (optional)
extension UserService {
    static let shared = UserService(networkManager: NetworkManager.shared)
}
```

## Service Locator Pattern (Anti-Pattern)

### Why to Avoid

```swift
// ❌ Avoid: Service Locator
final class ServiceLocator {
    static let shared = ServiceLocator()

    private var services: [String: Any] = [:]

    func register<T>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        services[key] = service
    }

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
}

// Problems:
// 1. Hidden dependencies (not visible in initializer)
// 2. Runtime errors if service not registered
// 3. Difficult to test
// 4. Tight coupling to ServiceLocator

// ✅ Good: Explicit constructor injection
final class UserViewModel {
    private let userService: UserServiceProtocol  // Dependency is explicit

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
}
```

## Best Practices

### 1. Depend on Abstractions

```swift
// ✅ Good: Depend on protocol
final class UserViewModel {
    private let userService: UserServiceProtocol  // Abstract

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
}

// ❌ Avoid: Depend on concrete class
final class UserViewModel {
    private let userService: UserService  // Concrete

    init(userService: UserService) {
        self.userService = userService
    }
}
```

### 2. Constructor Injection Over Property Injection

```swift
// ✅ Good: Constructor injection
final class UserViewModel {
    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
}

// ❌ Avoid: Property injection
final class UserViewModel {
    var userService: UserServiceProtocol!  // Can be nil!

    init() {}
}
```

### 3. Keep Containers Simple

```swift
// ✅ Good: Simple, focused container
final class ServiceContainer {
    lazy var userService: UserServiceProtocol = UserService(networkManager: networkManager)
    lazy var networkManager: NetworkManagerProtocol = NetworkManager()
}

// ❌ Avoid: Over-complicated container
final class MegaContainer {
    // 100+ dependencies
    // Complex registration logic
    // Circular dependency resolution
}
```

## References

- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Testing with Mocks](https://www.swiftbysundell.com/articles/mocking-in-swift/)
