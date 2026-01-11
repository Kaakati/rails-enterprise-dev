---
paths: "**/*Tests.swift"
---

# XCTest Unit Test Conventions

```swift
final class UserServiceTests: XCTestCase {
    var sut: UserService!
    var mockNetworkClient: MockNetworkClient!

    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        sut = UserService(networkClient: mockNetworkClient)
    }

    func testFetchUser_Success() async {
        // Given
        // When
        // Then
    }
}
```

- Name tests with pattern: `test[MethodName]_[Scenario]`
- Use Given-When-Then structure
- Mock dependencies via protocols
