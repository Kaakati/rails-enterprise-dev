---
name: "Session Management"
description: "Comprehensive user session, authentication, and token management patterns for iOS/tvOS"
version: "2.0.0"
---

# Session Management for iOS/tvOS

Complete guide to implementing secure session management, token storage with Keychain, authentication flows, and session persistence in iOS/tvOS applications.

## Core SessionManager Pattern

### Singleton SessionManager

```swift
@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?

    private let keychainService = "com.yourapp.auth"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"

    private init() {
        // Load persisted session on init
        loadSession()
    }

    // MARK: - Authentication

    func login(email: String, password: String) async throws {
        // Call authentication API
        let authResponse = try await AuthAPI.login(email: email, password: password)

        // Store tokens securely
        try storeTokens(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken
        )

        // Update session state
        self.currentUser = authResponse.user
        self.isAuthenticated = true
    }

    func logout() {
        // Clear tokens
        clearTokens()

        // Clear user data
        currentUser = nil
        isAuthenticated = false

        // Clear additional cached data if needed
        clearUserDefaults()
    }

    // MARK: - Token Management

    func getAccessToken() -> String? {
        return KeychainHelper.shared.read(
            service: keychainService,
            account: accessTokenKey
        )
    }

    func refreshAccessToken() async throws {
        guard let refreshToken = KeychainHelper.shared.read(
            service: keychainService,
            account: refreshTokenKey
        ) else {
            throw SessionError.noRefreshToken
        }

        let response = try await AuthAPI.refreshToken(refreshToken: refreshToken)

        try storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }

    // MARK: - Private Helpers

    private func storeTokens(accessToken: String, refreshToken: String) throws {
        try KeychainHelper.shared.save(
            accessToken,
            service: keychainService,
            account: accessTokenKey
        )

        try KeychainHelper.shared.save(
            refreshToken,
            service: keychainService,
            account: refreshTokenKey
        )
    }

    private func clearTokens() {
        KeychainHelper.shared.delete(service: keychainService, account: accessTokenKey)
        KeychainHelper.shared.delete(service: keychainService, account: refreshTokenKey)
    }

    private func loadSession() {
        // Check if tokens exist
        if let accessToken = getAccessToken() {
            // Validate token (check expiration)
            if !isTokenExpired(accessToken) {
                isAuthenticated = true
                // Load user profile
                Task {
                    try? await loadUserProfile()
                }
            } else {
                // Try refresh
                Task {
                    try? await refreshAccessToken()
                    try? await loadUserProfile()
                }
            }
        }
    }

    private func loadUserProfile() async throws {
        let user = try await UserAPI.getProfile()
        self.currentUser = user
        self.isAuthenticated = true
    }

    private func isTokenExpired(_ token: String) -> Bool {
        // JWT token validation
        // Parse token and check exp claim
        guard let jwt = try? decode(jwt: token) else { return true }
        return Date() > jwt.expirationDate
    }

    private func clearUserDefaults() {
        // Clear any cached user preferences
        UserDefaults.standard.removeObject(forKey: "userPreferences")
    }
}

enum SessionError: LocalizedError {
    case noRefreshToken
    case invalidToken
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "No refresh token available"
        case .invalidToken:
            return "Invalid authentication token"
        case .sessionExpired:
            return "Session has expired"
        }
    }
}
```

## Keychain Integration

### Secure KeychainHelper

```swift
final class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    func save(_ data: String, service: String, account: String) throws {
        guard let data = data.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status: status)
        }
    }

    func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }

    func deleteAll(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: LocalizedError {
    case invalidData
    case unableToSave(status: OSStatus)
    case unableToRetrieve

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .unableToSave(let status):
            return "Unable to save to Keychain (status: \(status))"
        case .unableToRetrieve:
            return "Unable to retrieve from Keychain"
        }
    }
}
```

## Token Refresh Flow

### Automatic Token Refresh

```swift
final class NetworkClient {
    private let sessionManager: SessionManager

    init(sessionManager: SessionManager = .shared) {
        self.sessionManager = sessionManager
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = try endpoint.asURLRequest()

        // Add access token
        if let accessToken = sessionManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check for 401 Unauthorized
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            // Try refreshing token
            try await sessionManager.refreshAccessToken()

            // Retry original request with new token
            if let newToken = sessionManager.getAccessToken() {
                request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(T.self, from: retryData)
            }
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

### Token Expiration Handling

```swift
extension SessionManager {
    func scheduleTokenRefresh() {
        guard let accessToken = getAccessToken(),
              let jwt = try? decode(jwt: accessToken) else {
            return
        }

        // Schedule refresh 5 minutes before expiration
        let refreshTime = jwt.expirationDate.addingTimeInterval(-300)
        let timeInterval = refreshTime.timeIntervalSinceNow

        if timeInterval > 0 {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
                try? await refreshAccessToken()
                scheduleTokenRefresh() // Reschedule for new token
            }
        }
    }
}
```

## Multi-User Session Handling

### Multiple Account Support

```swift
final class MultiUserSessionManager: ObservableObject {
    @Published private(set) var activeUserId: String?
    @Published private(set) var availableUsers: [UserAccount] = []

    private let userAccountsKey = "userAccounts"

    func addAccount(email: String, password: String) async throws {
        let authResponse = try await AuthAPI.login(email: email, password: password)

        // Create user account
        let account = UserAccount(
            id: authResponse.user.id,
            email: email,
            name: authResponse.user.name,
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken
        )

        // Store in keychain with user-specific keys
        try storeAccount(account)

        // Add to available users
        availableUsers.append(account)
        saveAvailableUsers()

        // Switch to new account
        switchToAccount(userId: account.id)
    }

    func switchToAccount(userId: String) {
        activeUserId = userId

        // Notify observers
        NotificationCenter.default.post(
            name: .userAccountDidChange,
            object: nil,
            userInfo: ["userId": userId]
        )
    }

    func removeAccount(userId: String) {
        // Remove from keychain
        let service = "com.yourapp.auth.\(userId)"
        KeychainHelper.shared.deleteAll(service: service)

        // Remove from available users
        availableUsers.removeAll { $0.id == userId }
        saveAvailableUsers()

        // Switch to another account if removed was active
        if activeUserId == userId {
            activeUserId = availableUsers.first?.id
        }
    }

    private func storeAccount(_ account: UserAccount) throws {
        let service = "com.yourapp.auth.\(account.id)"

        try KeychainHelper.shared.save(
            account.accessToken,
            service: service,
            account: "accessToken"
        )

        try KeychainHelper.shared.save(
            account.refreshToken,
            service: service,
            account: "refreshToken"
        )
    }

    private func saveAvailableUsers() {
        let accountData = availableUsers.map { account in
            ["id": account.id, "email": account.email, "name": account.name]
        }

        UserDefaults.standard.set(accountData, forKey: userAccountsKey)
    }
}

struct UserAccount: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    var accessToken: String
    var refreshToken: String
}
```

## Guest Authentication

### Guest Session Flow

```swift
extension SessionManager {
    func loginAsGuest() async throws {
        // Create guest session
        let guestResponse = try await AuthAPI.createGuestSession()

        // Store guest token
        try storeTokens(
            accessToken: guestResponse.accessToken,
            refreshToken: guestResponse.refreshToken
        )

        // Create guest user
        self.currentUser = User(
            id: guestResponse.userId,
            email: nil,
            name: "Guest",
            isGuest: true
        )

        self.isAuthenticated = true
    }

    func convertGuestToRegistered(email: String, password: String) async throws {
        guard let guestUser = currentUser, guestUser.isGuest else {
            throw SessionError.notGuestSession
        }

        // Convert guest account
        let response = try await AuthAPI.convertGuest(
            guestId: guestUser.id,
            email: email,
            password: password
        )

        // Update session with new tokens
        try storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        // Update user
        self.currentUser = response.user
    }
}
```

## Session Expiration Handling

### Auto-Logout on Expiration

```swift
extension SessionManager {
    func startSessionMonitoring() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkSessionValidity()
            }
            .store(in: &cancellables)
    }

    private func checkSessionValidity() {
        guard let accessToken = getAccessToken() else {
            logout()
            return
        }

        if isTokenExpired(accessToken) {
            // Try to refresh
            Task {
                do {
                    try await refreshAccessToken()
                } catch {
                    // Refresh failed, logout user
                    await MainActor.run {
                        logout()
                        showSessionExpiredAlert()
                    }
                }
            }
        }
    }

    private func showSessionExpiredAlert() {
        NotificationCenter.default.post(
            name: .sessionExpired,
            object: nil
        )
    }
}

extension Notification.Name {
    static let sessionExpired = Notification.Name("sessionExpired")
    static let userAccountDidChange = Notification.Name("userAccountDidChange")
}
```

## OAuth2 / OIDC Integration

### OAuth2 Flow

```swift
import AuthenticationServices

final class OAuth2Manager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuth2Manager()

    func loginWithOAuth(provider: OAuthProvider) async throws -> AuthResponse {
        let authURL = buildAuthorizationURL(provider: provider)

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "yourapp"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let url = callbackURL,
                      let code = self.extractAuthorizationCode(from: url) else {
                    continuation.resume(throwing: OAuth2Error.invalidCallback)
                    return
                }

                Task {
                    do {
                        let response = try await self.exchangeCodeForTokens(
                            code: code,
                            provider: provider
                        )
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private func buildAuthorizationURL(provider: OAuthProvider) -> URL {
        var components = URLComponents(string: provider.authorizationEndpoint)!

        components.queryItems = [
            URLQueryItem(name: "client_id", value: provider.clientId),
            URLQueryItem(name: "redirect_uri", value: provider.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: provider.scopes.joined(separator: " "))
        ]

        return components.url!
    }

    private func extractAuthorizationCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    private func exchangeCodeForTokens(code: String, provider: OAuthProvider) async throws -> AuthResponse {
        // Exchange authorization code for access/refresh tokens
        // Implementation depends on provider API
        fatalError("Not implemented")
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
}

struct OAuthProvider {
    let clientId: String
    let authorizationEndpoint: String
    let tokenEndpoint: String
    let redirectURI: String
    let scopes: [String]
}

enum OAuth2Error: LocalizedError {
    case invalidCallback
    case authorizationFailed
}
```

## Security Best Practices

### 1. Never Store Passwords

```swift
// ✅ Good: Store only tokens
try KeychainHelper.shared.save(accessToken, service: service, account: "accessToken")

// ❌ Bad: Never store plain passwords
// try KeychainHelper.shared.save(password, ...)
```

### 2. Use Appropriate Keychain Accessibility

```swift
// For sensitive data (like tokens)
kSecAttrAccessibleAfterFirstUnlock

// For highly sensitive data (like biometric auth)
kSecAttrAccessibleWhenUnlockedThisDeviceOnly
```

### 3. Implement Certificate Pinning

```swift
final class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Validate certificate
        if isServerTrusted(serverTrust) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func isServerTrusted(_ serverTrust: SecTrust) -> Bool {
        // Implement certificate pinning validation
        return true
    }
}
```

### 4. Clear Session on Logout

```swift
func secureLogout() {
    // Clear tokens
    clearTokens()

    // Clear user data
    currentUser = nil
    isAuthenticated = false

    // Clear all UserDefaults
    if let bundleID = Bundle.main.bundleIdentifier {
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
    }

    // Clear URL cache
    URLCache.shared.removeAllCachedResponses()

    // Clear cookies
    HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
}
```

## Testing Session Management

```swift
final class SessionManagerTests: XCTestCase {
    var sut: SessionManager!

    override func setUp() {
        super.setUp()
        sut = SessionManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testLoginSuccess() async throws {
        try await sut.login(email: "test@example.com", password: "password")

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
    }

    func testLogout() {
        sut.logout()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNil(sut.getAccessToken())
    }

    func testTokenRefresh() async throws {
        // Mock expired token
        try sut.storeTokens(accessToken: "expired", refreshToken: "valid")

        try await sut.refreshAccessToken()

        XCTAssertNotNil(sut.getAccessToken())
    }
}
```

## References

- [Keychain Services Documentation](https://developer.apple.com/documentation/security/keychain_services)
- [OAuth 2.0 RFC](https://datatracker.ietf.org/doc/html/rfc6749)
- [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
