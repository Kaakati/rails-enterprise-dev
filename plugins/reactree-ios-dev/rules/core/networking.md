---
paths: "**/Core/Networking/**/*.swift"
---

# Networking Conventions

Use NetworkRouter pattern with Alamofire.

```swift
enum UserAPI {
    case fetchUser(id: String)
}

extension UserAPI: NetworkRouter {
    var path: String { "/users/\(id)" }
    var method: HTTPMethod { .get }
}
```
