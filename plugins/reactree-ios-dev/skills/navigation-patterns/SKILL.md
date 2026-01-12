---
name: "Navigation Patterns"
description: "Comprehensive SwiftUI NavigationStack and routing patterns for iOS/tvOS development"
version: "2.0.0"
---

# Navigation Patterns for iOS/tvOS

Complete guide to implementing navigation in SwiftUI using NavigationStack (iOS 16+), NavigationPath, deep linking, and programmatic navigation.

## Core Navigation Concepts

### NavigationStack (iOS 16+)

**Modern Approach:**
```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Detail") {
                    DetailView()
                }
            }
            .navigationTitle("Home")
        }
    }
}
```

**Key Benefits:**
- Type-safe navigation
- Programmatic control via NavigationPath
- Improved performance over deprecated NavigationView
- Deep linking support
- State restoration capabilities

### Navigation with Value-Based Routing

```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .navigationTitle("Items")
        }
    }
}
```

## NavigationPath Management

### Basic NavigationPath

```swift
final class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()

    func navigateTo(_ destination: AnyHashable) {
        path.append(destination)
    }

    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
```

### Type-Safe NavigationPath

```swift
// Define navigation destinations
enum Route: Hashable {
    case home
    case profile(userId: String)
    case settings
    case detail(itemId: Int)
}

final class Router: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to route: Route) {
        path.append(route)
    }

    func back() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func reset() {
        path = NavigationPath()
    }
}

// Usage in View
struct ContentView: View {
    @StateObject private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
        .environmentObject(router)
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView()
        case .profile(let userId):
            ProfileView(userId: userId)
        case .settings:
            SettingsView()
        case .detail(let itemId):
            DetailView(itemId: itemId)
        }
    }
}
```

## Deep Linking

### URL Scheme Registration

**Info.plist:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourapp.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

### Deep Link Handling

```swift
@main
struct YourApp: App {
    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "yourapp" else { return }

        // Parse URL: yourapp://profile/123
        let path = url.path
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }

        switch components.first {
        case "profile":
            if let userId = components.last {
                router.navigate(to: .profile(userId: userId))
            }
        case "settings":
            router.navigate(to: .settings)
        default:
            break
        }
    }
}
```

### Universal Links

**apple-app-site-association (on server):**
```json
{
    "applinks": {
        "apps": [],
        "details": [
            {
                "appID": "TEAMID.com.yourapp",
                "paths": ["/items/*", "/profile/*"]
            }
        ]
    }
}
```

**SwiftUI Handling:**
```swift
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
    guard let url = userActivity.webpageURL else { return }
    handleUniversalLink(url)
}

private func handleUniversalLink(_ url: URL) {
    // Parse: https://yourapp.com/items/123
    let path = url.path

    if path.hasPrefix("/items/"), let itemId = Int(path.replacingOccurrences(of: "/items/", with: "")) {
        router.navigate(to: .detail(itemId: itemId))
    }
}
```

## Tab Bar + NavigationStack Coordination

### Proper Architecture

```swift
enum Tab: Hashable {
    case home
    case search
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var homeRouter = Router()
    @StateObject private var searchRouter = Router()
    @StateObject private var profileRouter = Router()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack(path: $homeRouter.path) {
                HomeView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(Tab.home)
            .environmentObject(homeRouter)

            // Search Tab
            NavigationStack(path: $searchRouter.path) {
                SearchView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)
            .environmentObject(searchRouter)

            // Profile Tab
            NavigationStack(path: $profileRouter.path) {
                ProfileView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(Tab.profile)
            .environmentObject(profileRouter)
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        // Shared destination view builder
        switch route {
        case .home: HomeView()
        case .profile(let userId): ProfileDetailView(userId: userId)
        case .settings: SettingsView()
        case .detail(let itemId): ItemDetailView(itemId: itemId)
        }
    }
}
```

## Modal Presentation

### Sheet Presentation

```swift
struct HomeView: View {
    @State private var showingSettings = false
    @State private var selectedItem: Item?

    var body: some View {
        List(items) { item in
            Button(item.name) {
                selectedItem = item
            }
        }
        .sheet(item: $selectedItem) { item in
            NavigationStack {
                ItemDetailView(item: item)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                selectedItem = nil
                            }
                        }
                    }
            }
        }
        .toolbar {
            Button("Settings") {
                showingSettings = true
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}
```

### Full Screen Cover

```swift
struct ContentView: View {
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            // Content
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}
```

### Confirmation Dialog

```swift
struct ItemRow: View {
    let item: Item
    @State private var showingOptions = false

    var body: some View {
        Button(item.name) {
            showingOptions = true
        }
        .confirmationDialog("Options", isPresented: $showingOptions) {
            Button("Edit") { /* ... */ }
            Button("Share") { /* ... */ }
            Button("Delete", role: .destructive) { /* ... */ }
        }
    }
}
```

## Programmatic Navigation

### Navigate on Action

```swift
struct LoginView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack {
            // Login form
        }
        .onChange(of: viewModel.isAuthenticated) { isAuth in
            if isAuth {
                router.navigate(to: .home)
            }
        }
    }
}
```

### Navigate from ViewModel

```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isAuthenticated = false
    private let router: Router

    init(router: Router) {
        self.router = router
    }

    func login() async {
        // Perform login
        isAuthenticated = true
        router.navigate(to: .home)
    }
}

// Inject router in View
struct LoginView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel: LoginViewModel

    init(router: Router) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(router: router))
    }

    var body: some View {
        VStack {
            Button("Login") {
                Task {
                    await viewModel.login()
                }
            }
        }
    }
}
```

## tvOS-Specific Navigation

### Focus Management

```swift
struct tvOSMenuView: View {
    @FocusState private var focusedItem: MenuItem?

    enum MenuItem: Hashable {
        case home
        case movies
        case tvShows
        case settings
    }

    var body: some View {
        VStack(spacing: 20) {
            ForEach([MenuItem.home, .movies, .tvShows, .settings], id: \.self) { item in
                Button(item.title) {
                    // Navigate
                }
                .focused($focusedItem, equals: item)
            }
        }
        .onAppear {
            focusedItem = .home
        }
    }
}
```

### Remote Control Navigation

```swift
struct tvOSNavigationView: View {
    var body: some View {
        NavigationStack {
            ContentView()
                .onPlayPauseCommand {
                    // Handle play/pause button
                }
                .onExitCommand {
                    // Handle menu button (back navigation)
                }
        }
    }
}
```

## Best Practices

### 1. Use NavigationStack over NavigationView

**✅ Good:**
```swift
NavigationStack(path: $path) {
    ContentView()
}
```

**❌ Avoid:**
```swift
NavigationView {  // Deprecated in iOS 16
    ContentView()
}
```

### 2. Centralize Navigation Logic

```swift
// Router as single source of truth
@EnvironmentObject var router: Router

// Avoid scattered @State navigation flags
// ❌ Bad:
@State private var showDetail = false
@State private var showSettings = false
@State private var showProfile = false
```

### 3. Type-Safe Routes

```swift
// Use enums for type safety
enum Route: Hashable {
    case detail(id: Int)
}

// Avoid stringly-typed navigation
// ❌ Bad: navigateTo("detail/123")
```

### 4. Handle Back Button Properly

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("Back") {
            router.back()
        }
    }
}
```

### 5. Test Navigation Flows

```swift
final class RouterTests: XCTestCase {
    func testNavigationToDetail() {
        let router = Router()
        router.navigate(to: .detail(itemId: 123))

        XCTAssertEqual(router.path.count, 1)
    }

    func testBackNavigation() {
        let router = Router()
        router.navigate(to: .detail(itemId: 123))
        router.back()

        XCTAssertEqual(router.path.count, 0)
    }
}
```

## Common Pitfalls

### 1. Memory Leaks in NavigationPath

**Issue:** Retaining references in closures
**Fix:** Use `[weak self]` in closures

### 2. Lost Navigation State

**Issue:** Not persisting NavigationPath on app termination
**Fix:** Save/restore path using SceneStorage or UserDefaults

```swift
@SceneStorage("navigationPath") private var pathData: Data = Data()

var body: some View {
    NavigationStack(path: $path) {
        // ...
    }
    .onAppear {
        restorePath()
    }
    .onChange(of: path) { _ in
        savePath()
    }
}
```

### 3. Deep Link Race Conditions

**Issue:** Deep link processed before view hierarchy ready
**Fix:** Delay navigation until onAppear

```swift
@State private var pendingDeepLink: URL?

var body: some View {
    NavigationStack {
        ContentView()
            .onAppear {
                if let url = pendingDeepLink {
                    handleDeepLink(url)
                    pendingDeepLink = nil
                }
            }
    }
    .onOpenURL { url in
        pendingDeepLink = url
    }
}
```

## References

- [Human Interface Guidelines - Navigation](https://developer.apple.com/design/human-interface-guidelines/navigation)
- [NavigationStack Documentation](https://developer.apple.com/documentation/swiftui/navigationstack)
- [Universal Links Guide](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
