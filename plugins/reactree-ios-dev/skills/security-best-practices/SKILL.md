---
name: "Security Best Practices"
description: "iOS/tvOS security best practices including Keychain usage, certificate pinning, secure data storage, and API key protection"
version: "2.0.0"
---

# Security Best Practices for iOS/tvOS

Complete guide to implementing security best practices in iOS/tvOS applications including Keychain storage, certificate pinning, secure coding, and API key protection.

## Keychain Storage

### Basic Keychain Operations

```swift
import Security

final class KeychainManager {
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }

    // Save
    static func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateItem
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // Load
    static func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }

        return data
    }

    // Update
    static func update(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // Delete
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// Usage
let token = "secret_token_123"
let data = token.data(using: .utf8)!

try KeychainManager.save(key: "authToken", data: data)
let loadedData = try KeychainManager.load(key: "authToken")
let loadedToken = String(data: loadedData, encoding: .utf8)
```

### Token Storage

```swift
final class SecureTokenManager {
    private static let tokenKey = "com.app.authToken"
    private static let refreshTokenKey = "com.app.refreshToken"

    static func saveAuthToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else { return }
        try KeychainManager.save(key: tokenKey, data: data)
    }

    static func loadAuthToken() -> String? {
        guard let data = try? KeychainManager.load(key: tokenKey),
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    static func deleteAuthToken() {
        try? KeychainManager.delete(key: tokenKey)
        try? KeychainManager.delete(key: refreshTokenKey)
    }
}
```

## Certificate Pinning

### SSL Pinning with URLSession

```swift
final class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [Data]

    init(certificateNames: [String]) {
        pinnedCertificates = certificateNames.compactMap { name in
            guard let certPath = Bundle.main.path(forResource: name, ofType: "cer"),
                  let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) else {
                return nil
            }
            return certData
        }
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Evaluate server trust
        guard SecTrustEvaluateWithError(serverTrust, nil) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Get server certificate
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data

        // Check if matches pinned certificate
        if pinnedCertificates.contains(serverCertificateData) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// Usage
let delegate = PinnedURLSessionDelegate(certificateNames: ["api_certificate"])
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
```

## Secure Data Storage

### File Encryption

```swift
final class SecureFileManager {
    enum EncryptionError: Error {
        case encryptionFailed
        case decryptionFailed
    }

    static func saveEncrypted(data: Data, filename: String, key: String) throws {
        // Generate encryption key from password
        guard let keyData = key.data(using: .utf8) else {
            throw EncryptionError.encryptionFailed
        }

        var encryptedData = data
        let status = SecKeyEncrypt(
            /* key */,
            .PKCS1,
            data.bytes,
            data.count,
            &encryptedData.mutableBytes,
            encryptedData.count
        )

        guard status == errSecSuccess else {
            throw EncryptionError.encryptionFailed
        }

        // Save to file
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        try encryptedData.write(to: fileURL, options: .completeFileProtection)
    }

    static func loadEncrypted(filename: String, key: String) throws -> Data {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        let encryptedData = try Data(contentsOf: fileURL)

        // Decrypt
        var decryptedData = Data()
        let status = SecKeyDecrypt(
            /* key */,
            .PKCS1,
            encryptedData.bytes,
            encryptedData.count,
            &decryptedData.mutableBytes,
            decryptedData.count
        )

        guard status == errSecSuccess else {
            throw EncryptionError.decryptionFailed
        }

        return decryptedData
    }
}
```

### Data Protection Attributes

```swift
// File protection levels
let attributes: [FileAttributeKey: Any] = [
    .protectionKey: FileProtectionType.complete  // Encrypted when device locked
]

try data.write(to: fileURL, options: .completeFileProtection)

// Available protection levels:
// - .complete: Encrypted when locked, inaccessible when locked
// - .completeUnlessOpen: Encrypted, accessible if already open
// - .completeUntilFirstUserAuthentication: Encrypted until first unlock
// - .none: Not encrypted
```

## API Key Protection

### Environment Variables

```swift
// Never hardcode API keys
// ❌ Bad
let apiKey = "sk_live_abc123xyz"

// ✅ Good: Use build configuration
enum Config {
    enum Keys {
        static let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
        static let apiSecret = Bundle.main.object(forInfoDictionaryKey: "API_SECRET") as? String ?? ""
    }

    static var apiBaseURL: String {
        #if DEBUG
        return "https://dev-api.example.com"
        #else
        return "https://api.example.com"
        #endif
    }
}

// Info.plist (using xcconfig)
// API_KEY = $(API_KEY)
// API_SECRET = $(API_SECRET)

// .xcconfig files (not committed to git)
// Debug.xcconfig
API_KEY = dev_key_123

// Release.xcconfig
API_KEY = prod_key_456
```

### Obfuscation (Basic)

```swift
// Simple obfuscation (not secure, just obscurity)
final class APIKeyManager {
    private static let obfuscatedKey: [UInt8] = [
        115, 107, 95, 108, 105, 118, 101, 95  // "sk_live_"
    ]

    static func getAPIKey() -> String {
        String(bytes: obfuscatedKey, encoding: .utf8) ?? ""
    }

    // Better: Retrieve from secure backend
    static func fetchSecureAPIKey() async throws -> String {
        // Get from authenticated backend endpoint
        let url = URL(string: "https://api.example.com/secure/keys")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(APIKeyResponse.self, from: data)
        return response.key
    }
}
```

## Input Validation

### Sanitize User Input

```swift
final class InputValidator {
    // Email validation
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // Sanitize HTML
    static func sanitizeHTML(_ input: String) -> String {
        input
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    // Prevent SQL injection (if using raw SQL)
    static func escapeSQLString(_ input: String) -> String {
        input.replacingOccurrences(of: "'", with: "''")
    }

    // Validate URL
    static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }
}
```

## Secure Communication

### HTTPS Enforcement

```swift
// Info.plist - App Transport Security
/*
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <false/>
</dict>
*/

// Force HTTPS
final class SecureNetworkManager {
    static func validateURL(_ url: URL) -> Bool {
        guard url.scheme == "https" else {
            print("Warning: Non-HTTPS URL detected: \(url)")
            return false
        }
        return true
    }
}
```

### Request Signing

```swift
final class RequestSigner {
    static func signRequest(_ request: URLRequest, secret: String) -> URLRequest {
        var signedRequest = request

        // Create signature
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let signature = createHMAC(message: "\(timestamp)\(body)", key: secret)

        // Add headers
        signedRequest.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        signedRequest.setValue(signature, forHTTPHeaderField: "X-Signature")

        return signedRequest
    }

    private static func createHMAC(message: String, key: String) -> String {
        // Implement HMAC-SHA256
        // Use CryptoKit or CommonCrypto
        return ""
    }
}
```

## Jailbreak Detection (Optional)

### Basic Detection

```swift
final class JailbreakDetector {
    static func isJailbroken() -> Bool {
        // Check 1: Cydia app
        if FileManager.default.fileExists(atPath: "/Applications/Cydia.app") {
            return true
        }

        // Check 2: Common jailbreak files
        let jailbreakPaths = [
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check 3: Can write to protected directory
        let testPath = "/private/test_jailbreak.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Expected to fail on non-jailbroken device
        }

        return false
    }

    static func warnIfJailbroken() {
        if isJailbroken() {
            print("⚠️ Device appears to be jailbroken")
            // Optionally: Limit functionality or warn user
        }
    }
}
```

## Secure Coding Practices

### Avoid Force Unwrapping

```swift
// ❌ Bad: Force unwrapping
let user = users.first!  // Crashes if empty

// ✅ Good: Safe unwrapping
guard let user = users.first else {
    return
}
```

### Sensitive Data in Logs

```swift
// ❌ Bad: Logging sensitive data
print("User password: \(password)")
print("Credit card: \(creditCardNumber)")

// ✅ Good: Never log sensitive data
print("User authenticated")
print("Payment processed")

// Redact sensitive data in debug logs
#if DEBUG
print("Token: \(String(repeating: "*", count: token.count))")
#endif
```

### Memory Management

```swift
// ✅ Good: Clear sensitive data from memory
var sensitiveData: Data? = loadSensitiveData()

// Use data...

// Clear when done
if var data = sensitiveData {
    data.resetBytes(in: 0..<data.count)
    sensitiveData = nil
}
```

## Best Practices

### 1. Use Keychain for Credentials

```swift
// ✅ Good: Store in Keychain
try KeychainManager.save(key: "password", data: passwordData)

// ❌ Avoid: UserDefaults for sensitive data
UserDefaults.standard.set(password, forKey: "password")  // Not secure!
```

### 2. Validate Server Certificates

```swift
// ✅ Good: Certificate pinning
let delegate = PinnedURLSessionDelegate(certificateNames: ["cert"])

// ❌ Avoid: Accepting all certificates
// Vulnerable to man-in-the-middle attacks
```

### 3. Use HTTPS Only

```swift
// ✅ Good: Enforce HTTPS
guard url.scheme == "https" else {
    throw NetworkError.insecureConnection
}

// ❌ Avoid: HTTP in production
// Allows eavesdropping
```

### 4. Sanitize User Input

```swift
// ✅ Good: Validate and sanitize
let cleanEmail = InputValidator.sanitizeHTML(email)
guard InputValidator.isValidEmail(cleanEmail) else {
    throw ValidationError.invalidEmail
}

// ❌ Avoid: Using raw input
executeQuery("SELECT * FROM users WHERE email = '\(email)'")  // SQL injection!
```

### 5. Encrypt Sensitive Files

```swift
// ✅ Good: File protection
try data.write(to: url, options: .completeFileProtection)

// ❌ Avoid: Unprotected files
try data.write(to: url)  // No encryption
```

## Security Audit Checklist

```markdown
## Security Checklist

### Data Storage
- [ ] Sensitive data stored in Keychain
- [ ] Files use appropriate protection level
- [ ] No hardcoded credentials
- [ ] UserDefaults only for non-sensitive data

### Network
- [ ] HTTPS enforced (no HTTP fallback)
- [ ] Certificate pinning implemented
- [ ] Request signing for authenticated requests
- [ ] Timeout policies configured

### Authentication
- [ ] Tokens stored in Keychain
- [ ] Token refresh implemented
- [ ] Session timeout enforced
- [ ] Biometric authentication available

### Input Validation
- [ ] All user input validated
- [ ] SQL injection prevention (use parameterized queries)
- [ ] XSS prevention (sanitize HTML)
- [ ] URL validation

### API Keys
- [ ] No API keys in code
- [ ] Build configuration for different environments
- [ ] Obfuscation or backend retrieval

### Code Security
- [ ] No force unwrapping in production code
- [ ] No sensitive data in logs
- [ ] Memory cleared for sensitive data
- [ ] Jailbreak detection (if required)
```

## References

- [Apple Security Documentation](https://developer.apple.com/documentation/security)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [App Transport Security](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security-testing-guide/)
