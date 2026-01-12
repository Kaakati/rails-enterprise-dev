---
name: "XCTest Patterns"
description: "Comprehensive testing patterns with XCTest for iOS/tvOS applications"
version: "2.0.0"
---

# XCTest Patterns for iOS/tvOS

Complete guide to testing iOS/tvOS applications using XCTest framework, including unit tests, integration tests, UI tests, performance tests, and code coverage strategies.

## Core Testing Concepts

### XCTest Framework

**Key Components:**
- `XCTestCase` - Base class for test cases
- `XCTestExpectation` - Asynchronous test expectations
- `XCUIApplication` - UI testing automation
- `XCTMetric` - Performance measurement
- `XCTAttachment` - Screenshots and data attachments

**Test Types:**
- **Unit Tests** - Test individual components in isolation
- **Integration Tests** - Test component interactions
- **UI Tests** - Test user interface and workflows
- **Performance Tests** - Measure execution time and memory
- **Snapshot Tests** - Visual regression testing

## Unit Testing Patterns

### Basic XCTestCase Structure

```swift
import XCTest
@testable import YourApp

final class ViewModelTests: XCTestCase {
    var sut: LoginViewModel!
    var mockAuthService: MockAuthService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        sut = LoginViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testLoginSuccess() {
        // Given (Arrange)
        let email = "test@example.com"
        let password = "password123"
        mockAuthService.shouldSucceed = true

        // When (Act)
        sut.login(email: email, password: password)

        // Then (Assert)
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockAuthService.loginCallCount, 1)
    }

    func testLoginFailure() {
        // Given
        let email = "test@example.com"
        let password = "wrong"
        mockAuthService.shouldSucceed = false

        // When
        sut.login(email: email, password: password)

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }
}
```

### Given-When-Then Pattern

```swift
func testItemAddedToCart() {
    // Given (Arrange) - Set up test data and initial state
    let cart = ShoppingCart()
    let product = Product(id: 1, name: "iPhone", price: 999.99)
    XCTAssertEqual(cart.items.count, 0)

    // When (Act) - Execute the action being tested
    cart.addItem(product)

    // Then (Assert) - Verify the expected outcome
    XCTAssertEqual(cart.items.count, 1)
    XCTAssertEqual(cart.items.first?.id, product.id)
    XCTAssertEqual(cart.totalPrice, 999.99)
}
```

## Mock Objects and Protocols

### Protocol-Based Mocking

```swift
// Production protocol
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
}

// Mock implementation for testing
final class MockAuthService: AuthServiceProtocol {
    var shouldSucceed = true
    var loginCallCount = 0
    var logoutCallCount = 0
    var capturedEmail: String?
    var capturedPassword: String?

    func login(email: String, password: String) async throws -> User {
        loginCallCount += 1
        capturedEmail = email
        capturedPassword = password

        if shouldSucceed {
            return User(id: "123", email: email, name: "Test User")
        } else {
            throw AuthError.invalidCredentials
        }
    }

    func logout() async throws {
        logoutCallCount += 1
        if !shouldSucceed {
            throw AuthError.logoutFailed
        }
    }
}
```

### Spy Pattern for Verification

```swift
final class NetworkServiceSpy: NetworkServiceProtocol {
    private(set) var requestsCalled: [(endpoint: String, method: HTTPMethod)] = []

    func request<T: Decodable>(_ endpoint: String, method: HTTPMethod) async throws -> T {
        requestsCalled.append((endpoint, method))
        // Return mock data
        throw NetworkError.notImplemented
    }

    func verify(endpoint: String, wasCalledTimes count: Int) -> Bool {
        return requestsCalled.filter { $0.endpoint == endpoint }.count == count
    }
}

// Usage in tests
func testFetchUserMakesNetworkRequest() {
    let spy = NetworkServiceSpy()
    let sut = UserRepository(networkService: spy)

    _ = try? await sut.fetchUser(id: "123")

    XCTAssertTrue(spy.verify(endpoint: "/users/123", wasCalledTimes: 1))
}
```

## Async/Await Testing (Swift 5.5+)

### Testing Async Functions

```swift
func testAsyncFetchUser() async throws {
    // Given
    let mockService = MockUserService()
    let sut = UserViewModel(userService: mockService)

    // When
    await sut.fetchUser(id: "123")

    // Then
    XCTAssertNotNil(sut.currentUser)
    XCTAssertEqual(sut.currentUser?.id, "123")
    XCTAssertFalse(sut.isLoading)
}

func testAsyncErrorHandling() async {
    // Given
    let mockService = MockUserService()
    mockService.shouldThrowError = true
    let sut = UserViewModel(userService: mockService)

    // When
    await sut.fetchUser(id: "123")

    // Then
    XCTAssertNil(sut.currentUser)
    XCTAssertNotNil(sut.errorMessage)
}
```

### Testing with Task and MainActor

```swift
@MainActor
func testMainActorViewModel() async {
    // Given
    let sut = MainActorViewModel()

    // When
    await sut.performAction()

    // Then - Assertions run on MainActor
    XCTAssertTrue(sut.isCompleted)
}

func testBackgroundTask() async {
    // Given
    let sut = BackgroundProcessor()

    // When
    let result = await sut.processData(["a", "b", "c"])

    // Then
    XCTAssertEqual(result.count, 3)
}
```

## XCTestExpectation for Asynchronous Testing

### Basic Expectation Usage

```swift
func testAsyncNetworkCall() {
    // Given
    let expectation = expectation(description: "Network call completes")
    let sut = NetworkManager()

    // When
    sut.fetchData { result in
        // Then
        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)
        case .failure:
            XCTFail("Network call should succeed")
        }
        expectation.fulfill()
    }

    // Wait for expectation
    wait(for: [expectation], timeout: 5.0)
}
```

### Multiple Expectations

```swift
func testMultipleAsyncOperations() {
    let expectation1 = expectation(description: "First operation")
    let expectation2 = expectation(description: "Second operation")

    performFirstOperation {
        expectation1.fulfill()
    }

    performSecondOperation {
        expectation2.fulfill()
    }

    // All expectations must be fulfilled
    wait(for: [expectation1, expectation2], timeout: 10.0)
}
```

### Expectation with Specific Count

```swift
func testNotificationPostedMultipleTimes() {
    let expectation = expectation(forNotification: .dataUpdated, object: nil)
    expectation.expectedFulfillmentCount = 3

    // Trigger notification 3 times
    NotificationCenter.default.post(name: .dataUpdated, object: nil)
    NotificationCenter.default.post(name: .dataUpdated, object: nil)
    NotificationCenter.default.post(name: .dataUpdated, object: nil)

    wait(for: [expectation], timeout: 1.0)
}
```

## Testing ViewModels (MVVM)

### ViewModel Unit Tests

```swift
@MainActor
final class LoginViewModelTests: XCTestCase {
    var sut: LoginViewModel!
    var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        sut = LoginViewModel(authService: mockAuthService)
    }

    func testInitialState() {
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testEmailValidation() {
        // Invalid email
        sut.email = "invalid"
        XCTAssertFalse(sut.isEmailValid)

        // Valid email
        sut.email = "test@example.com"
        XCTAssertTrue(sut.isEmailValid)
    }

    func testLoginSetsLoadingState() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"

        // When - start login
        let loginTask = Task {
            await sut.login()
        }

        // Then - loading should be true immediately
        XCTAssertTrue(sut.isLoading)

        await loginTask.value

        // Then - loading should be false after completion
        XCTAssertFalse(sut.isLoading)
    }

    func testLoginSuccessClearsError() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"
        sut.errorMessage = "Previous error"
        mockAuthService.shouldSucceed = true

        // When
        await sut.login()

        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.isAuthenticated)
    }
}
```

## UI Testing with XCUITest

### Basic UI Test Structure

```swift
import XCTest

final class LoginUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    func testLoginFlow() {
        // Given - App launched on login screen
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]

        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(passwordField.exists)

        // When - Enter credentials and tap login
        emailField.tap()
        emailField.typeText("test@example.com")

        passwordField.tap()
        passwordField.typeText("password123")

        loginButton.tap()

        // Then - Home screen appears
        let homeTitle = app.staticTexts["homeTitle"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 5))
    }

    func testInvalidLoginShowsError() {
        // Given
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]

        // When
        emailField.tap()
        emailField.typeText("invalid@example.com")

        passwordField.tap()
        passwordField.typeText("wrong")

        loginButton.tap()

        // Then
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 3))
    }
}
```

### Accessibility Identifiers

**Setting Identifiers in Code:**
```swift
// SwiftUI
TextField("Email", text: $email)
    .accessibilityIdentifier("emailTextField")

Button("Login") {
    login()
}
.accessibilityIdentifier("loginButton")

// UIKit
emailTextField.accessibilityIdentifier = "emailTextField"
loginButton.accessibilityIdentifier = "loginButton"
```

**Using Identifiers in Tests:**
```swift
let emailField = app.textFields["emailTextField"]
let loginButton = app.buttons["loginButton"]
let errorLabel = app.staticTexts["errorLabel"]
```

### XCUIElement Queries

```swift
func testNavigationFlow() {
    // Query by type
    let firstButton = app.buttons.element(boundBy: 0)
    let allTextFields = app.textFields.allElementsBoundByIndex

    // Query by label
    let settingsButton = app.buttons["Settings"]

    // Query by predicate
    let submitButtons = app.buttons.matching(
        NSPredicate(format: "label CONTAINS 'Submit'")
    )

    // Query descendants
    let tableView = app.tables["itemsTable"]
    let firstCell = tableView.cells.element(boundBy: 0)
    let cellButton = firstCell.buttons["detailButton"]
}
```

## Screenshot Testing

### Capturing Screenshots

```swift
func testHomeScreenAppearance() {
    // Given
    app.launch()

    // When
    let homeScreen = app.otherElements["homeScreen"]
    XCTAssertTrue(homeScreen.waitForExistence(timeout: 3))

    // Capture screenshot
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "Home Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
}
```

### Visual Regression Testing

```swift
extension XCTestCase {
    func assertScreenshot(_ element: XCUIElement, named name: String, file: StaticString = #file, line: UInt = #line) {
        let screenshot = element.screenshot()

        // Compare with baseline (using external library like SnapshotTesting)
        // assertSnapshot(matching: screenshot, as: .image, named: name, file: file, line: line)

        // Or just attach for manual comparison
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        add(attachment)
    }
}
```

## Performance Testing

### Measuring Execution Time

```swift
func testPerformanceOfDataProcessing() {
    let processor = DataProcessor()
    let largeDataSet = generateLargeDataSet()

    measure {
        _ = processor.process(largeDataSet)
    }
    // XCTest will run this block 10 times and report average
}
```

### XCTMetric for Custom Measurements

```swift
func testMemoryUsage() {
    let options = XCTMeasureOptions()
    options.iterationCount = 5

    measure(metrics: [XCTMemoryMetric()], options: options) {
        let viewModel = HeavyViewModel()
        viewModel.loadLargeDataSet()
    }
}

func testCPUUsage() {
    measure(metrics: [XCTCPUMetric(), XCTClockMetric()]) {
        performCPUIntensiveTask()
    }
}

func testDiskWrites() {
    measure(metrics: [XCTStorageMetric()]) {
        saveLargeFile()
    }
}
```

### Animation Performance

```swift
func testScrollPerformance() {
    let app = XCUIApplication()
    app.launch()

    let tableView = app.tables["itemsTable"]

    measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
        tableView.swipeUp(velocity: .fast)
        tableView.swipeDown(velocity: .fast)
    }
}
```

## Code Coverage

### Enabling Code Coverage

**Xcode Scheme Settings:**
1. Edit Scheme → Test
2. Options → Check "Gather coverage for some targets"
3. Select targets to measure

### Coverage Reports

```bash
# Generate coverage report
xcodebuild test -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# View coverage in Xcode
# Report Navigator → Coverage tab
```

### Coverage Thresholds

```swift
// Set minimum coverage requirement in CI/CD
// Example: Fail build if coverage drops below 80%

// .xccovrc file
{
  "coverage_targets": {
    "YourApp": {
      "minimum_coverage": 80
    }
  }
}
```

## Test Organization Patterns

### Test Suite Structure

```
YourAppTests/
├── Unit/
│   ├── ViewModels/
│   │   ├── LoginViewModelTests.swift
│   │   └── HomeViewModelTests.swift
│   ├── Services/
│   │   ├── AuthServiceTests.swift
│   │   └── NetworkServiceTests.swift
│   └── Models/
│       └── UserTests.swift
├── Integration/
│   ├── AuthenticationFlowTests.swift
│   └── DataSyncTests.swift
├── UI/
│   ├── LoginUITests.swift
│   └── NavigationUITests.swift
├── Performance/
│   └── PerformanceTests.swift
└── Helpers/
    ├── Mocks/
    │   ├── MockAuthService.swift
    │   └── MockNetworkService.swift
    └── Extensions/
        └── XCTestCase+Helpers.swift
```

### Shared Test Helpers

```swift
extension XCTestCase {
    func waitForCondition(timeout: TimeInterval = 5.0, condition: @escaping () -> Bool) {
        let expectation = expectation(description: "Waiting for condition")

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            }
        }

        wait(for: [expectation], timeout: timeout)
        timer.invalidate()
    }

    func createMockUser(id: String = "123", email: String = "test@example.com") -> User {
        User(id: id, email: email, name: "Test User")
    }
}
```

## Test Data Builders

### Builder Pattern for Test Data

```swift
final class UserBuilder {
    private var id = "123"
    private var email = "test@example.com"
    private var name = "Test User"
    private var isActive = true

    func withId(_ id: String) -> UserBuilder {
        self.id = id
        return self
    }

    func withEmail(_ email: String) -> UserBuilder {
        self.email = email
        return self
    }

    func inactive() -> UserBuilder {
        self.isActive = false
        return self
    }

    func build() -> User {
        User(id: id, email: email, name: name, isActive: isActive)
    }
}

// Usage in tests
func testActiveUserCanLogin() {
    let user = UserBuilder()
        .withEmail("active@example.com")
        .build()

    XCTAssertTrue(user.isActive)
}

func testInactiveUserCannotLogin() {
    let user = UserBuilder()
        .withEmail("inactive@example.com")
        .inactive()
        .build()

    XCTAssertFalse(user.isActive)
}
```

## Testing Best Practices

### 1. Test Naming Convention

```swift
// ✅ Good: Descriptive test names
func testLoginWithValidCredentials_SetsAuthenticatedState()
func testFetchUser_WhenNetworkFails_SetsErrorMessage()
func testAddItemToCart_IncreasesItemCount()

// ❌ Avoid: Vague test names
func testLogin()
func testFetch()
func testAdd()
```

### 2. One Assertion per Concept

```swift
// ✅ Good: Focused test
func testLoginSuccess_SetsAuthenticatedFlag() {
    sut.login(email: "test@example.com", password: "password")
    XCTAssertTrue(sut.isAuthenticated)
}

func testLoginSuccess_ClearsErrorMessage() {
    sut.errorMessage = "Previous error"
    sut.login(email: "test@example.com", password: "password")
    XCTAssertNil(sut.errorMessage)
}

// ❌ Avoid: Testing multiple concepts
func testLogin() {
    sut.login(email: "test@example.com", password: "password")
    XCTAssertTrue(sut.isAuthenticated)
    XCTAssertNil(sut.errorMessage)
    XCTAssertNotNil(sut.user)
    XCTAssertEqual(sut.loginCount, 1)
}
```

### 3. Avoid Test Interdependence

```swift
// ✅ Good: Independent tests
class CartTests: XCTestCase {
    var sut: ShoppingCart!

    override func setUp() {
        super.setUp()
        sut = ShoppingCart() // Fresh instance for each test
    }

    func testAddFirstItem() {
        sut.addItem(Product(id: 1, name: "Item", price: 10))
        XCTAssertEqual(sut.items.count, 1)
    }

    func testAddSecondItem() {
        sut.addItem(Product(id: 1, name: "Item 1", price: 10))
        sut.addItem(Product(id: 2, name: "Item 2", price: 20))
        XCTAssertEqual(sut.items.count, 2)
    }
}
```

### 4. Use Descriptive Failure Messages

```swift
XCTAssertEqual(
    cart.totalPrice,
    99.99,
    "Cart total should match sum of item prices"
)

XCTAssertNotNil(
    user,
    "User should be loaded after successful login"
)
```

### 5. Test Edge Cases

```swift
func testCartWithZeroItems_HasZeroTotal() {
    let cart = ShoppingCart()
    XCTAssertEqual(cart.totalPrice, 0)
}

func testCartWithNegativeQuantity_ThrowsError() {
    let cart = ShoppingCart()
    XCTAssertThrowsError(
        try cart.addItem(Product(id: 1, name: "Item", price: 10), quantity: -1)
    )
}

func testCartWithMaxIntItems_DoesNotOverflow() {
    // Test boundary conditions
}
```

## Common XCTest Assertions

```swift
// Equality
XCTAssertEqual(a, b)
XCTAssertNotEqual(a, b)

// Nil checks
XCTAssertNil(value)
XCTAssertNotNil(value)

// Boolean
XCTAssertTrue(condition)
XCTAssertFalse(condition)

// Throwing errors
XCTAssertThrowsError(try expression)
XCTAssertNoThrow(try expression)

// Numeric comparisons
XCTAssertGreaterThan(a, b)
XCTAssertLessThan(a, b)
XCTAssertGreaterThanOrEqual(a, b)

// Type checking
XCTAssertIsType(value, ExpectedType.self)

// Failure
XCTFail("This should not be reached")
```

## Troubleshooting

### Tests Run Slowly

```swift
// Parallelize tests
// Test Plan → Options → Execute in parallel

// Reduce setUp/tearDown overhead
override func setUp() {
    super.setUp()
    // Only create what's needed for THIS test class
}

// Use @MainActor sparingly
// Only when testing MainActor-isolated code
```

### Flaky Tests

```swift
// Add explicit waits for async operations
let element = app.buttons["submit"]
XCTAssertTrue(element.waitForExistence(timeout: 5))

// Use expectations instead of sleep()
let expectation = expectation(description: "Data loaded")
// ... fulfill expectation
wait(for: [expectation], timeout: 5)
```

### UI Tests Can't Find Elements

```swift
// Set accessibility identifiers
button.accessibilityIdentifier = "loginButton"

// Use waitForExistence
let button = app.buttons["loginButton"]
XCTAssertTrue(button.waitForExistence(timeout: 3))

// Check element hierarchy
print(app.debugDescription)
```

## References

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Tips and Tricks (WWDC)](https://developer.apple.com/videos/play/wwdc2018/417/)
- [UI Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
