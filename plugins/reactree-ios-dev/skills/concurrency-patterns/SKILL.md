---
name: "Concurrency Patterns"
description: "Modern Swift concurrency with async/await, actors, structured concurrency, and AsyncSequence patterns for iOS/tvOS"
version: "2.0.0"
---

# Concurrency Patterns for iOS/tvOS

Complete guide to modern Swift concurrency using async/await, actors, structured concurrency, and migration from Grand Central Dispatch (GCD) to structured concurrency patterns.

## Async/Await Fundamentals

### Basic Async Functions

```swift
// Async function declaration
func fetchUser(id: String) async throws -> User {
    // Suspend execution until network request completes
    let (data, _) = try await URLSession.shared.data(from: url)
    let user = try JSONDecoder().decode(User.self, from: data)
    return user
}

// Calling async function
Task {
    do {
        let user = try await fetchUser(id: "123")
        print("User: \(user.name)")
    } catch {
        print("Error: \(error)")
    }
}
```

### Async Properties

```swift
class UserService {
    // Async property getter
    var currentUser: User {
        get async throws {
            try await fetchUser(id: getCurrentUserId())
        }
    }

    // Read-only async property
    private(set) var cachedUsers: [User] = []

    func loadUsers() async throws {
        cachedUsers = try await fetchAllUsers()
    }
}
```

### Async Sequences

```swift
// AsyncSequence for streaming data
func fetchMessages() -> AsyncStream<Message> {
    AsyncStream { continuation in
        // WebSocket connection
        let socket = WebSocket(url: messageURL)

        socket.onMessage = { message in
            continuation.yield(message)
        }

        socket.onClose = {
            continuation.finish()
        }

        socket.connect()
    }
}

// Consuming async sequence
for await message in fetchMessages() {
    print("New message: \(message.content)")
}
```

## Task and TaskGroup

### Creating Tasks

```swift
// Unstructured task
Task {
    let user = try await fetchUser(id: "123")
    print(user)
}

// Detached task (no inheritance of priority or task-local values)
Task.detached {
    let result = await heavyComputation()
    print(result)
}

// Task with priority
Task(priority: .high) {
    let urgentData = try await fetchUrgentData()
    processData(urgentData)
}
```

### Task Values and Cancellation

```swift
// Task returns a value
let task = Task {
    try await fetchUser(id: "123")
}

// Get task result
let user = try await task.value

// Check if task is cancelled
Task {
    for i in 0..<100 {
        // Check for cancellation
        if Task.isCancelled {
            print("Task was cancelled")
            break
        }

        await processItem(i)
    }
}

// Cancel task
task.cancel()

// Throwing cancellation error
Task {
    for i in 0..<100 {
        // Throws CancellationError if cancelled
        try Task.checkCancellation()
        await processItem(i)
    }
}
```

### TaskGroup for Parallel Execution

```swift
// Parallel execution with results
func fetchAllUsers(ids: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        // Add tasks to group
        for id in ids {
            group.addTask {
                try await fetchUser(id: id)
            }
        }

        // Collect results
        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}

// Non-throwing variant
func fetchAllImages(urls: [URL]) async -> [UIImage] {
    await withTaskGroup(of: UIImage?.self) { group in
        for url in urls {
            group.addTask {
                try? await downloadImage(from: url)
            }
        }

        var images: [UIImage] = []
        for await image in group {
            if let image = image {
                images.append(image)
            }
        }
        return images
    }
}
```

### Dynamic Task Creation

```swift
func processItemsInBatches(items: [Item]) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        for batch in items.chunked(into: 10) {
            // Limit concurrent tasks
            if group.taskCount >= 5 {
                // Wait for one to complete
                try await group.next()
            }

            group.addTask {
                try await processBatch(batch)
            }
        }

        // Wait for all remaining tasks
        try await group.waitForAll()
    }
}
```

## Actor Isolation

### Basic Actor

```swift
// Actor for thread-safe mutable state
actor UserCache {
    private var cache: [String: User] = [:]

    func getUser(id: String) -> User? {
        cache[id]
    }

    func setUser(_ user: User) {
        cache[user.id] = user
    }

    func clear() {
        cache.removeAll()
    }
}

// Usage (all access is async)
let cache = UserCache()

Task {
    await cache.setUser(user)
    let cachedUser = await cache.getUser(id: "123")
}
```

### Actor Reentrancy

```swift
actor BankAccount {
    var balance: Double = 0

    func deposit(amount: Double) {
        balance += amount
    }

    func withdraw(amount: Double) async throws {
        // Suspension point - actor can be reentered
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Balance might have changed during suspension!
        guard balance >= amount else {
            throw BankError.insufficientFunds
        }

        balance -= amount
    }

    // Non-isolated method (no actor isolation)
    nonisolated func getAccountNumber() -> String {
        "ACC-123"  // Can only access immutable or nonisolated data
    }
}
```

### Global Actor Pattern

```swift
// Custom global actor
@globalActor
actor DatabaseActor {
    static let shared = DatabaseActor()
}

// Apply to type
@DatabaseActor
class DatabaseManager {
    var connection: DatabaseConnection?

    func query(_ sql: String) async throws -> [Row] {
        // Automatically isolated to DatabaseActor
        try await connection?.execute(sql)
    }
}

// Apply to function
@DatabaseActor
func migrateDatabase() async throws {
    // Runs on DatabaseActor
}
```

## @MainActor for UI Updates

### UI Updates on Main Thread

```swift
// ViewModel isolated to main actor
@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadUser(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Network call can be off main thread
            user = try await fetchUser(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// SwiftUI View (always @MainActor)
struct UserView: View {
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                Text("User: \(user.name)")
            }
        }
        .task {
            await viewModel.loadUser(id: "123")
        }
    }
}
```

### Mixing Main and Background Work

```swift
@MainActor
final class ImageProcessor: ObservableObject {
    @Published var processedImage: UIImage?

    func processImage(_ image: UIImage) async {
        // Update UI immediately
        processedImage = nil

        // Heavy processing off main thread
        let processed = await Task.detached {
            // Background processing
            return Self.applyFilters(to: image)
        }.value

        // Update UI on main thread
        processedImage = processed
    }

    // Non-isolated static method
    nonisolated static func applyFilters(to image: UIImage) -> UIImage {
        // Heavy image processing
        return image  // Processed image
    }
}
```

### Escaping to Main Actor

```swift
class NetworkManager {
    func fetchData() async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)

        // Explicitly run on main actor
        await MainActor.run {
            // Update UI or main-actor-isolated state
            NotificationCenter.default.post(name: .dataLoaded, object: nil)
        }

        return data
    }
}
```

## Sendable Protocol

### Sendable Types

```swift
// Structs with Sendable properties are implicitly Sendable
struct User: Sendable {
    let id: String
    let name: String
    let email: String
}

// Explicit Sendable conformance
final class DatabaseConnection: @unchecked Sendable {
    // @unchecked: We guarantee thread safety manually
    private let lock = NSLock()
    private var connection: Connection?

    func execute(_ query: String) async throws {
        lock.lock()
        defer { lock.unlock() }
        // Thread-safe implementation
    }
}

// Functions can be Sendable
let sendableFunction: @Sendable (String) -> Void = { text in
    print(text)
}
```

### Non-Sendable Types

```swift
// Classes are not Sendable by default
class MutableCache {
    var cache: [String: Any] = [:]  // Not thread-safe
}

// This would be a compile error:
// extension MutableCache: Sendable {}

// Solution: Use actor
actor SafeCache {
    var cache: [String: Any] = [:]  // Thread-safe via actor
}
```

## Structured Concurrency

### Task Tree and Cancellation Propagation

```swift
func processOrderWithItems(orderId: String) async throws {
    // Parent task
    try await withThrowingTaskGroup(of: Void.self) { group in
        // Child task 1: Fetch order
        group.addTask {
            let order = try await fetchOrder(id: orderId)
            print("Order: \(order)")
        }

        // Child task 2: Fetch items
        group.addTask {
            let items = try await fetchOrderItems(orderId: orderId)
            print("Items: \(items)")
        }

        // If parent is cancelled, all children are cancelled
        // If any child throws, all siblings are cancelled
        try await group.waitForAll()
    }
}
```

### Task Locals

```swift
enum RequestID {
    @TaskLocal static var current: String = ""
}

func handleRequest() async {
    await RequestID.$current.withValue(UUID().uuidString) {
        // All child tasks inherit this value
        await processRequest()
    }
}

func processRequest() async {
    // Access task-local value
    print("Request ID: \(RequestID.current)")

    // Child tasks inherit value
    Task {
        print("Child Request ID: \(RequestID.current)")  // Same ID
    }
}
```

## AsyncSequence Patterns

### Custom AsyncSequence

```swift
struct CountdownSequence: AsyncSequence {
    typealias Element = Int

    let start: Int
    let delay: Duration

    struct AsyncIterator: AsyncIteratorProtocol {
        var current: Int
        let delay: Duration

        mutating func next() async -> Int? {
            guard current >= 0 else {
                return nil
            }

            let value = current
            current -= 1

            if current >= 0 {
                try? await Task.sleep(for: delay)
            }

            return value
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(current: start, delay: delay)
    }
}

// Usage
for await number in CountdownSequence(start: 10, delay: .seconds(1)) {
    print(number)  // 10, 9, 8, ..., 0
}
```

### AsyncStream

```swift
// Simple AsyncStream
let stream = AsyncStream<Int> { continuation in
    Task {
        for i in 0..<10 {
            continuation.yield(i)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        continuation.finish()
    }
}

// Consuming stream
for await value in stream {
    print(value)
}

// AsyncStream with buffering
let bufferedStream = AsyncStream<String>(bufferingPolicy: .bufferingNewest(5)) { continuation in
    // Drops oldest values if buffer is full
}
```

### AsyncThrowingStream

```swift
func monitorLocationUpdates() -> AsyncThrowingStream<Location, Error> {
    AsyncThrowingStream { continuation in
        let locationManager = LocationManager()

        locationManager.onLocation = { location in
            continuation.yield(location)
        }

        locationManager.onError = { error in
            continuation.finish(throwing: error)
        }

        locationManager.startUpdating()

        continuation.onTermination = { @Sendable _ in
            locationManager.stopUpdating()
        }
    }
}

// Usage
do {
    for try await location in monitorLocationUpdates() {
        print("Location: \(location)")
    }
} catch {
    print("Error: \(error)")
}
```

## Async Let Bindings

### Parallel Async Calls

```swift
func loadDashboard() async throws -> Dashboard {
    // Execute in parallel
    async let user = fetchUser()
    async let stats = fetchStatistics()
    async let notifications = fetchNotifications()

    // Wait for all results
    return try await Dashboard(
        user: user,
        stats: stats,
        notifications: notifications
    )
}

// Equivalent TaskGroup version
func loadDashboardTaskGroup() async throws -> Dashboard {
    try await withThrowingTaskGroup(of: DashboardComponent.self) { group in
        group.addTask { .user(try await fetchUser()) }
        group.addTask { .stats(try await fetchStatistics()) }
        group.addTask { .notifications(try await fetchNotifications()) }

        var user: User?
        var stats: Statistics?
        var notifications: [Notification]?

        for try await component in group {
            switch component {
            case .user(let u): user = u
            case .stats(let s): stats = s
            case .notifications(let n): notifications = n
            }
        }

        return Dashboard(user: user!, stats: stats!, notifications: notifications!)
    }
}
```

## Migrating from GCD to Structured Concurrency

### DispatchQueue → async/await

```swift
// Old GCD approach
func fetchUserOld(completion: @escaping (Result<User, Error>) -> Void) {
    DispatchQueue.global().async {
        // Background work
        let result = performNetworkRequest()

        DispatchQueue.main.async {
            completion(result)
        }
    }
}

// New async/await approach
func fetchUser() async throws -> User {
    // Automatically runs on background
    let user = try await performNetworkRequest()

    // Update UI on main actor
    await MainActor.run {
        // UI updates
    }

    return user
}
```

### Serial Queue → Actor

```swift
// Old: Serial queue for thread safety
class OldUserCache {
    private var cache: [String: User] = [:]
    private let queue = DispatchQueue(label: "cache.queue")

    func getUser(id: String) -> User? {
        queue.sync {
            cache[id]
        }
    }

    func setUser(_ user: User) {
        queue.async {
            self.cache[user.id] = user
        }
    }
}

// New: Actor for thread safety
actor NewUserCache {
    private var cache: [String: User] = [:]

    func getUser(id: String) -> User? {
        cache[id]
    }

    func setUser(_ user: User) {
        cache[user.id] = user
    }
}
```

### DispatchGroup → TaskGroup

```swift
// Old: DispatchGroup
func fetchAllUsersOld(ids: [String], completion: @escaping ([User]) -> Void) {
    let group = DispatchGroup()
    var users: [User] = []
    let lock = NSLock()

    for id in ids {
        group.enter()
        fetchUser(id: id) { result in
            if case .success(let user) = result {
                lock.lock()
                users.append(user)
                lock.unlock()
            }
            group.leave()
        }
    }

    group.notify(queue: .main) {
        completion(users)
    }
}

// New: TaskGroup
func fetchAllUsers(ids: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                try await fetchUser(id: id)
            }
        }

        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

## Continuation for Bridging Callback APIs

### withCheckedContinuation

```swift
// Bridge callback-based API to async/await
func fetchUserLegacy(completion: @escaping (User?, Error?) -> Void) {
    // Legacy callback API
}

func fetchUser() async throws -> User {
    try await withCheckedThrowingContinuation { continuation in
        fetchUserLegacy { user, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let user = user {
                continuation.resume(returning: user)
            } else {
                continuation.resume(throwing: NetworkError.invalidResponse)
            }
        }
    }
}
```

### Delegate to Async

```swift
// Convert delegate pattern to async
actor LocationDelegate: NSObject, CLLocationManagerDelegate {
    var continuation: CheckedContinuation<CLLocation, Error>?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

func getCurrentLocation() async throws -> CLLocation {
    let manager = CLLocationManager()
    let delegate = LocationDelegate()
    manager.delegate = delegate

    return try await withCheckedThrowingContinuation { continuation in
        await delegate.setContinuation(continuation)
        manager.requestLocation()
    }
}
```

## Best Practices

### 1. Prefer Structured Concurrency

```swift
// ✅ Good: Structured concurrency
func loadData() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await fetchUsers() }
        group.addTask { try await fetchPosts() }
    }
}

// ❌ Avoid: Unstructured tasks
func loadData() async {
    Task { try? await fetchUsers() }
    Task { try? await fetchPosts() }
    // No way to wait for completion or handle errors
}
```

### 2. Use Actors for Mutable State

```swift
// ✅ Good: Actor for thread-safe state
actor Cache {
    private var items: [String: Any] = [:]
}

// ❌ Avoid: Manual locking
class Cache {
    private var items: [String: Any] = [:]
    private let lock = NSLock()
}
```

### 3. Mark UI Code with @MainActor

```swift
// ✅ Good: Explicit main actor
@MainActor
final class ViewModel: ObservableObject {
    @Published var data: [Item] = []
}

// ❌ Avoid: Manual dispatch to main queue
class ViewModel: ObservableObject {
    @Published var data: [Item] = []

    func update() {
        DispatchQueue.main.async {
            self.data = newData
        }
    }
}
```

## Testing Async Code

### XCTest Async Support

```swift
final class AsyncTests: XCTestCase {
    func testAsyncFunction() async throws {
        // Test async function directly
        let user = try await fetchUser(id: "123")
        XCTAssertEqual(user.id, "123")
    }

    func testTaskCancellation() async {
        let task = Task {
            try await longRunningOperation()
        }

        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Should have been cancelled")
        } catch is CancellationError {
            // Expected
        } catch {
            XCTFail("Wrong error type")
        }
    }
}
```

## References

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [async/await Proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)
- [Actors Proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
- [WWDC 2021: Meet async/await](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [WWDC 2021: Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
