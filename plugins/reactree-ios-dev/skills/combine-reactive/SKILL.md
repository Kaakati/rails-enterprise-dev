---
name: "Combine Reactive"
description: "Combine framework for reactive programming in iOS/tvOS with publishers, operators, and integration with async/await"
version: "2.0.0"
---

# Combine Framework for iOS/tvOS

Complete guide to reactive programming with Combine framework, including publishers, subscribers, operators, and migration strategies to async/await.

## Core Concepts

### Publishers and Subscribers

```swift
import Combine

// Publisher emits values
let publisher = Just("Hello")

// Subscriber receives values
let subscriber = publisher.sink { value in
    print("Received: \(value)")
}

// Publisher types
let justPublisher = Just(42)  // Emits single value
let futurePublisher = Future<String, Never> { promise in
    promise(.success("Value"))
}
let passthrough = PassthroughSubject<String, Never>()  // Manual emission
let currentValue = CurrentValueSubject<Int, Never>(0)  // Stores current value
```

### Subscriptions and Cancellation

```swift
class ViewModel {
    private var cancellables = Set<AnyCancellable>()

    func loadData() {
        fetchUser()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("Completed")
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                },
                receiveValue: { user in
                    print("User: \(user)")
                }
            )
            .store(in: &cancellables)
    }

    // Automatic cancellation on deinit
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
```

## @Published Property Wrapper

### Observable Properties

```swift
@MainActor
final class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func loadUsers() {
        isLoading = true

        userService.fetchUsers()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    self?.users = users
                }
            )
            .store(in: &cancellables)
    }
}

// SwiftUI automatically observes @Published properties
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
        .onAppear {
            viewModel.loadUsers()
        }
    }
}
```

## Common Operators

### Transforming Operators

```swift
// map: Transform values
let numbers = [1, 2, 3, 4, 5]
numbers.publisher
    .map { $0 * 2 }
    .sink { print($0) }  // 2, 4, 6, 8, 10

// flatMap: Transform and flatten
struct User {
    let id: String
}

func fetchUser(id: String) -> AnyPublisher<User, Error> {
    // Network request
}

userIds.publisher
    .flatMap { userId in
        fetchUser(id: userId)
    }
    .collect()
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { users in
            print("All users: \(users)")
        }
    )

// compactMap: Map and remove nils
["1", "2", "three", "4"].publisher
    .compactMap { Int($0) }
    .sink { print($0) }  // 1, 2, 4

// scan: Accumulate values
[1, 2, 3, 4].publisher
    .scan(0, +)
    .sink { print($0) }  // 1, 3, 6, 10
```

### Filtering Operators

```swift
// filter: Keep values that match predicate
[1, 2, 3, 4, 5, 6].publisher
    .filter { $0 % 2 == 0 }
    .sink { print($0) }  // 2, 4, 6

// removeDuplicates: Remove consecutive duplicates
[1, 1, 2, 2, 3, 3].publisher
    .removeDuplicates()
    .sink { print($0) }  // 1, 2, 3

// first: Emit only first value
[1, 2, 3].publisher
    .first()
    .sink { print($0) }  // 1

// dropFirst: Skip first n values
[1, 2, 3, 4].publisher
    .dropFirst(2)
    .sink { print($0) }  // 3, 4
```

### Combining Operators

```swift
// combineLatest: Combine latest values from multiple publishers
let namePublisher = PassthroughSubject<String, Never>()
let agePublisher = PassthroughSubject<Int, Never>()

Publishers.CombineLatest(namePublisher, agePublisher)
    .sink { name, age in
        print("\(name) is \(age) years old")
    }

namePublisher.send("John")
agePublisher.send(30)  // Prints: "John is 30 years old"

// merge: Merge multiple publishers
let publisher1 = [1, 2, 3].publisher
let publisher2 = [4, 5, 6].publisher

publisher1.merge(with: publisher2)
    .sink { print($0) }  // 1, 2, 3, 4, 5, 6 (order may vary)

// zip: Pair values from publishers
let numbers = [1, 2, 3].publisher
let letters = ["A", "B", "C"].publisher

numbers.zip(letters)
    .sink { number, letter in
        print("\(number)-\(letter)")  // 1-A, 2-B, 3-C
    }
```

### Timing Operators

```swift
// debounce: Wait for pause in emissions
searchTextField.textPublisher
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { searchText in
        performSearch(searchText)
    }

// throttle: Limit emission rate
scrollView.contentOffsetPublisher
    .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
    .sink { offset in
        updateUI(for: offset)
    }

// delay: Delay emissions
publisher
    .delay(for: .seconds(2), scheduler: DispatchQueue.main)
    .sink { value in
        print("Delayed: \(value)")
    }
```

## Error Handling

### Catch and Retry

```swift
// catch: Replace error with fallback publisher
fetchUser(id: "123")
    .catch { error -> AnyPublisher<User, Never> in
        print("Error: \(error)")
        return Just(User.placeholder).eraseToAnyPublisher()
    }
    .sink { user in
        print("User: \(user)")
    }

// retry: Retry on failure
fetchUser(id: "123")
    .retry(3)
    .catch { _ in Just(User.placeholder) }
    .sink { user in
        print("User: \(user)")
    }

// replaceError: Replace error with value
fetchUser(id: "123")
    .replaceError(with: User.placeholder)
    .sink { user in
        print("User: \(user)")
    }
```

## Subjects

### PassthroughSubject

```swift
// Manual value emission
final class EventBus {
    let userLoggedIn = PassthroughSubject<User, Never>()
    let userLoggedOut = PassthroughSubject<Void, Never>()

    func notifyLogin(user: User) {
        userLoggedIn.send(user)
    }

    func notifyLogout() {
        userLoggedOut.send()
    }
}

// Usage
let eventBus = EventBus()

eventBus.userLoggedIn
    .sink { user in
        print("User logged in: \(user.name)")
    }
    .store(in: &cancellables)

eventBus.notifyLogin(user: User(name: "John"))
```

### CurrentValueSubject

```swift
// Stores and emits current value
final class SettingsManager {
    let theme = CurrentValueSubject<Theme, Never>(.light)
    let fontSize = CurrentValueSubject<Int, Never>(14)

    func updateTheme(_ theme: Theme) {
        self.theme.send(theme)
    }

    var currentTheme: Theme {
        theme.value  // Access current value
    }
}

// Usage
let settings = SettingsManager()

settings.theme
    .sink { theme in
        applyTheme(theme)
    }
    .store(in: &cancellables)

print("Current theme: \(settings.currentTheme)")
settings.updateTheme(.dark)
```

## Combine with SwiftUI

### TextField Binding

```swift
struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [String] = []

    private let searchPublisher = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .onChange(of: searchText) { oldValue, newValue in
                    searchPublisher.send(newValue)
                }

            List(results, id: \.self) { result in
                Text(result)
            }
        }
        .onAppear {
            setupSearch()
        }
    }

    private func setupSearch() {
        searchPublisher
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .flatMap { query -> AnyPublisher<[String], Never> in
                performSearch(query: query)
            }
            .sink { results in
                self.results = results
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) -> AnyPublisher<[String], Never> {
        // Simulate search
        Just(["Result 1", "Result 2"]).eraseToAnyPublisher()
    }
}
```

### Timer Publisher

```swift
struct CountdownView: View {
    @State private var timeRemaining = 60
    private var cancellables = Set<AnyCancellable>()

    var body: some View {
        Text("\(timeRemaining) seconds")
            .onAppear {
                startTimer()
            }
    }

    private func startTimer() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
            }
            .store(in: &cancellables)
    }
}
```

## Migrating to Async/Await

### Future to Async

```swift
// Combine Future
func fetchUser(id: String) -> Future<User, Error> {
    Future { promise in
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle response
            if let error = error {
                promise(.failure(error))
            } else if let data = data {
                let user = try! JSONDecoder().decode(User.self, from: data)
                promise(.success(user))
            }
        }.resume()
    }
}

// Async/await equivalent
func fetchUser(id: String) async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// Bridge Combine to async
extension Publisher {
    func async() async throws -> Output where Failure == Error {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

// Usage
Task {
    let user = try await fetchUserPublisher().async()
}
```

### AsyncSequence from Publisher

```swift
extension Publisher {
    var values: AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: { value in
                    continuation.yield(value)
                }
            )

            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
}

// Usage
for try await user in userPublisher.values {
    print(user)
}
```

## Best Practices

### 1. Store Subscriptions

```swift
// ✅ Good: Store in Set<AnyCancellable>
class ViewModel {
    private var cancellables = Set<AnyCancellable>()

    func load() {
        publisher.sink { }.store(in: &cancellables)
    }
}

// ❌ Avoid: Not storing (subscription cancelled immediately)
func load() {
    publisher.sink { }  // Cancelled right away!
}
```

### 2. Use Weak Self in Closures

```swift
// ✅ Good: Weak self to prevent retain cycles
publisher
    .sink { [weak self] value in
        self?.updateUI(value)
    }
    .store(in: &cancellables)

// ❌ Avoid: Strong self capture
publisher
    .sink { value in
        self.updateUI(value)  // Retain cycle!
    }
```

### 3. Cancel on Deinit

```swift
// ✅ Good: Automatic cancellation
class ViewModel {
    private var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
```

### 4. Type Erasure

```swift
// ✅ Good: Use AnyPublisher for API boundaries
func fetchData() -> AnyPublisher<Data, Error> {
    URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .eraseToAnyPublisher()
}

// ❌ Avoid: Exposing complex publisher types
func fetchData() -> Publishers.Map<URLSession.DataTaskPublisher, Data> {
    // Complex type signature
}
```

## References

- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Using Combine](https://heckj.github.io/swiftui-notes/)
- [Combine Operators](https://developer.apple.com/documentation/combine/publishers)
- [Async/Await Migration](https://www.swiftbysundell.com/articles/calling-async-functions-within-a-combine-pipeline/)
