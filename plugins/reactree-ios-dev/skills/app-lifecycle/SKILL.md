---
name: "App Lifecycle"
description: "iOS/tvOS application lifecycle management including app launch, scene lifecycle, state restoration, and background tasks"
version: "2.0.0"
---

# App Lifecycle for iOS/tvOS

Complete guide to managing iOS/tvOS application lifecycle including app launch sequence, scene lifecycle (iOS 13+), state restoration, background tasks, and memory warnings.

## App Launch Sequence

### Application Lifecycle (Pre-iOS 13)

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    // 1. App launch
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("App did finish launching")

        // Setup app (networking, third-party SDKs, etc.)
        setupApplication()

        return true
    }

    // 2. App becomes active
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App did become active")
        // Restart tasks, refresh UI
    }

    // 3. App will resign active
    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active")
        // Pause ongoing tasks, disable timers
    }

    // 4. App enters background
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App did enter background")
        // Save data, release resources
        saveApplicationState()
    }

    // 5. App will enter foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        // Undo what was done in background
    }

    // 6. App will terminate
    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")
        // Save data, cleanup
        saveApplicationState()
    }

    private func setupApplication() {
        // Initialize third-party SDKs
        // Setup network monitoring
        // Configure appearance
    }

    private func saveApplicationState() {
        // Save user data
        // Persist state
    }
}
```

## Scene Lifecycle (iOS 13+)

### SceneDelegate

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // Scene created
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Setup window
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UIHostingController(rootView: ContentView())
        window?.makeKeyAndVisible()

        // Handle URL if launched via deep link
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }
    }

    // Scene disconnected
    func sceneDidDisconnect(_ scene: UIScene) {
        print("Scene did disconnect")
        // Release resources
    }

    // Scene became active
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("Scene did become active")
        // Restart paused tasks
        // Refresh UI
    }

    // Scene will resign active
    func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
        // Pause ongoing tasks
    }

    // Scene entered foreground
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("Scene will enter foreground")
        // Undo background changes
    }

    // Scene entered background
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("Scene did enter background")
        // Save data
        // Release resources
    }

    // Handle deep link
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleURL(url)
        }
    }

    private func handleURL(_ url: URL) {
        print("Handle URL: \(url)")
        // Deep link handling
    }
}
```

### SwiftUI App Lifecycle

```swift
import SwiftUI

@main
struct MyApp: App {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("App is active")
                handleActive()

            case .inactive:
                print("App is inactive")
                handleInactive()

            case .background:
                print("App is in background")
                handleBackground()

            @unknown default:
                break
            }
        }
    }

    private func handleActive() {
        // Refresh content
        // Restart timers
    }

    private func handleInactive() {
        // Pause animations
        // Save state
    }

    private func handleBackground() {
        // Save data
        // Stop network requests
    }
}
```

## State Restoration

### Save State

```swift
// Enable state restoration in AppDelegate
func application(
    _ application: UIApplication,
    shouldSaveSecureApplicationState coder: NSCoder
) -> Bool {
    return true
}

// ViewController state restoration
class UserDetailViewController: UIViewController {
    override var restorationIdentifier: String? {
        get { "UserDetailViewController" }
        set { }
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        // Save state
        coder.encode(userId, forKey: "userId")
        coder.encode(scrollPosition, forKey: "scrollPosition")
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)

        // Restore state
        userId = coder.decodeObject(forKey: "userId") as? String
        scrollPosition = coder.decodeDouble(forKey: "scrollPosition")
    }
}
```

### SwiftUI State Restoration

```swift
struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0
    @SceneStorage("searchText") private var searchText = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)

            SearchView(searchText: $searchText)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(1)
        }
    }
}

// @SceneStorage automatically saves and restores per-scene state
```

## Background Tasks

### Background Fetch

```swift
// Enable background modes in Xcode: Background fetch

@main
class AppDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set minimum background fetch interval
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            UIApplication.backgroundFetchIntervalMinimum
        )
        return true
    }

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            do {
                let newData = try await fetchNewData()
                completionHandler(newData ? .newData : .noData)
            } catch {
                completionHandler(.failed)
            }
        }
    }

    private func fetchNewData() async throws -> Bool {
        // Fetch data from server
        return false
    }
}
```

### Background URL Sessions

```swift
class BackgroundDownloadManager: NSObject {
    static let shared = BackgroundDownloadManager()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.app.backgroundSession"
        )
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func startDownload(url: URL) {
        let task = session.downloadTask(with: url)
        task.resume()
    }
}

extension BackgroundDownloadManager: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        print("Download completed: \(location)")
        // Move file to permanent location
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            print("Download failed: \(error)")
        }
    }
}

// AppDelegate
func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
) {
    // Store completion handler
    BackgroundDownloadManager.shared.completionHandler = completionHandler
}
```

## Memory Warnings

### Handle Low Memory

```swift
// UIViewController
override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()

    // Free up resources
    imageCache.removeAll()
    cancelPendingRequests()
}

// SwiftUI
struct ContentView: View {
    @State private var images: [UIImage] = []

    var body: some View {
        ScrollView {
            // Content
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            handleMemoryWarning()
        }
    }

    private func handleMemoryWarning() {
        images.removeAll()
        // Clear caches
    }
}

// Monitor memory usage
class MemoryMonitor {
    static func currentMemoryUsage() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? taskInfo.resident_size : 0
    }
}
```

## App Termination

### Clean Shutdown

```swift
func applicationWillTerminate(_ application: UIApplication) {
    // Save critical data
    UserDefaults.standard.synchronize()

    // Cancel network requests
    URLSession.shared.invalidateAndCancel()

    // Clear temporary files
    clearTempFiles()

    // Notify backend
    Task {
        await notifyBackendOfTermination()
    }
}

private func clearTempFiles() {
    let tmpDirectory = FileManager.default.temporaryDirectory
    try? FileManager.default.removeItem(at: tmpDirectory)
}
```

## Universal Links

### Handle Universal Links

```swift
// SceneDelegate
func scene(
    _ scene: UIScene,
    continue userActivity: NSUserActivity
) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
        return
    }

    handleUniversalLink(url)
}

private func handleUniversalLink(_ url: URL) {
    // Parse URL and navigate
    if url.pathComponents.contains("user") {
        let userId = url.lastPathComponent
        navigateToUser(id: userId)
    }
}

// Associated domains entitlement
// Add to Xcode: Signing & Capabilities → Associated Domains
// applinks:example.com
```

## Best Practices

### 1. Minimize Launch Time

```swift
// ✅ Good: Defer non-critical setup
func application(...didFinishLaunchingWithOptions...) -> Bool {
    setupCriticalServices()

    DispatchQueue.global().async {
        self.setupNonCriticalServices()
    }

    return true
}

// ❌ Avoid: Heavy work on main thread
func application(...didFinishLaunchingWithOptions...) -> Bool {
    setupEverything()  // Blocks UI!
    return true
}
```

### 2. Save State on Background

```swift
func sceneDidEnterBackground(_ scene: UIScene) {
    // Save immediately
    saveUserData()

    // Request extended time if needed
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    backgroundTask = UIApplication.shared.beginBackgroundTask {
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }

    Task {
        await performBackgroundSync()
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
}
```

### 3. Handle Termination Gracefully

```swift
// Save state on scene disconnect
func sceneDidDisconnect(_ scene: UIScene) {
    saveApplicationState()
}

// Also save periodically
Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
    saveApplicationState()
}
```

## References

- [App Lifecycle](https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle)
- [Scene Lifecycle](https://developer.apple.com/documentation/uikit/app_and_environment/scenes)
- [State Restoration](https://developer.apple.com/documentation/uikit/view_controllers/preserving_your_app_s_ui_across_launches)
- [Background Execution](https://developer.apple.com/documentation/backgroundtasks)
