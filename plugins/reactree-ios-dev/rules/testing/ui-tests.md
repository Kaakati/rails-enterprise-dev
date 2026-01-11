---
paths: "**/*UITests.swift"
---

# UI Test Conventions

```swift
final class HomeUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testLoginFlow() {
        // UI test logic
    }
}
```

- Use accessibility identifiers
- Create screen object models
