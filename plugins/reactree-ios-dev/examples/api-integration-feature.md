# API Integration Example

REST API integration with Alamofire, NetworkRouter, and MVVM pattern.

## Implementation

### NetworkRouter
```swift
enum UserAPI {
    case fetchUsers
    case fetchUser(id: String)
    case createUser(request: CreateUserRequest)
}

extension UserAPI: NetworkRouter {
    var path: String {
        switch self {
        case .fetchUsers: return "/users"
        case .fetchUser(let id): return "/users/\(id)"
        case .createUser: return "/users"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchUsers, .fetchUser: return .get
        case .createUser: return .post
        }
    }
}
```

### Service
```swift
protocol UserServiceProtocol {
    func fetchUsers() async -> Result<[User], NetworkError>
}

final class UserService: UserServiceProtocol {
    private let networkClient: NetworkClientProtocol

    func fetchUsers() async -> Result<[User], NetworkError> {
        return await networkClient.request(UserAPI.fetchUsers)
    }
}
```

### ViewModel
```swift
@MainActor
final class UsersViewModel: BaseViewModel {
    @Published var users: [User] = []
    private let service: UserServiceProtocol

    func loadUsers() async {
        await executeTask {
            let result = await service.fetchUsers()
            if case .success(let users) = result {
                self.users = users
            }
        }
    }
}
```
