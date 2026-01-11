---
name: "MVVM Architecture"
description: "Model-View-ViewModel pattern implementation for iOS/tvOS with SwiftUI"
version: "1.0.0"
---

# MVVM Architecture

## BaseViewModel Pattern

```swift
@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false

    func executeTask(_ task: @escaping () async throws -> Void) async {
        isLoading = true
        do {
            try await task()
        } catch {
            self.error = error
            showError = true
        }
        isLoading = false
    }
}
```

## ViewModel Implementation

```swift
@MainActor
final class HomeViewModel: BaseViewModel {
    @Published var items: [Item] = []
    private let service: HomeServiceProtocol

    init(service: HomeServiceProtocol = HomeService()) {
        self.service = service
        super.init()
    }

    func loadData() async {
        await executeTask {
            let result = await service.fetchItems()
            if case .success(let items) = result {
                self.items = items
            }
        }
    }
}
```

## View-ViewModel Binding

```swift
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.loadData() }
        .alert("Error", isPresented: $viewModel.showError) { }
    }
}
```
