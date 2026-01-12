---
name: "Performance Optimization"
description: "SwiftUI and iOS performance optimization techniques including profiling with Instruments, memory management, and rendering optimization"
version: "2.0.0"
---

# Performance Optimization for iOS/tvOS

Complete guide to optimizing iOS/tvOS app performance covering SwiftUI rendering, memory management, Instruments profiling, network optimization, and image loading.

## SwiftUI Performance Patterns

### View Identity and Updates

```swift
// ✅ Good: Stable identity with explicit IDs
List(items) { item in
    ItemRow(item: item)
        .id(item.id)  // Stable identity
}

// ❌ Avoid: Unstable identity
List(items.indices, id: \.self) { index in
    ItemRow(item: items[index])
    // Indices change when array is modified
}

// ✅ Good: Equatable to prevent unnecessary updates
struct ItemRow: View, Equatable {
    let item: Item

    var body: some View {
        HStack {
            Text(item.name)
            Text("$\(item.price)")
        }
    }

    static func == (lhs: ItemRow, rhs: ItemRow) -> Bool {
        lhs.item.id == rhs.item.id &&
        lhs.item.name == rhs.item.name &&
        lhs.item.price == rhs.item.price
    }
}
```

### Lazy Loading Containers

```swift
// ✅ Good: Lazy loading for large lists
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// ❌ Avoid: Eager loading
ScrollView {
    VStack(spacing: 16) {
        ForEach(items) { item in
            ItemRow(item: item)
            // All views created immediately
        }
    }
}

// Lazy grids for grid layouts
ScrollView {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
        ForEach(products) { product in
            ProductCard(product: product)
        }
    }
}
```

### View Hierarchy Optimization

```swift
// ✅ Good: Flat hierarchy
struct ProductCard: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            productImage
            productInfo
            priceLabel
        }
    }

    var productImage: some View {
        AsyncImage(url: product.imageURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 80, height: 80)
    }

    var productInfo: some View {
        VStack(alignment: .leading) {
            Text(product.name).font(.headline)
            Text(product.category).font(.caption)
        }
    }

    var priceLabel: some View {
        Text("$\(product.price, specifier: "%.2f")")
            .font(.title3)
    }
}

// ❌ Avoid: Deep nesting
struct ProductCard: View {
    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        VStack {
                            // Deeply nested...
                        }
                    }
                }
            }
        }
    }
}
```

## State Management Performance

### @State vs @StateObject vs @ObservedObject

```swift
// ✅ @State for simple value types
struct CounterView: View {
    @State private var count = 0  // Recreated on view recreation

    var body: some View {
        Button("Count: \(count)") {
            count += 1
        }
    }
}

// ✅ @StateObject for owned ViewModels
struct UserListView: View {
    @StateObject private var viewModel = UserListViewModel()
    // ViewModel persists across view updates

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
    }
}

// ✅ @ObservedObject for passed ViewModels
struct UserDetailView: View {
    @ObservedObject var viewModel: UserDetailViewModel
    // ViewModel owned by parent

    var body: some View {
        Text(viewModel.user.name)
    }
}

// ❌ Avoid: @StateObject for passed objects
struct UserDetailView: View {
    @StateObject var viewModel: UserDetailViewModel
    // Creates new instance on every view recreation!
}
```

### Minimize View Updates

```swift
// ✅ Good: Separate mutable and immutable properties
@MainActor
final class ViewModel: ObservableObject {
    @Published var items: [Item] = []  // Changes trigger updates
    let staticData = "Static"  // Doesn't change
    private var internalCache: [String: Any] = [:]  // Not @Published
}

// ✅ Good: Computed properties instead of @Published
@MainActor
final class ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var allItems: [Item] = []

    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return allItems }
        return allItems.filter { $0.name.contains(searchText) }
    }
    // Automatically updates when dependencies change
}

// ❌ Avoid: Redundant @Published properties
@MainActor
final class ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var allItems: [Item] = []
    @Published var filteredItems: [Item] = []  // Redundant

    func updateFilter() {
        filteredItems = allItems.filter { $0.name.contains(searchText) }
    }
}
```

## Memory Management

### Capturing Self in Closures

```swift
// ✅ Good: Weak self to prevent retain cycles
class ViewModel: ObservableObject {
    var timer: Timer?

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCounter()
        }
    }

    deinit {
        timer?.invalidate()
    }
}

// ✅ Good: Unowned self when guaranteed to exist
class Parent {
    lazy var closure: () -> Void = { [unowned self] in
        self.doSomething()
    }
}

// ❌ Avoid: Strong self capture
class ViewModel {
    var timer: Timer?

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCounter()  // Retain cycle!
        }
    }
}
```

### Image Caching

```swift
// Custom image cache
actor ImageCache {
    private var cache: [URL: UIImage] = [:]
    private let maxCacheSize = 100

    func image(for url: URL) -> UIImage? {
        cache[url]
    }

    func setImage(_ image: UIImage, for url: URL) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries
            let keysToRemove = cache.keys.prefix(20)
            keysToRemove.forEach { cache.removeValue(forKey: $0) }
        }
        cache[url] = image
    }

    func clear() {
        cache.removeAll()
    }
}

// Usage with AsyncImage
struct CachedAsyncImage: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
                    .task {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        let cache = ImageCache.shared

        if let cached = await cache.image(for: url) {
            image = cached
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloaded = UIImage(data: data) {
                await cache.setImage(downloaded, for: url)
                image = downloaded
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}
```

## Instruments Profiling

### Time Profiler

```markdown
## Using Time Profiler

1. Product → Profile (⌘I)
2. Select "Time Profiler"
3. Record app usage
4. Analyze call tree:
   - Sort by "Self" time (time spent in function itself)
   - Look for heavy methods (> 16.67ms for 60 FPS)
   - Expand call tree to find bottlenecks

5. Common issues:
   - Expensive computations on main thread
   - Synchronous I/O operations
   - Inefficient algorithms (O(n²))
   - Excessive view updates
```

```swift
// ✅ Good: Move heavy work off main thread
@MainActor
final class ViewModel: ObservableObject {
    @Published var processedData: [String] = []

    func processData(_ data: [Data]) async {
        let processed = await Task.detached(priority: .userInitiated) {
            data.map { Self.heavyProcessing($0) }
        }.value

        processedData = processed
    }

    static func heavyProcessing(_ data: Data) -> String {
        // CPU-intensive work
        return ""
    }
}
```

### Allocations Instrument

```markdown
## Finding Memory Leaks

1. Product → Profile → Allocations
2. Enable "Record Reference Counts"
3. Use app normally
4. Click "Mark Generation" after each major action
5. Look for:
   - Growing memory usage
   - Objects not deallocating
   - Unexpected retain counts

6. Common leak sources:
   - Retain cycles (strong self in closures)
   - Observers not removed
   - Timers not invalidated
   - Delegates not weak
```

```swift
// ✅ Good: Weak delegate
protocol UserServiceDelegate: AnyObject {
    func didUpdateUser(_ user: User)
}

class UserService {
    weak var delegate: UserServiceDelegate?  // Prevent retain cycle
}

// ✅ Good: Remove observers
class ViewController: UIViewController {
    private var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        observer = NotificationCenter.default.addObserver(
            forName: .userDidLogin,
            object: nil,
            queue: .main
        ) { _ in }
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

## Network Performance

### Request Batching

```swift
// ✅ Good: Batch requests
actor NetworkBatcher {
    private var pendingRequests: [URL: [CheckedContinuation<Data, Error>]] = [:]

    func fetchData(from url: URL) async throws -> Data {
        // Check if request already in progress
        if pendingRequests[url] != nil {
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequests[url]?.append(continuation)
            }
        }

        // Start new request
        pendingRequests[url] = []

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Resolve all waiting continuations
            pendingRequests[url]?.forEach { $0.resume(returning: data) }
            pendingRequests.removeValue(forKey: url)

            return data
        } catch {
            pendingRequests[url]?.forEach { $0.resume(throwing: error) }
            pendingRequests.removeValue(forKey: url)
            throw error
        }
    }
}
```

### Connection Pooling

```swift
// URLSession connection pooling (automatic)
let session = URLSession(configuration: .default)
// Reuses connections for same host

// Custom configuration for better performance
let configuration = URLSessionConfiguration.default
configuration.httpMaximumConnectionsPerHost = 4
configuration.requestCachePolicy = .returnCacheDataElseLoad
configuration.urlCache = URLCache(
    memoryCapacity: 50 * 1024 * 1024,  // 50 MB
    diskCapacity: 100 * 1024 * 1024,    // 100 MB
    diskPath: "ImageCache"
)

let optimizedSession = URLSession(configuration: configuration)
```

## Image Loading Optimization

### Downsampling Images

```swift
// ✅ Good: Downsample before displaying
func downsample(imageAt url: URL, to size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceShouldCache: false,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height) * scale
    ]

    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        return nil
    }

    return UIImage(cgImage: image)
}

// ❌ Avoid: Loading full resolution
let fullResImage = UIImage(contentsOfFile: path)  // Loads entire image into memory
imageView.image = fullResImage
```

### Progressive Image Loading

```swift
struct ProgressiveImage: View {
    let url: URL
    @State private var lowResImage: UIImage?
    @State private var highResImage: UIImage?

    var body: some View {
        ZStack {
            if let highRes = highResImage {
                Image(uiImage: highRes)
                    .resizable()
            } else if let lowRes = lowResImage {
                Image(uiImage: lowRes)
                    .resizable()
                    .blur(radius: 2)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            await loadImages()
        }
    }

    private func loadImages() async {
        // Load low-res thumbnail first
        if let thumbnail = await loadThumbnail(from: url) {
            lowResImage = thumbnail
        }

        // Then load high-res version
        if let fullSize = await loadFullSize(from: url) {
            highResImage = fullSize
        }
    }
}
```

## Core Data Performance

### Batch Operations

```swift
// ✅ Good: Batch delete
let fetchRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "isActive == NO")

let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
try context.execute(batchDelete)

// ✅ Good: Batch update
let batchUpdate = NSBatchUpdateRequest(entityName: "User")
batchUpdate.predicate = NSPredicate(format: "lastLogin < %@", oneYearAgo as NSDate)
batchUpdate.propertiesToUpdate = ["isActive": false]
try context.execute(batchUpdate)

// ❌ Avoid: Deleting individually
let users = try context.fetch(fetchRequest)
users.forEach { context.delete($0) }  // Slow for large datasets
```

### Faulting and Prefetching

```swift
// ✅ Good: Prefetch relationships
let fetchRequest: NSFetchRequest<Order> = Order.fetchRequest()
fetchRequest.relationshipKeyPathsForPrefetching = ["customer", "items"]
let orders = try context.fetch(fetchRequest)

// ✅ Good: Control faulting
fetchRequest.returnsObjectsAsFaults = false  // Load all data immediately

// Background context for heavy operations
let backgroundContext = container.newBackgroundContext()
backgroundContext.performAndWait {
    // Heavy Core Data operations
}
```

## Best Practices

### 1. Measure Before Optimizing

```swift
// Use Instruments to identify actual bottlenecks
// Don't optimize based on assumptions

// Measure with os_signpost
import os.signpost

let log = OSLog(subsystem: "com.app", category: .pointsOfInterest)

os_signpost(.begin, log: log, name: "Data Processing")
// Expensive operation
os_signpost(.end, log: log, name: "Data Processing")
```

### 2. Lazy Initialization

```swift
// ✅ Good: Lazy properties
class ViewModel {
    lazy var expensiveObject: ExpensiveObject = {
        ExpensiveObject()  // Created only when accessed
    }()
}
```

### 3. Avoid Premature Optimization

```markdown
1. Write clean, readable code first
2. Profile to find actual bottlenecks
3. Optimize only what matters
4. Measure impact of optimizations
5. Document why optimizations were made
```

## Testing Performance

### XCTest Performance Tests

```swift
final class PerformanceTests: XCTestCase {
    func testFetchPerformance() {
        measure {
            // Code to measure
            _ = fetchLargeDataset()
        }
    }

    func testRenderingPerformance() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let view = ComplexView()

            startMeasuring()
            _ = view.body  // Trigger view rendering
            stopMeasuring()
        }
    }
}
```

## References

- [SwiftUI Performance](https://developer.apple.com/documentation/swiftui/fruta_building_a_feature-rich_app_with_swiftui)
- [Instruments User Guide](https://help.apple.com/instruments/mac/current/)
- [Core Data Performance](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Performance.html)
- [Image Optimization](https://developer.apple.com/videos/play/wwdc2018/219/)
