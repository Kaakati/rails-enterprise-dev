---
paths: "**/Presentation/**/*ViewModel.swift"
---

# ViewModel Conventions

```swift
@MainActor
final class HomeViewModel: BaseViewModel {
    @Published var items: [Item] = []
    private let service: HomeServiceProtocol

    init(service: HomeServiceProtocol = HomeService()) {
        self.service = service
        super.init()
    }
}
```

- Inherit from BaseViewModel
- Use @MainActor for UI updates
- Inject services via protocol
