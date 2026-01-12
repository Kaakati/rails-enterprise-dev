---
title: "Offline Sync Feature Example"
description: "Complete offline-first data synchronization with Core Data, sync queue, conflict resolution, and background sync"
platform: "iOS/tvOS"
difficulty: "Advanced"
estimated_time: "4-6 hours"
---

# Offline Sync Feature Example

This example demonstrates building a complete offline-first data synchronization system for iOS/tvOS applications, including:

- **Offline Persistence** - Core Data for local storage
- **Sync Queue** - Background sync queue with retry logic
- **Conflict Resolution** - Last-write-wins and custom strategies
- **Network Reachability** - Monitor connectivity and trigger sync
- **Background Sync** - Sync when app enters background

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Data Model](#core-data-model)
3. [Sync Queue Implementation](#sync-queue-implementation)
4. [Conflict Resolution](#conflict-resolution)
5. [Network Reachability](#network-reachability)
6. [Background Sync](#background-sync)
7. [Testing Strategy](#testing-strategy)
8. [Complete Example](#complete-example)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                 │
│  ┌───────────────────────────────────────────┐  │
│  │  TaskListView + TaskListViewModel         │  │
│  └──────────────────┬────────────────────────┘  │
└────────────────────┼────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────┐
│              Core Layer (Services)              │
│  ┌──────────────────┴──────────────────────┐   │
│  │        TaskSyncService                  │   │
│  │  - Sync queue management                │   │
│  │  - Conflict resolution                  │   │
│  │  - Background sync coordination         │   │
│  └──────────┬──────────────┬───────────────┘   │
│             │              │                    │
│  ┌──────────┴───────┐   ┌──┴────────────────┐  │
│  │ TaskRepository   │   │ NetworkService    │  │
│  │ (Core Data)      │   │ (API Client)      │  │
│  └──────────────────┘   └───────────────────┘  │
└─────────────────────────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────┐
│         Infrastructure Layer                    │
│  ┌──────────────────┴──────────────────────┐   │
│  │     PersistenceController               │   │
│  │  - Core Data stack                      │   │
│  │  - Background context                   │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## Core Data Model

### Task.xcdatamodeld

```swift
// Core/Data/Models/TaskEntity+CoreDataClass.swift
import Foundation
import CoreData

@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var taskDescription: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var serverVersion: Int64  // For conflict resolution
}

extension TaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    /// Fetch tasks that need syncing
    static func pendingSyncFetchRequest() -> NSFetchRequest<TaskEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: true)]
        return request
    }
}

// Core/Data/Models/Task.swift (Domain Model)
import Foundation

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var isCompleted: Bool
    let createdAt: Date
    var updatedAt: Date
    var serverVersion: Int64

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverVersion: Int64 = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverVersion = serverVersion
    }
}

// Mapping between domain model and entity
extension TaskEntity {
    func toDomain() -> Task {
        Task(
            id: id,
            title: title,
            description: taskDescription,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            serverVersion: serverVersion
        )
    }

    func update(from task: Task) {
        title = task.title
        taskDescription = task.description
        isCompleted = task.isCompleted
        updatedAt = task.updatedAt
        serverVersion = task.serverVersion
        needsSync = true
    }

    static func create(from task: Task, in context: NSManagedObjectContext) -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.id = task.id
        entity.title = task.title
        entity.taskDescription = task.description
        entity.isCompleted = task.isCompleted
        entity.createdAt = task.createdAt
        entity.updatedAt = task.updatedAt
        entity.serverVersion = task.serverVersion
        entity.needsSync = true
        return entity
    }
}
```

---

## Sync Queue Implementation

### TaskSyncService

```swift
// Core/Services/TaskSyncService.swift
import Foundation
import CoreData
import Combine

@MainActor
final class TaskSyncService: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: Error?

    private let repository: TaskRepository
    private let networkService: NetworkServiceProtocol
    private let reachability: NetworkReachability

    private var syncTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: TaskRepository,
        networkService: NetworkServiceProtocol = NetworkService.shared,
        reachability: NetworkReachability = NetworkReachability.shared
    ) {
        self.repository = repository
        self.networkService = networkService
        self.reachability = reachability

        setupReachabilityObserver()
    }

    // MARK: - Public Methods

    /// Manually trigger sync
    func sync() async {
        guard !isSyncing else { return }
        guard reachability.isReachable else {
            syncError = SyncError.noConnection
            return
        }

        await performSync()
    }

    /// Start automatic sync monitoring
    func startAutoSync() {
        // Sync when network becomes available
        setupReachabilityObserver()
    }

    /// Stop automatic sync monitoring
    func stopAutoSync() {
        cancellables.removeAll()
    }

    // MARK: - Private Methods

    private func setupReachabilityObserver() {
        reachability.$isReachable
            .filter { $0 }  // Only when reachable
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.syncIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    private func syncIfNeeded() async {
        guard !isSyncing else { return }
        guard await repository.hasPendingSync() else { return }

        await performSync()
    }

    private func performSync() async {
        isSyncing = true
        syncError = nil

        do {
            // 1. Push local changes to server
            try await pushLocalChanges()

            // 2. Pull remote changes from server
            try await pullRemoteChanges()

            // 3. Update last sync date
            lastSyncDate = Date()

            print("✅ Sync completed successfully")
        } catch {
            syncError = error
            print("❌ Sync failed: \(error)")
        }

        isSyncing = false
    }

    private func pushLocalChanges() async throws {
        let pendingTasks = await repository.fetchPendingSync()

        guard !pendingTasks.isEmpty else { return }

        print("⬆️  Pushing \(pendingTasks.count) tasks to server...")

        for task in pendingTasks {
            do {
                // Push to server
                let serverTask: Task = try await networkService.request(
                    endpoint: "/tasks/\(task.id)",
                    method: .put,
                    body: task
                )

                // Update local record with server version
                await repository.updateServerVersion(
                    taskId: task.id,
                    serverVersion: serverTask.serverVersion,
                    syncedAt: Date()
                )

                print("  ✓ Pushed task: \(task.title)")
            } catch {
                print("  ✗ Failed to push task: \(task.title) - \(error)")
                // Continue with other tasks
            }
        }
    }

    private func pullRemoteChanges() async throws {
        print("⬇️  Pulling changes from server...")

        // Get last sync date to only fetch updated tasks
        let since = lastSyncDate ?? Date.distantPast

        let remoteTasks: [Task] = try await networkService.request(
            endpoint: "/tasks",
            method: .get,
            queryParams: ["since": since.ISO8601Format()]
        )

        guard !remoteTasks.isEmpty else { return }

        print("  Received \(remoteTasks.count) tasks from server")

        for remoteTask in remoteTasks {
            // Check if task exists locally
            if let localTask = await repository.fetchTask(id: remoteTask.id) {
                // Conflict resolution
                try await resolveConflict(local: localTask, remote: remoteTask)
            } else {
                // New task from server
                await repository.save(remoteTask, needsSync: false)
                print("  ✓ Added new task: \(remoteTask.title)")
            }
        }
    }
}

// MARK: - Sync Error

enum SyncError: LocalizedError {
    case noConnection
    case conflictResolutionFailed
    case pushFailed(Task)
    case pullFailed

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .conflictResolutionFailed:
            return "Failed to resolve sync conflict"
        case .pushFailed(let task):
            return "Failed to push task: \(task.title)"
        case .pullFailed:
            return "Failed to pull remote changes"
        }
    }
}
```

---

## Conflict Resolution

### Conflict Resolution Strategy

```swift
// Core/Services/TaskSyncService+ConflictResolution.swift
extension TaskSyncService {
    /// Resolve conflicts between local and remote versions
    private func resolveConflict(local: Task, remote: Task) async throws {
        print("⚠️  Conflict detected for task: \(local.title)")

        // Strategy 1: Last Write Wins (based on updatedAt timestamp)
        let resolvedTask = resolveByLastWriteWins(local: local, remote: remote)

        // Strategy 2: Server Version Wins (alternative)
        // let resolvedTask = remote

        // Strategy 3: Custom Business Logic
        // let resolvedTask = resolveByCustomLogic(local: local, remote: remote)

        // Update local database with resolved version
        await repository.save(resolvedTask, needsSync: false)

        print("  ✓ Conflict resolved using Last Write Wins")
    }

    /// Last Write Wins: Choose task with most recent updatedAt
    private func resolveByLastWriteWins(local: Task, remote: Task) -> Task {
        if remote.updatedAt > local.updatedAt {
            print("    → Server version is newer")
            return remote
        } else {
            print("    → Local version is newer")
            return local
        }
    }

    /// Custom Business Logic: Merge changes intelligently
    private func resolveByCustomLogic(local: Task, remote: Task) -> Task {
        var resolved = remote  // Start with server version

        // Example: If local has completion status changed more recently, use that
        if local.updatedAt > remote.updatedAt {
            resolved.isCompleted = local.isCompleted
        }

        // Example: Merge descriptions if both changed
        if local.description != remote.description {
            resolved.description = "\(local.description ?? "") | \(remote.description ?? "")"
        }

        return resolved
    }
}
```

---

## Network Reachability

### NetworkReachability Service

```swift
// Core/Services/NetworkReachability.swift
import Foundation
import Network
import Combine

@MainActor
final class NetworkReachability: ObservableObject {
    static let shared = NetworkReachability()

    @Published private(set) var isReachable = false
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.app.network-monitor")

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }

    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isReachable = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown

                if path.status == .satisfied {
                    print("📶 Network connection available (\(self?.connectionType ?? .unknown))")
                } else {
                    print("📵 Network connection lost")
                }
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else {
            return .unknown
        }
    }
}
```

---

## Background Sync

### Background Sync Trigger

```swift
// Core/Services/TaskSyncService+Background.swift
import BackgroundTasks

extension TaskSyncService {
    /// Register background task for periodic sync
    static func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.app.task-sync",
            using: nil
        ) { task in
            Task {
                await Self.handleBackgroundSync(task: task as! BGAppRefreshTask)
            }
        }
    }

    /// Schedule next background sync
    func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.app.task-sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background sync scheduled")
        } catch {
            print("❌ Failed to schedule background sync: \(error)")
        }
    }

    /// Handle background sync task
    private static func handleBackgroundSync(task: BGAppRefreshTask) async {
        print("🔄 Background sync started")

        let syncService = TaskSyncService(
            repository: TaskRepository.shared,
            networkService: NetworkService.shared,
            reachability: NetworkReachability.shared
        )

        // Set up task expiration handler
        task.expirationHandler = {
            print("⚠️  Background sync time expired")
        }

        // Perform sync
        await syncService.sync()

        // Mark task as complete
        task.setTaskCompleted(success: syncService.syncError == nil)

        // Schedule next sync
        await syncService.scheduleBackgroundSync()
    }
}

// AppDelegate or App struct
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    // Register background tasks
    TaskSyncService.registerBackgroundTasks()
    return true
}
```

---

## Testing Strategy

### Sync Service Tests

```swift
// Tests/TaskSyncServiceTests.swift
import XCTest
@testable import MyApp

final class TaskSyncServiceTests: XCTestCase {
    var repository: MockTaskRepository!
    var networkService: MockNetworkService!
    var reachability: MockNetworkReachability!
    var syncService: TaskSyncService!

    @MainActor
    override func setUp() async throws {
        repository = MockTaskRepository()
        networkService = MockNetworkService()
        reachability = MockNetworkReachability()

        syncService = TaskSyncService(
            repository: repository,
            networkService: networkService,
            reachability: reachability
        )
    }

    @MainActor
    func testSyncPushesLocalChanges() async throws {
        // Given: Local tasks pending sync
        let task = Task(id: UUID(), title: "Test Task")
        repository.pendingSyncTasks = [task]
        reachability.isReachable = true

        // When: Sync is triggered
        await syncService.sync()

        // Then: Tasks are pushed to server
        XCTAssertTrue(networkService.pushedTasks.contains(where: { $0.id == task.id }))
        XCTAssertFalse(syncService.isSyncing)
        XCTAssertNil(syncService.syncError)
    }

    @MainActor
    func testSyncPullsRemoteChanges() async throws {
        // Given: Remote tasks available
        let remoteTask = Task(id: UUID(), title: "Remote Task")
        networkService.remoteTasks = [remoteTask]
        reachability.isReachable = true

        // When: Sync is triggered
        await syncService.sync()

        // Then: Remote tasks are saved locally
        XCTAssertTrue(repository.savedTasks.contains(where: { $0.id == remoteTask.id }))
    }

    @MainActor
    func testConflictResolutionLastWriteWins() async throws {
        // Given: Local and remote versions of same task
        let taskId = UUID()
        let localTask = Task(id: taskId, title: "Local", updatedAt: Date())
        let remoteTask = Task(id: taskId, title: "Remote", updatedAt: Date().addingTimeInterval(60))

        repository.fetchedTask = localTask
        networkService.remoteTasks = [remoteTask]
        reachability.isReachable = true

        // When: Sync resolves conflict
        await syncService.sync()

        // Then: Remote version wins (more recent)
        let savedTask = repository.savedTasks.first { $0.id == taskId }
        XCTAssertEqual(savedTask?.title, "Remote")
    }

    @MainActor
    func testSyncFailsWhenOffline() async {
        // Given: No network connection
        reachability.isReachable = false

        // When: Sync is attempted
        await syncService.sync()

        // Then: Sync error is set
        XCTAssertNotNil(syncService.syncError)
        XCTAssertFalse(syncService.isSyncing)
    }
}
```

---

## Complete Example

### TaskListView with Offline Sync

```swift
// Presentation/TaskList/TaskListView.swift
import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Task list
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskRow(task: task) {
                            viewModel.toggleTaskCompletion(task)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteTasks(at: indexSet)
                    }
                }
                .refreshable {
                    await viewModel.sync()
                }

                // Sync status overlay
                if viewModel.isSyncing {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Syncing...")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        viewModel.addTask()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isOnline ? "wifi" : "wifi.slash")
                        if let lastSync = viewModel.lastSyncDate {
                            Text("Synced \(lastSync, style: .relative)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .alert("Sync Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                if let error = viewModel.syncError {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)

                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
```

---

## Summary

This example demonstrates:

✅ **Offline-First Architecture** - Local persistence with Core Data
✅ **Background Sync Queue** - Automatic sync when network available
✅ **Conflict Resolution** - Last-write-wins strategy with extensible design
✅ **Network Monitoring** - Reactive sync on connectivity changes
✅ **Background Sync** - BGTaskScheduler for periodic sync
✅ **Comprehensive Testing** - Mock-based unit tests for sync logic
✅ **User Experience** - Visual sync status and error handling

**Key Takeaways:**
- Always persist locally first, sync asynchronously
- Use server version numbers for conflict detection
- Monitor network reachability for automatic sync
- Implement retry logic for failed sync operations
- Provide clear sync status to users
- Test sync logic thoroughly with mocks
