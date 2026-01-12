---
name: "Core Data Patterns"
description: "Core Data persistence patterns for iOS/tvOS including NSPersistentContainer, fetch requests, relationships, and SwiftUI integration"
version: "2.0.0"
---

# Core Data Patterns for iOS/tvOS

Complete guide to Core Data persistence in iOS/tvOS applications including setup, CRUD operations, relationships, migration, and SwiftUI integration.

## Core Data Stack Setup

### NSPersistentContainer

```swift
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AppModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // Preview helper
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create sample data
        for i in 0..<10 {
            let user = User(context: context)
            user.id = UUID()
            user.name = "User \(i)"
            user.email = "user\(i)@example.com"
        }

        try? context.save()
        return controller
    }()
}
```

### SwiftUI Integration

```swift
@main
struct MyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

## Data Model

### Entity Definition

```swift
// User+CoreDataClass.swift
import CoreData

@objc(User)
public class User: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var email: String
    @NSManaged public var age: Int16
    @NSManaged public var createdAt: Date
    @NSManaged public var posts: NSSet?
}

// Relationships
extension User {
    @objc(addPostsObject:)
    @NSManaged public func addToPosts(_ value: Post)

    @objc(removePostsObject:)
    @NSManaged public func removeFromPosts(_ value: Post)

    @objc(addPosts:)
    @NSManaged public func addToPosts(_ values: NSSet)

    @objc(removePosts:)
    @NSManaged public func removeFromPosts(_ values: NSSet)
}

// Convenience extensions
extension User {
    static func fetchRequest() -> NSFetchRequest<User> {
        NSFetchRequest<User>(entityName: "User")
    }

    var postsArray: [Post] {
        let set = posts as? Set<Post> ?? []
        return set.sorted { $0.createdAt < $1.createdAt }
    }
}
```

## CRUD Operations

### Create

```swift
func createUser(name: String, email: String, in context: NSManagedObjectContext) throws -> User {
    let user = User(context: context)
    user.id = UUID()
    user.name = name
    user.email = email
    user.age = 0
    user.createdAt = Date()

    try context.save()
    return user
}

// SwiftUI
struct CreateUserView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name = ""
    @State private var email = ""

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Email", text: $email)

            Button("Save") {
                saveUser()
            }
        }
    }

    private func saveUser() {
        withAnimation {
            let user = User(context: viewContext)
            user.id = UUID()
            user.name = name
            user.email = email
            user.createdAt = Date()

            do {
                try viewContext.save()
            } catch {
                print("Error saving: \(error)")
            }
        }
    }
}
```

### Read (Fetch Requests)

```swift
// Basic fetch
func fetchAllUsers(in context: NSManagedObjectContext) throws -> [User] {
    let request = User.fetchRequest()
    return try context.fetch(request)
}

// Fetch with predicate
func fetchUsers(named name: String, in context: NSManagedObjectContext) throws -> [User] {
    let request = User.fetchRequest()
    request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
    return try context.fetch(request)
}

// Fetch with sort
func fetchUsersSorted(in context: NSManagedObjectContext) throws -> [User] {
    let request = User.fetchRequest()
    request.sortDescriptors = [
        NSSortDescriptor(keyPath: \User.name, ascending: true)
    ]
    return try context.fetch(request)
}

// Fetch with limit
func fetchRecentUsers(limit: Int, in context: NSManagedObjectContext) throws -> [User] {
    let request = User.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(keyPath: \User.createdAt, ascending: false)]
    request.fetchLimit = limit
    return try context.fetch(request)
}

// Complex predicate
func fetchActiveUsers(minAge: Int16, in context: NSManagedObjectContext) throws -> [User] {
    let request = User.fetchRequest()
    request.predicate = NSPredicate(
        format: "age >= %d AND email != nil",
        minAge
    )
    return try context.fetch(request)
}
```

### Update

```swift
func updateUser(_ user: User, name: String? = nil, email: String? = nil, in context: NSManagedObjectContext) throws {
    if let name = name {
        user.name = name
    }

    if let email = email {
        user.email = email
    }

    try context.save()
}

// Batch update
func deactivateOldUsers(in context: NSManagedObjectContext) throws {
    let request = NSBatchUpdateRequest(entityName: "User")
    request.predicate = NSPredicate(
        format: "createdAt < %@",
        Calendar.current.date(byAdding: .year, value: -1, to: Date())! as NSDate
    )
    request.propertiesToUpdate = ["isActive": false]

    try context.execute(request)
}
```

### Delete

```swift
func deleteUser(_ user: User, in context: NSManagedObjectContext) throws {
    context.delete(user)
    try context.save()
}

// Batch delete
func deleteInactiveUsers(in context: NSManagedObjectContext) throws {
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "isActive == NO")

    let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    try context.execute(batchDelete)
}
```

## SwiftUI @FetchRequest

### Basic Fetch

```swift
struct UserListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        animation: .default
    )
    private var users: FetchedResults<User>

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
    }
}
```

### Dynamic Fetch Request

```swift
struct FilteredUserListView: View {
    @State private var searchText = ""

    var body: some View {
        UserListView(searchText: searchText)
    }
}

struct UserListView: View {
    @FetchRequest private var users: FetchedResults<User>

    init(searchText: String) {
        let predicate: NSPredicate? = searchText.isEmpty ? nil : NSPredicate(
            format: "name CONTAINS[cd] %@",
            searchText
        )

        _users = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        List(users) { user in
            VStack(alignment: .leading) {
                Text(user.name)
                Text(user.email).font(.caption)
            }
        }
    }
}
```

## Relationships

### One-to-Many

```swift
// User (one) → Posts (many)

// Create relationship
func addPost(to user: User, title: String, in context: NSManagedObjectContext) throws {
    let post = Post(context: context)
    post.id = UUID()
    post.title = title
    post.content = ""
    post.createdAt = Date()
    post.author = user

    try context.save()
}

// Fetch with relationship
func fetchUsersWithPosts(in context: NSManagedObjectContext) throws -> [User] {
    let request = User.fetchRequest()
    request.predicate = NSPredicate(format: "posts.@count > 0")
    request.relationshipKeyPathsForPrefetching = ["posts"]
    return try context.fetch(request)
}
```

### Many-to-Many

```swift
// User (many) ← → Groups (many)

// Create relationship
func addUserToGroup(_ user: User, group: Group, in context: NSManagedObjectContext) throws {
    user.addToGroups(group)
    try context.save()
}

// Remove relationship
func removeUserFromGroup(_ user: User, group: Group, in context: NSManagedObjectContext) throws {
    user.removeFromGroups(group)
    try context.save()
}
```

## Background Context

### Performing Background Operations

```swift
func importData(_ data: [UserData]) {
    let context = PersistenceController.shared.container.newBackgroundContext()

    context.perform {
        for userData in data {
            let user = User(context: context)
            user.id = UUID()
            user.name = userData.name
            user.email = userData.email
        }

        do {
            try context.save()
        } catch {
            print("Error saving: \(error)")
        }
    }
}

// Async background operation
func importDataAsync(_ data: [UserData]) async throws {
    let context = PersistenceController.shared.container.newBackgroundContext()

    try await context.perform {
        for userData in data {
            let user = User(context: context)
            user.id = UUID()
            user.name = userData.name
            user.email = userData.email
        }

        try context.save()
    }
}
```

## Migration

### Lightweight Migration

```swift
let container = NSPersistentContainer(name: "AppModel")

let description = container.persistentStoreDescriptions.first
description?.shouldInferMappingModelAutomatically = true
description?.shouldMigrateStoreAutomatically = true

container.loadPersistentStores { description, error in
    if let error = error {
        fatalError("Migration failed: \(error)")
    }
}
```

### Custom Migration

```swift
// Create new model version in Xcode
// Add mapping model if needed

class MigrationManager {
    static func migrateStoreIfNeeded(at storeURL: URL) throws {
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL
        )

        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])!

        if !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            try performMigration(at: storeURL, to: model)
        }
    }

    private static func performMigration(at storeURL: URL, to model: NSManagedObjectModel) throws {
        let migrationManager = NSMigrationManager(
            sourceModel: /* source model */,
            destinationModel: model
        )

        let mappingModel = NSMappingModel(
            from: [Bundle.main],
            forSourceModel: /* source */,
            destinationModel: model
        )!

        try migrationManager.migrateStore(
            from: storeURL,
            sourceType: NSSQLiteStoreType,
            options: nil,
            with: mappingModel,
            toDestinationURL: /* temp URL */,
            destinationType: NSSQLiteStoreType,
            destinationOptions: nil
        )
    }
}
```

## Performance Optimization

### Faulting

```swift
// Faulting: Objects are placeholders until accessed
let request = User.fetchRequest()
request.returnsObjectsAsFaults = true  // Default
let users = try context.fetch(request)

// user.name triggers fault and loads data

// Prefetch to avoid faulting
request.returnsObjectsAsFaults = false
```

### Batch Faulting

```swift
// Fetch with batch size
let request = User.fetchRequest()
request.fetchBatchSize = 20  // Load 20 objects at a time

let users = try context.fetch(request)

for user in users {
    // Automatically loads in batches of 20
    print(user.name)
}
```

### Prefetching Relationships

```swift
let request = User.fetchRequest()
request.relationshipKeyPathsForPrefetching = ["posts", "groups"]

let users = try context.fetch(request)
// Posts and groups are eagerly loaded
```

## Best Practices

### 1. Use Background Contexts

```swift
// ✅ Good: Heavy operations on background
let backgroundContext = container.newBackgroundContext()
backgroundContext.perform {
    // Heavy import/processing
    try? backgroundContext.save()
}

// ❌ Avoid: Blocking main thread
let users = try viewContext.fetch(/* large fetch */)  // Blocks UI!
```

### 2. Batch Operations

```swift
// ✅ Good: Batch delete
let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
try context.execute(batchDelete)

// ❌ Avoid: Individual deletes
users.forEach { context.delete($0) }  // Slow for large datasets
try context.save()
```

### 3. Limit Fetch Results

```swift
// ✅ Good: Fetch only what you need
request.fetchLimit = 50
request.propertiesToFetch = ["name", "email"]

// ❌ Avoid: Fetching everything
let allUsers = try context.fetch(User.fetchRequest())  // Could be thousands!
```

### 4. Error Handling

```swift
// ✅ Good: Handle save errors
do {
    try context.save()
} catch let error as NSError {
    print("Save error: \(error), \(error.userInfo)")
    context.rollback()
}

// ❌ Avoid: Ignoring errors
try? context.save()  // Silently fails
```

## Testing Core Data

### In-Memory Store

```swift
final class CoreDataTests: XCTestCase {
    var persistenceController: PersistenceController!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }

    func testCreateUser() throws {
        let context = persistenceController.container.viewContext

        let user = User(context: context)
        user.id = UUID()
        user.name = "Test User"
        user.email = "test@example.com"

        try context.save()

        let request = User.fetchRequest()
        let users = try context.fetch(request)

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, "Test User")
    }
}
```

## References

- [Core Data Programming Guide](https://developer.apple.com/documentation/coredata)
- [NSPersistentContainer](https://developer.apple.com/documentation/coredata/nspersistentcontainer)
- [Core Data Performance](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Performance.html)
- [SwiftUI Core Data Integration](https://developer.apple.com/documentation/coredata/loading_and_displaying_a_large_data_feed)
