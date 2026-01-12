---
name: "Error Handling Patterns"
description: "Comprehensive error handling strategies for iOS/tvOS applications using Swift Result types, custom errors, and user-facing error presentation"
version: "2.0.0"
---

# Error Handling Patterns for iOS/tvOS

Complete guide to implementing robust error handling in Swift applications using Result types, custom error enums, propagation strategies, recovery mechanisms, and user-friendly error presentation.

## Swift Error Handling Fundamentals

### Error Protocol

```swift
// Base protocol for all Swift errors
protocol Error {}

// Custom error types conform to Error
enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
}
```

### Throwing Functions

```swift
// Function that can throw errors
func fetchUser(id: String) throws -> User {
    guard !id.isEmpty else {
        throw ValidationError.emptyID
    }

    // Network request...
    guard let response = response else {
        throw NetworkError.invalidResponse
    }

    return user
}
```

### Do-Catch Pattern

```swift
// Basic do-catch
do {
    let user = try fetchUser(id: "123")
    print("User: \(user.name)")
} catch let error as NetworkError {
    print("Network error: \(error)")
} catch let error as ValidationError {
    print("Validation error: \(error)")
} catch {
    print("Unknown error: \(error)")
}
```

## Result Type Pattern

### Basic Result Usage

```swift
// Result<Success, Failure> type
func fetchUser(id: String) -> Result<User, Error> {
    guard !id.isEmpty else {
        return .failure(ValidationError.emptyID)
    }

    // Simulate network request
    if let user = performRequest() {
        return .success(user)
    } else {
        return .failure(NetworkError.invalidResponse)
    }
}

// Using Result
let result = fetchUser(id: "123")
switch result {
case .success(let user):
    print("User: \(user.name)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Result with Async/Await

```swift
// Modern async function returning Result
func fetchUser(id: String) async -> Result<User, NetworkError> {
    do {
        let user = try await networkManager.getUser(id: id)
        return .success(user)
    } catch let error as NetworkError {
        return .failure(error)
    } catch {
        return .failure(.unknown)
    }
}

// Usage with async/await
Task {
    let result = await fetchUser(id: "123")
    switch result {
    case .success(let user):
        print("User: \(user.name)")
    case .failure(let error):
        handleError(error)
    }
}
```

### Result Transformation

```swift
// Map success value
let userResult: Result<User, NetworkError> = fetchUser(id: "123")
let nameResult: Result<String, NetworkError> = userResult.map { $0.name }

// FlatMap for chaining Results
let emailResult: Result<String, NetworkError> = userResult.flatMap { user in
    validateEmail(user.email)
}

// MapError to transform error type
let transformedResult: Result<User, AppError> = userResult.mapError { networkError in
    AppError.network(networkError)
}
```

## Custom Error Enums

### Network Errors

```swift
enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(statusCode: Int, message: String?)
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimitExceeded
    case unknown

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError(let code, let message):
            return message ?? "Server error (Code: \(code))"
        case .invalidResponse:
            return "Invalid response from server."
        case .unauthorized:
            return "You are not authorized. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your Wi-Fi or cellular connection and try again."
        case .timeout:
            return "Make sure you have a stable internet connection."
        case .unauthorized:
            return "Please log out and log in again."
        case .rateLimitExceeded:
            return "Wait a few minutes before trying again."
        default:
            return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError:
            return true
        case .unauthorized, .forbidden, .notFound:
            return false
        case .invalidResponse, .rateLimitExceeded, .unknown:
            return true
        }
    }
}
```

### Validation Errors

```swift
enum ValidationError: Error, LocalizedError {
    case emptyField(fieldName: String)
    case invalidEmail
    case passwordTooShort(minLength: Int)
    case passwordMismatch
    case invalidPhoneNumber
    case invalidDate
    case outOfRange(min: Int, max: Int)

    var errorDescription: String? {
        switch self {
        case .emptyField(let fieldName):
            return "\(fieldName) cannot be empty."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .passwordTooShort(let minLength):
            return "Password must be at least \(minLength) characters."
        case .passwordMismatch:
            return "Passwords do not match."
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
        case .invalidDate:
            return "Please enter a valid date."
        case .outOfRange(let min, let max):
            return "Value must be between \(min) and \(max)."
        }
    }
}
```

### Domain-Specific Errors

```swift
enum AuthenticationError: Error, LocalizedError {
    case invalidCredentials
    case accountLocked
    case sessionExpired
    case tokenRefreshFailed
    case biometricAuthFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .accountLocked:
            return "Your account has been locked. Please contact support."
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication. Please log in again."
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please use your password."
        }
    }
}

enum PaymentError: Error, LocalizedError {
    case cardDeclined
    case insufficientFunds
    case invalidCardNumber
    case expiredCard
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .cardDeclined:
            return "Your card was declined. Please try another payment method."
        case .insufficientFunds:
            return "Insufficient funds. Please check your balance."
        case .invalidCardNumber:
            return "Invalid card number. Please check and try again."
        case .expiredCard:
            return "Your card has expired. Please use a different card."
        case .processingFailed:
            return "Payment processing failed. Please try again."
        }
    }
}
```

## Error Propagation Patterns

### Rethrowing Functions

```swift
// Function that rethrows errors from closure
func performWithRetry<T>(
    maxAttempts: Int = 3,
    operation: () throws -> T
) rethrows -> T {
    var attempts = 0
    var lastError: Error?

    while attempts < maxAttempts {
        do {
            return try operation()
        } catch {
            lastError = error
            attempts += 1
        }
    }

    throw lastError!
}

// Usage
do {
    let user = try performWithRetry {
        try fetchUser(id: "123")
    }
} catch {
    print("Failed after retries: \(error)")
}
```

### Error Chaining

```swift
// Chain multiple throwing operations
func completeUserRegistration(email: String, password: String) async throws -> User {
    // 1. Validate input
    try validateEmail(email)
    try validatePassword(password)

    // 2. Create account
    let user = try await createAccount(email: email, password: password)

    // 3. Send verification email
    try await sendVerificationEmail(to: email)

    // 4. Log analytics event
    try await logRegistrationEvent(userId: user.id)

    return user
}
```

### Optional Try

```swift
// try? converts error to nil
let user = try? fetchUser(id: "123")  // Returns User? instead of throwing

// try! force-unwraps (crashes on error - use sparingly)
let user = try! fetchUser(id: "123")  // Only if you're 100% sure it won't fail
```

## Error Recovery Strategies

### Retry with Exponential Backoff

```swift
actor RetryManager {
    func performWithExponentialBackoff<T>(
        maxAttempts: Int = 5,
        baseDelay: TimeInterval = 1.0,
        operation: () async throws -> T
    ) async throws -> T {
        var attempts = 0
        var delay = baseDelay

        while attempts < maxAttempts {
            do {
                return try await operation()
            } catch let error as NetworkError where error.isRetryable {
                attempts += 1
                if attempts >= maxAttempts {
                    throw error
                }

                // Exponential backoff: 1s, 2s, 4s, 8s, 16s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay *= 2
            } catch {
                // Non-retryable error
                throw error
            }
        }

        fatalError("Should not reach here")
    }
}

// Usage
let retryManager = RetryManager()
do {
    let user = try await retryManager.performWithExponentialBackoff {
        try await fetchUser(id: "123")
    }
} catch {
    print("Failed after retries: \(error)")
}
```

### Fallback Values

```swift
// Provide default value on error
func getUserName(id: String) async -> String {
    do {
        let user = try await fetchUser(id: id)
        return user.name
    } catch {
        return "Unknown User"
    }
}

// Using Result with default value
let userName = await fetchUser(id: "123")
    .map { $0.name }
    .recover { error in "Unknown User" }
```

### Circuit Breaker Pattern

```swift
actor CircuitBreaker {
    enum State {
        case closed      // Normal operation
        case open        // Failures detected, reject requests
        case halfOpen    // Testing if service recovered
    }

    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let failureThreshold = 5
    private let timeout: TimeInterval = 60.0

    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .open:
            // Check if timeout has passed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > timeout {
                state = .halfOpen
            } else {
                throw NetworkError.serverError(statusCode: 503, message: "Circuit breaker is open")
            }
        case .halfOpen, .closed:
            break
        }

        do {
            let result = try await operation()
            onSuccess()
            return result
        } catch {
            onFailure()
            throw error
        }
    }

    private func onSuccess() {
        failureCount = 0
        state = .closed
    }

    private func onFailure() {
        failureCount += 1
        lastFailureTime = Date()

        if failureCount >= failureThreshold {
            state = .open
        }
    }
}
```

## User-Facing Error Presentation

### SwiftUI Alert Presentation

```swift
// ViewModel with error handling
@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var showError = false

    func loadUser(id: String) async {
        do {
            user = try await fetchUser(id: id)
        } catch let error as LocalizedError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = "An unexpected error occurred."
            showError = true
        }
    }
}

// SwiftUI View
struct UserView: View {
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        VStack {
            if let user = viewModel.user {
                Text("User: \(user.name)")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .task {
            await viewModel.loadUser(id: "123")
        }
    }
}
```

### Custom Error View

```swift
struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text(errorTitle)
                .font(.headline)

            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction, isRetryable {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var errorTitle: String {
        if let localizedError = error as? LocalizedError {
            return localizedError.errorDescription ?? "Error"
        }
        return "Error"
    }

    private var errorMessage: String {
        (error as? LocalizedError)?.failureReason ?? error.localizedDescription
    }

    private var recoverySuggestion: String? {
        (error as? LocalizedError)?.recoverySuggestion
    }

    private var isRetryable: Bool {
        (error as? NetworkError)?.isRetryable ?? false
    }
}
```

### Toast Notifications

```swift
// Toast notification for non-critical errors
struct ToastView: View {
    let message: String
    let type: ToastType

    enum ToastType {
        case error, warning, success, info

        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .success: return .green
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(.white)

            Text(message)
                .foregroundColor(.white)
                .font(.body)

            Spacer()
        }
        .padding()
        .background(type.color)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// Toast Manager
@MainActor
final class ToastManager: ObservableObject {
    @Published var toast: Toast?

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastView.ToastType
    }

    func show(_ message: String, type: ToastView.ToastType = .info, duration: TimeInterval = 3.0) {
        toast = Toast(message: message, type: type)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if toast?.id == toast?.id {
                toast = nil
            }
        }
    }

    func showError(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        show(message, type: .error)
    }
}
```

## Error Logging and Analytics

### Structured Logging

```swift
import os.log

final class ErrorLogger {
    static let shared = ErrorLogger()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "errors")

    func log(_ error: Error, context: [String: Any] = [:]) {
        let errorDescription = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription

        logger.error("""
            Error: \(errorDescription)
            Type: \(String(describing: type(of: error)))
            Context: \(context.description)
            """)

        // Send to analytics
        Analytics.shared.trackError(error, context: context)
    }

    func logNetworkError(_ error: NetworkError, endpoint: String, statusCode: Int?) {
        log(error, context: [
            "endpoint": endpoint,
            "statusCode": statusCode ?? 0,
            "isRetryable": error.isRetryable
        ])
    }
}
```

### Error Analytics

```swift
protocol ErrorAnalytics {
    func trackError(_ error: Error, context: [String: Any])
}

final class Analytics: ErrorAnalytics {
    static let shared = Analytics()

    func trackError(_ error: Error, context: [String: Any]) {
        let errorName = String(describing: type(of: error))
        let errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription

        // Send to analytics service (Firebase, Amplitude, etc.)
        #if DEBUG
        print("Analytics - Error: \(errorName), Message: \(errorMessage), Context: \(context)")
        #else
        // Production analytics tracking
        // FirebaseAnalytics.logEvent("error_occurred", parameters: [
        //     "error_name": errorName,
        //     "error_message": errorMessage,
        //     ...context
        // ])
        #endif
    }
}
```

## Best Practices

### 1. Use Specific Error Types

```swift
// ✅ Good: Specific error type
enum UserServiceError: Error {
    case userNotFound
    case invalidUserData
}

// ❌ Avoid: Generic error messages
enum GenericError: Error {
    case somethingWentWrong
}
```

### 2. Provide User-Friendly Messages

```swift
// ✅ Good: Implement LocalizedError
enum NetworkError: Error, LocalizedError {
    case timeout

    var errorDescription: String? {
        "The request timed out. Please try again."
    }
}

// ❌ Avoid: Technical error messages
throw NSError(domain: "com.app", code: 1001, userInfo: nil)
```

### 3. Handle Errors at Appropriate Level

```swift
// ✅ Good: Handle at ViewModel, present in View
@MainActor
final class ViewModel: ObservableObject {
    @Published var errorMessage: String?

    func loadData() async {
        do {
            try await service.fetchData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// ❌ Avoid: Swallowing errors silently
func loadData() async {
    try? await service.fetchData()  // Error is ignored
}
```

### 4. Use Result for Explicit Error Handling

```swift
// ✅ Good: Explicit success/failure
func fetchUser() async -> Result<User, NetworkError> {
    // Implementation
}

// Usage forces error handling
let result = await fetchUser()
switch result {
case .success(let user): print(user)
case .failure(let error): handleError(error)
}
```

## Testing Error Handling

### Unit Tests

```swift
final class ErrorHandlingTests: XCTestCase {
    func testNetworkErrorHandling() async {
        // Given
        let mockService = MockNetworkService()
        mockService.shouldFail = true
        mockService.errorToThrow = NetworkError.timeout

        // When
        let result = await mockService.fetchUser(id: "123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, NetworkError.timeout)
        }
    }

    func testRetryLogic() async {
        // Given
        let retryManager = RetryManager()
        var attemptCount = 0

        // When
        do {
            _ = try await retryManager.performWithExponentialBackoff(maxAttempts: 3) {
                attemptCount += 1
                if attemptCount < 3 {
                    throw NetworkError.timeout
                }
                return "Success"
            }
        } catch {
            XCTFail("Should succeed after retries")
        }

        // Then
        XCTAssertEqual(attemptCount, 3)
    }
}
```

## References

- [Swift Error Handling Guide](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)
- [Result Type Documentation](https://developer.apple.com/documentation/swift/result)
- [LocalizedError Protocol](https://developer.apple.com/documentation/foundation/localizederror)
- [Error Handling Best Practices](https://www.swiftbysundell.com/articles/error-handling-in-swift/)
