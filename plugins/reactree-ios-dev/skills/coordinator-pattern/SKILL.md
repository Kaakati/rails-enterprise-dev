---
name: "Coordinator Pattern"
description: "Navigation coordination pattern for iOS/tvOS to decouple navigation logic from view controllers and manage app flow"
version: "2.0.0"
---

# Coordinator Pattern for iOS/tvOS

Complete guide to implementing the Coordinator pattern in SwiftUI and UIKit applications for clean navigation architecture and decoupled view logic.

## Core Concept

The Coordinator pattern separates navigation logic from view controllers/views, creating a dedicated object responsible for app flow.

### Benefits

- **Separation of Concerns**: Navigation logic separated from UI
- **Testability**: Navigation can be tested independently
- **Reusability**: Views don't know about navigation context
- **Deep Linking**: Centralized place to handle deep links
- **Dependency Injection**: Coordinators create and configure views

## SwiftUI Coordinator

### Basic Coordinator Protocol

```swift
protocol Coordinator: ObservableObject {
    associatedtype Route: Hashable
    var navigationPath: NavigationPath { get set }

    func navigate(to route: Route)
    func pop()
    func popToRoot()
}

// App coordinator
final class AppCoordinator: Coordinator {
    enum Route: Hashable {
        case home
        case userList
        case userDetail(userId: String)
        case settings
    }

    @Published var navigationPath = NavigationPath()

    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView(coordinator: self)
        case .userList:
            UserListView(coordinator: self)
        case .userDetail(let userId):
            UserDetailView(userId: userId, coordinator: self)
        case .settings:
            SettingsView(coordinator: self)
        }
    }
}
```

### NavigationStack Integration

```swift
struct CoordinatedApp: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            coordinator.view(for: .home)
                .navigationDestination(for: AppCoordinator.Route.self) { route in
                    coordinator.view(for: route)
                }
        }
        .environmentObject(coordinator)
    }
}

// Views using coordinator
struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        VStack {
            Button("View Users") {
                coordinator.navigate(to: .userList)
            }

            Button("Settings") {
                coordinator.navigate(to: .settings)
            }
        }
        .navigationTitle("Home")
    }
}

struct UserListView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var users: [User] = []

    var body: some View {
        List(users) { user in
            Button(user.name) {
                coordinator.navigate(to: .userDetail(userId: user.id))
            }
        }
        .navigationTitle("Users")
    }
}
```

## Hierarchical Coordinators

### Parent-Child Coordinator Pattern

```swift
protocol ParentCoordinator: AnyObject {
    var childCoordinators: [any Coordinator] { get set }

    func start(coordinator: any Coordinator)
    func didFinish(coordinator: any Coordinator)
}

extension ParentCoordinator {
    func start(coordinator: any Coordinator) {
        childCoordinators.append(coordinator)
    }

    func didFinish(coordinator: any Coordinator) {
        childCoordinators.removeAll { $0 === coordinator as AnyObject }
    }
}

// Tab coordinator managing child coordinators
final class TabCoordinator: ParentCoordinator {
    var childCoordinators: [any Coordinator] = []

    lazy var homeCoordinator = HomeCoordinator(parent: self)
    lazy var profileCoordinator = ProfileCoordinator(parent: self)
    lazy var settingsCoordinator = SettingsCoordinator(parent: self)

    @ViewBuilder
    func makeTabView() -> some View {
        TabView {
            homeCoordinator.start()
                .tabItem { Label("Home", systemImage: "house") }

            profileCoordinator.start()
                .tabItem { Label("Profile", systemImage: "person") }

            settingsCoordinator.start()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

// Child coordinator
final class HomeCoordinator: Coordinator {
    enum Route: Hashable {
        case home
        case feed
        case notifications
    }

    weak var parent: ParentCoordinator?
    @Published var navigationPath = NavigationPath()

    init(parent: ParentCoordinator) {
        self.parent = parent
    }

    func start() -> some View {
        NavigationStack(path: $navigationPath) {
            view(for: .home)
                .navigationDestination(for: Route.self) { route in
                    view(for: route)
                }
        }
    }

    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView(coordinator: self)
        case .feed:
            FeedView(coordinator: self)
        case .notifications:
            NotificationsView(coordinator: self)
        }
    }
}
```

## Deep Linking

### Deep Link Handling

```swift
enum DeepLink: Equatable {
    case user(id: String)
    case product(id: String)
    case settings(section: String)
    case notification(id: String)

    init?(url: URL) {
        guard url.scheme == "myapp" else { return nil }

        let components = url.pathComponents.dropFirst()

        switch url.host {
        case "user":
            guard let id = components.first else { return nil }
            self = .user(id: id)

        case "product":
            guard let id = components.first else { return nil }
            self = .product(id: id)

        case "settings":
            let section = components.first ?? "general"
            self = .settings(section: section)

        case "notification":
            guard let id = components.first else { return nil }
            self = .notification(id: id)

        default:
            return nil
        }
    }
}

final class AppCoordinator: Coordinator {
    func handle(deepLink: DeepLink) {
        popToRoot()

        switch deepLink {
        case .user(let id):
            navigate(to: .userList)
            navigate(to: .userDetail(userId: id))

        case .product(let id):
            navigate(to: .productList)
            navigate(to: .productDetail(productId: id))

        case .settings(let section):
            navigate(to: .settings)
            navigate(to: .settingsSection(section))

        case .notification(let id):
            navigate(to: .notifications)
            navigate(to: .notificationDetail(id))
        }
    }
}

// SwiftUI scene integration
@main
struct MyApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            CoordinatedApp()
                .onOpenURL { url in
                    if let deepLink = DeepLink(url: url) {
                        coordinator.handle(deepLink: deepLink)
                    }
                }
        }
    }
}
```

## UIKit Coordinator

### UIKit Coordinator Pattern

```swift
protocol UIKitCoordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [UIKitCoordinator] { get set }

    func start()
}

// Example coordinator
final class LoginCoordinator: UIKitCoordinator {
    let navigationController: UINavigationController
    var childCoordinators: [UIKitCoordinator] = []
    weak var parentCoordinator: UIKitCoordinator?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showLogin()
    }

    private func showLogin() {
        let viewModel = LoginViewModel(coordinator: self)
        let loginVC = LoginViewController(viewModel: viewModel)
        navigationController.pushViewController(loginVC, animated: true)
    }

    func didFinishLogin(user: User) {
        showHome(user: user)
    }

    private func showHome(user: User) {
        let homeCoordinator = HomeCoordinator(
            navigationController: navigationController,
            user: user
        )
        childCoordinators.append(homeCoordinator)
        homeCoordinator.start()
    }
}
```

## Modal Presentation

### Sheet Presentation

```swift
final class AppCoordinator: ObservableObject {
    enum Sheet: Identifiable {
        case settings
        case profile(userId: String)
        case compose

        var id: String {
            switch self {
            case .settings: return "settings"
            case .profile(let id): return "profile-\(id)"
            case .compose: return "compose"
            }
        }
    }

    @Published var activeSheet: Sheet?

    func presentSheet(_ sheet: Sheet) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    @ViewBuilder
    func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView(coordinator: self)
        case .profile(let userId):
            ProfileView(userId: userId, coordinator: self)
        case .compose:
            ComposeView(coordinator: self)
        }
    }
}

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack {
            HomeView(coordinator: coordinator)
        }
        .sheet(item: $coordinator.activeSheet) { sheet in
            coordinator.sheetView(for: sheet)
        }
    }
}
```

## Coordinator with Dependency Injection

### Factory Pattern

```swift
protocol CoordinatorFactory {
    func makeAppCoordinator() -> AppCoordinator
    func makeAuthCoordinator(parent: AppCoordinator) -> AuthCoordinator
    func makeHomeCoordinator(parent: AppCoordinator) -> HomeCoordinator
}

final class DefaultCoordinatorFactory: CoordinatorFactory {
    private let container: DependencyContainer

    init(container: DependencyContainer) {
        self.container = container
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(
            authService: container.authService,
            factory: self
        )
    }

    func makeAuthCoordinator(parent: AppCoordinator) -> AuthCoordinator {
        AuthCoordinator(
            parent: parent,
            authService: container.authService
        )
    }

    func makeHomeCoordinator(parent: AppCoordinator) -> HomeCoordinator {
        HomeCoordinator(
            parent: parent,
            userService: container.userService
        )
    }
}
```

## Testing Coordinators

### Coordinator Tests

```swift
final class AppCoordinatorTests: XCTestCase {
    var sut: AppCoordinator!

    override func setUp() {
        super.setUp()
        sut = AppCoordinator()
    }

    func testNavigateToUserList() {
        // When
        sut.navigate(to: .userList)

        // Then
        XCTAssertEqual(sut.navigationPath.count, 1)
    }

    func testPopToRoot() {
        // Given
        sut.navigate(to: .userList)
        sut.navigate(to: .userDetail(userId: "123"))

        // When
        sut.popToRoot()

        // Then
        XCTAssertEqual(sut.navigationPath.count, 0)
    }

    func testDeepLinkHandling() {
        // Given
        let url = URL(string: "myapp://user/123")!
        let deepLink = DeepLink(url: url)

        // When
        if let deepLink = deepLink {
            sut.handle(deepLink: deepLink)
        }

        // Then
        XCTAssertEqual(sut.navigationPath.count, 2)
    }
}
```

## Best Practices

### 1. Single Responsibility

```swift
// ✅ Good: One coordinator per feature
final class AuthCoordinator: Coordinator {
    // Handles only authentication flow
}

final class ProfileCoordinator: Coordinator {
    // Handles only profile flow
}

// ❌ Avoid: God coordinator
final class AppCoordinator: Coordinator {
    // Handles everything
}
```

### 2. Weak Parent References

```swift
// ✅ Good: Weak parent to prevent retain cycles
final class ChildCoordinator: Coordinator {
    weak var parent: ParentCoordinator?
}

// ❌ Avoid: Strong parent reference
final class ChildCoordinator: Coordinator {
    var parent: ParentCoordinator  // Retain cycle!
}
```

### 3. View Doesn't Know About Navigation

```swift
// ✅ Good: View delegates navigation to coordinator
struct UserDetailView: View {
    let coordinator: AppCoordinator

    var body: some View {
        Button("Edit") {
            coordinator.navigate(to: .editUser)
        }
    }
}

// ❌ Avoid: View knows about NavigationLink
struct UserDetailView: View {
    var body: some View {
        NavigationLink("Edit", destination: EditUserView())
    }
}
```

## References

- [Coordinator Pattern](https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps)
- [SwiftUI Navigation](https://developer.apple.com/documentation/swiftui/navigation)
- [Advanced Coordinators](https://www.swiftbysundell.com/articles/navigation-in-swiftui/)
