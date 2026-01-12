---
name: "API Integration"
description: "Comprehensive REST and GraphQL API integration patterns for iOS/tvOS using Alamofire and URLSession"
version: "2.0.0"
---

# API Integration for iOS/tvOS

Complete guide to implementing REST and GraphQL APIs in iOS/tvOS applications using Alamofire, URLSession, and modern Swift concurrency patterns.

## REST API Architecture

### NetworkRouter Pattern

**Centralized endpoint configuration using enum:**

```swift
import Alamofire

enum APIRouter: URLRequestConvertible {
    case login(email: String, password: String)
    case getUser(id: String)
    case updateUser(id: String, data: [String: Any])
    case deleteUser(id: String)
    case uploadAvatar(userId: String, image: Data)

    // MARK: - Base URL

    static let baseURL = "https://api.yourapp.com/v1"

    // MARK: - HTTP Method

    var method: HTTPMethod {
        switch self {
        case .login, .uploadAvatar:
            return .post
        case .getUser:
            return .get
        case .updateUser:
            return .put
        case .deleteUser:
            return .delete
        }
    }

    // MARK: - Path

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .getUser(let id), .updateUser(let id, _), .deleteUser(let id):
            return "/users/\(id)"
        case .uploadAvatar(let userId, _):
            return "/users/\(userId)/avatar"
        }
    }

    // MARK: - Parameters

    var parameters: Parameters? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .updateUser(_, let data):
            return data
        default:
            return nil
        }
    }

    // MARK: - URLRequestConvertible

    func asURLRequest() throws -> URLRequest {
        let url = try Self.baseURL.asURL().appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.timeoutInterval = 30

        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication token if available
        if let token = SessionManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode parameters
        if let parameters = parameters {
            request = try JSONEncoding.default.encode(request, with: parameters)
        }

        return request
    }
}
```

### Service Layer Pattern

```swift
protocol UserServiceProtocol {
    func getUser(id: String) async throws -> User
    func updateUser(id: String, data: UserUpdateRequest) async throws -> User
    func deleteUser(id: String) async throws
}

final class UserService: UserServiceProtocol {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }

    func getUser(id: String) async throws -> User {
        try await networkManager.request(APIRouter.getUser(id: id))
    }

    func updateUser(id: String, data: UserUpdateRequest) async throws -> User {
        let parameters = try data.asDictionary()
        return try await networkManager.request(APIRouter.updateUser(id: id, data: parameters))
    }

    func deleteUser(id: String) async throws {
        try await networkManager.request(APIRouter.deleteUser(id: id))
    }
}
```

## NetworkManager Implementation

### Alamofire-Based NetworkManager

```swift
import Alamofire

protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ router: URLRequestConvertible) async throws -> T
    func upload(data: Data, to router: URLRequestConvertible) async throws -> Data
    func download(_ router: URLRequestConvertible, to destination: URL) async throws
}

final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()

    private let session: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300

        // Custom server trust evaluation
        let serverTrustManager = ServerTrustManager(evaluators: [
            "api.yourapp.com": DefaultTrustEvaluator()
        ])

        session = Session(
            configuration: configuration,
            serverTrustManager: serverTrustManager
        )
    }

    func request<T: Decodable>(_ router: URLRequestConvertible) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            session.request(router)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: self.mapError(error, response: response.response))
                    }
                }
        }
    }

    func upload(data: Data, to router: URLRequestConvertible) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            session.upload(data, with: router)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: self.mapError(error, response: response.response))
                    }
                }
        }
    }

    func download(_ router: URLRequestConvertible, to destination: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            session.download(router)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            try data.write(to: destination)
                            continuation.resume()
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: self.mapError(error, response: response.response))
                    }
                }
        }
    }

    // MARK: - Error Mapping

    private func mapError(_ error: AFError, response: HTTPURLResponse?) -> NetworkError {
        if let statusCode = response?.statusCode {
            switch statusCode {
            case 401:
                return .unauthorized
            case 403:
                return .forbidden
            case 404:
                return .notFound
            case 500...599:
                return .serverError(statusCode)
            default:
                break
            }
        }

        if error.isTimeout {
            return .timeout
        }

        if error.isSessionTaskError {
            return .noConnection
        }

        return .unknown(error)
    }
}
```

### NetworkError Enum

```swift
enum NetworkError: LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case timeout
    case noConnection
    case serverError(Int)
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .timeout:
            return "The request timed out. Please try again."
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingError:
            return "Failed to process server response."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

## Request/Response Patterns

### Codable Models

```swift
// Request model
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// Response model
struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let avatarURL: URL?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}
```

### Custom Date Decoding

```swift
extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()

        // ISO 8601 date decoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        // Convert snake_case to camelCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return decoder
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()

        // ISO 8601 date encoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)

        // Convert camelCase to snake_case
        encoder.keyEncodingStrategy = .convertToSnakeCase

        return encoder
    }
}
```

## Authentication & Token Refresh

### Token Refresh Interceptor

```swift
import Alamofire

final class AuthenticationInterceptor: RequestInterceptor {
    private let sessionManager: SessionManager

    init(sessionManager: SessionManager = .shared) {
        self.sessionManager = sessionManager
    }

    // Add access token to requests
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest

        if let token = sessionManager.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        completion(.success(urlRequest))
    }

    // Retry with refreshed token on 401
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }

        Task {
            do {
                try await sessionManager.refreshToken()
                completion(.retry)
            } catch {
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
```

## Multipart Upload

### Image Upload Pattern

```swift
extension NetworkManager {
    func uploadImage(_ image: UIImage, to router: URLRequestConvertible) async throws -> UploadResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.unknown(NSError(domain: "ImageConversion", code: -1))
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(
                    imageData,
                    withName: "avatar",
                    fileName: "avatar.jpg",
                    mimeType: "image/jpeg"
                )
            }, with: router)
            .validate()
            .responseDecodable(of: UploadResponse.self) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error, response: response.response))
                }
            }
        }
    }
}

struct UploadResponse: Decodable {
    let url: URL
    let size: Int
}
```

## Background URL Sessions

### Download Manager

```swift
final class DownloadManager: NSObject {
    static let shared = DownloadManager()

    private var backgroundSession: URLSession!
    private var ongoingDownloads: [URL: URL] = [:] // Remote URL -> Local URL

    private override init() {
        super.init()

        let config = URLSessionConfiguration.background(withIdentifier: "com.yourapp.background")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true

        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func downloadFile(from url: URL, to destination: URL) {
        let task = backgroundSession.downloadTask(with: url)
        ongoingDownloads[url] = destination
        task.resume()
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let remoteURL = downloadTask.originalRequest?.url,
              let destination = ongoingDownloads[remoteURL] else {
            return
        }

        do {
            try FileManager.default.moveItem(at: location, to: destination)
            ongoingDownloads.removeValue(forKey: remoteURL)

            NotificationCenter.default.post(
                name: .downloadCompleted,
                object: nil,
                userInfo: ["url": destination]
            )
        } catch {
            print("Failed to move downloaded file: \(error)")
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)

        NotificationCenter.default.post(
            name: .downloadProgress,
            object: nil,
            userInfo: ["progress": progress]
        )
    }
}

extension Notification.Name {
    static let downloadCompleted = Notification.Name("downloadCompleted")
    static let downloadProgress = Notification.Name("downloadProgress")
}
```

## GraphQL Integration

### GraphQL Query Builder

```swift
struct GraphQLRequest<T: Decodable>: Encodable {
    let query: String
    let variables: [String: Any]?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(query, forKey: .query)

        if let variables = variables {
            let jsonData = try JSONSerialization.data(withJSONObject: variables)
            let jsonString = String(data: jsonData, encoding: .utf8)
            try container.encode(jsonString, forKey: .variables)
        }
    }

    enum CodingKeys: String, CodingKey {
        case query
        case variables
    }
}

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
    let locations: [Location]?
    let path: [String]?

    struct Location: Decodable {
        let line: Int
        let column: Int
    }
}
```

### GraphQL NetworkManager Extension

```swift
extension NetworkManager {
    func graphQLRequest<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil
    ) async throws -> T {
        let request = GraphQLRequest<T>(query: query, variables: variables)
        let response: GraphQLResponse<T> = try await self.request(APIRouter.graphQL(request))

        if let errors = response.errors, !errors.isEmpty {
            throw NetworkError.unknown(NSError(domain: "GraphQL", code: -1, userInfo: [
                NSLocalizedDescriptionKey: errors.map(\.message).joined(separator: ", ")
            ]))
        }

        guard let data = response.data else {
            throw NetworkError.decodingError(NSError(domain: "GraphQL", code: -1))
        }

        return data
    }
}
```

## API Versioning

### Version-Aware Router

```swift
enum APIVersion: String {
    case v1 = "v1"
    case v2 = "v2"
    case v3 = "v3"
}

enum VersionedAPIRouter: URLRequestConvertible {
    case getUsers(version: APIVersion = .v2)
    case getUser(id: String, version: APIVersion = .v2)

    static let baseURL = "https://api.yourapp.com"

    var version: APIVersion {
        switch self {
        case .getUsers(let version), .getUser(_, let version):
            return version
        }
    }

    var path: String {
        switch self {
        case .getUsers:
            return "/users"
        case .getUser(let id, _):
            return "/users/\(id)"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = try "\(Self.baseURL)/\(version.rawValue)\(path)".asURL()
        var request = URLRequest(url: url)
        request.method = .get
        return request
    }
}
```

## Best Practices

### 1. Protocol-Based Services

```swift
// ✅ Good: Protocol for testability
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> LoginResponse
}

final class AuthService: AuthServiceProtocol {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }
}

// ❌ Avoid: Direct NetworkManager dependency
final class AuthService {
    func login(email: String, password: String) async throws -> LoginResponse {
        try await NetworkManager.shared.request(...)
    }
}
```

### 2. Centralized Error Handling

```swift
// ✅ Good: Consistent error mapping
extension ViewModel {
    func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            errorMessage = networkError.errorDescription
        } else {
            errorMessage = "An unexpected error occurred"
        }
    }
}
```

### 3. Request Timeouts

```swift
// Set appropriate timeouts
configuration.timeoutIntervalForRequest = 30  // API calls
configuration.timeoutIntervalForResource = 300 // Downloads
```

### 4. Retry Logic

```swift
// Use Alamofire's retry interceptor for transient failures
let retryPolicy = RetryPolicy(retryLimit: 3)
session = Session(interceptor: retryPolicy)
```

### 5. Response Validation

```swift
// Always validate status codes
session.request(router)
    .validate(statusCode: 200..<300)
    .validate(contentType: ["application/json"])
```

## Testing API Integration

### Mock NetworkManager

```swift
final class MockNetworkManager: NetworkManagerProtocol {
    var shouldSucceed = true
    var mockResponse: Any?

    func request<T: Decodable>(_ router: URLRequestConvertible) async throws -> T {
        if shouldSucceed, let response = mockResponse as? T {
            return response
        } else {
            throw NetworkError.unknown(NSError(domain: "Mock", code: -1))
        }
    }
}

// Usage in tests
func testGetUser() async throws {
    let mockManager = MockNetworkManager()
    mockManager.shouldSucceed = true
    mockManager.mockResponse = User(id: "123", email: "test@example.com", name: "Test User")

    let service = UserService(networkManager: mockManager)
    let user = try await service.getUser(id: "123")

    XCTAssertEqual(user.id, "123")
}
```

## Troubleshooting

### Invalid SSL Certificate

```swift
// Add server trust evaluation for development
let serverTrustManager = ServerTrustManager(evaluators: [
    "dev.yourapp.com": DisabledTrustEvaluator()
])
```

### Slow Network Requests

```swift
// Enable request logging
let eventMonitor = ClosureEventMonitor()
eventMonitor.requestDidFinish = { request in
    print("Request: \(request.request?.url?.absoluteString ?? "")")
    print("Duration: \(request.duration)")
}

session = Session(eventMonitors: [eventMonitor])
```

### Decoding Failures

```swift
// Log decoding errors
do {
    let user = try JSONDecoder.api.decode(User.self, from: data)
} catch {
    print("Decoding error: \(error)")
    if let decodingError = error as? DecodingError {
        print(decodingError.localizedDescription)
    }
}
```

## References

- [Alamofire Documentation](https://github.com/Alamofire/Alamofire)
- [URLSession Guide](https://developer.apple.com/documentation/foundation/urlsession)
- [Codable in Swift](https://developer.apple.com/documentation/swift/codable)
