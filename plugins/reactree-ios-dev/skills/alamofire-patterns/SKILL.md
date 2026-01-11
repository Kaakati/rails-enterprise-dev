---
name: "Alamofire Patterns"
description: "NetworkRouter protocol, NetworkClient implementation, and request/response handling with Alamofire"
version: "1.0.0"
---

# Alamofire Networking Patterns

## NetworkRouter Protocol

```swift
protocol NetworkRouter {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var headers: HTTPHeaders? { get }
    var encoding: ParameterEncoding { get }
}

enum UserAPI {
    case fetchUser(id: String)
    case updateProfile(request: UpdateProfileRequest)
}

extension UserAPI: NetworkRouter {
    var baseURL: URL { URL(string: "https://api.example.com")! }

    var path: String {
        switch self {
        case .fetchUser(let id): return "/users/\(id)"
        case .updateProfile: return "/profile"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchUser: return .get
        case .updateProfile: return .put
        }
    }
}
```

## NetworkClient

```swift
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ router: NetworkRouter) async -> Result<T, NetworkError>
}

final class NetworkClient: NetworkClientProtocol {
    private let session: Session

    func request<T: Decodable>(_ router: NetworkRouter) async -> Result<T, NetworkError> {
        do {
            let urlRequest = try router.asURLRequest()
            let response = await session.request(urlRequest)
                .serializingDecodable(T.self)
                .response
            return .success(response.value!)
        } catch {
            return .failure(.networkError(error))
        }
    }
}
```

## Authentication Interceptor

```swift
final class AuthenticationInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var modifiedRequest = urlRequest
        if let token = SessionManager.shared.accessToken {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        completion(.success(modifiedRequest))
    }
}
```
