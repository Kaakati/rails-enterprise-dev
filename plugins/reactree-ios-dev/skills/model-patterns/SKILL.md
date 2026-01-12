---
name: "Model Patterns"
description: "Comprehensive model design patterns for iOS/tvOS using Codable, custom decoding, DTO mapping, and immutable structs"
version: "2.0.0"
---

# Model Patterns for iOS/tvOS

Complete guide to designing robust data models in Swift using Codable protocol, custom decoding strategies, DTO-to-Domain mapping, and immutable struct patterns.

## Codable Protocol Basics

### Simple Codable Model

```swift
// Struct that conforms to Codable
struct User: Codable {
    let id: String
    let name: String
    let email: String
    let createdAt: Date
}

// Encoding to JSON
let user = User(id: "123", name: "John", email: "john@example.com", createdAt: Date())
let encoder = JSONEncoder()
let jsonData = try encoder.encode(user)

// Decoding from JSON
let decoder = JSONDecoder()
let decodedUser = try decoder.decode(User.self, from: jsonData)
```

### Automatic Synthesis

```swift
// Codable is automatically synthesized when all properties are Codable
struct Product: Codable {
    let id: String
    let name: String
    let price: Double
    let inStock: Bool
}

// Codable = Encodable + Decodable
typealias Codable = Encodable & Decodable
```

## CodingKeys Enum Pattern

### Custom Property Names

```swift
struct User: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let emailAddress: String

    // Map Swift property names to JSON keys
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case emailAddress = "email"
    }
}

// JSON: {"id": "123", "first_name": "John", "last_name": "Doe", "email": "john@example.com"}
// Swift: User(id: "123", firstName: "John", lastName: "John", emailAddress: "john@example.com")
```

### Excluding Properties from Encoding/Decoding

```swift
struct User: Codable {
    let id: String
    let name: String
    let email: String

    // Computed property - not encoded/decoded
    var displayName: String {
        name.isEmpty ? email : name
    }

    // Only include specific properties in CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        // displayName is excluded
    }
}
```

### Nested JSON Structures

```swift
struct UserResponse: Codable {
    let user: User
    let metadata: Metadata

    struct User: Codable {
        let id: String
        let name: String
    }

    struct Metadata: Codable {
        let timestamp: Date
        let version: String
    }
}

// JSON:
// {
//   "user": {"id": "123", "name": "John"},
//   "metadata": {"timestamp": "2024-01-01T00:00:00Z", "version": "1.0"}
// }
```

## Custom init(from decoder:) Patterns

### Custom Decoding Logic

```swift
struct User: Codable {
    let id: String
    let fullName: String
    let email: String
    let age: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case age
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Standard decoding
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)

        // Combine first and last name
        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decode(String.self, forKey: .lastName)
        fullName = "\(firstName) \(lastName)"

        // Optional decoding with default value
        age = try container.decodeIfPresent(Int.self, forKey: .age)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)

        // Split full name back to first and last
        let nameParts = fullName.components(separatedBy: " ")
        try container.encode(nameParts.first ?? "", forKey: .firstName)
        try container.encode(nameParts.dropFirst().joined(separator: " "), forKey: .lastName)

        try container.encodeIfPresent(age, forKey: .age)
    }
}
```

### Handling Missing or Invalid Data

```swift
struct Product: Codable {
    let id: String
    let name: String
    let price: Double
    let status: Status

    enum Status: String, Codable {
        case available
        case outOfStock
        case discontinued
        case unknown
    }

    enum CodingKeys: String, CodingKey {
        case id, name, price, status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        // Handle invalid price as 0
        price = (try? container.decode(Double.self, forKey: .price)) ?? 0.0

        // Handle unknown status gracefully
        let statusString = try container.decode(String.self, forKey: .status)
        status = Status(rawValue: statusString) ?? .unknown
    }
}
```

## Date and URL Decoding Strategies

### Date Decoding Strategies

```swift
// ISO8601 Date Strategy
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

// Custom Date Formatter
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
decoder.dateDecodingStrategy = .formatted(dateFormatter)

// Unix Timestamp (seconds since 1970)
decoder.dateDecodingStrategy = .secondsSince1970

// Unix Timestamp (milliseconds)
decoder.dateDecodingStrategy = .millisecondsSince1970

// Custom Date Decoding
decoder.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    guard let date = formatter.date(from: dateString) else {
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date format: \(dateString)"
        )
    }

    return date
}
```

### URL Decoding

```swift
struct ImageModel: Codable {
    let id: String
    let imageURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case imageURL = "image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)

        // Safely decode URL
        if let urlString = try container.decodeIfPresent(String.self, forKey: .imageURL) {
            imageURL = URL(string: urlString)
        } else {
            imageURL = nil
        }
    }
}
```

## Nested Model Structures

### Complex Nested Models

```swift
struct Order: Codable {
    let id: String
    let customer: Customer
    let items: [OrderItem]
    let payment: Payment
    let shipping: Shipping

    struct Customer: Codable {
        let id: String
        let name: String
        let email: String
        let address: Address

        struct Address: Codable {
            let street: String
            let city: String
            let state: String
            let zipCode: String
            let country: String
        }
    }

    struct OrderItem: Codable {
        let productId: String
        let productName: String
        let quantity: Int
        let unitPrice: Double

        var totalPrice: Double {
            Double(quantity) * unitPrice
        }
    }

    struct Payment: Codable {
        let method: PaymentMethod
        let status: PaymentStatus
        let transactionId: String?

        enum PaymentMethod: String, Codable {
            case creditCard = "credit_card"
            case debitCard = "debit_card"
            case paypal
            case applePay = "apple_pay"
        }

        enum PaymentStatus: String, Codable {
            case pending
            case completed
            case failed
            case refunded
        }
    }

    struct Shipping: Codable {
        let address: Customer.Address
        let method: ShippingMethod
        let trackingNumber: String?

        enum ShippingMethod: String, Codable {
            case standard
            case express
            case overnight
        }
    }
}
```

### Array of Different Types (Type Erasure)

```swift
enum MediaType: String, Codable {
    case image
    case video
    case document
}

protocol Media: Codable {
    var type: MediaType { get }
}

struct ImageMedia: Media {
    let type: MediaType = .image
    let url: URL
    let width: Int
    let height: Int
}

struct VideoMedia: Media {
    let type: MediaType = .video
    let url: URL
    let duration: TimeInterval
    let thumbnail: URL
}

struct Post: Codable {
    let id: String
    let title: String
    let mediaItems: [AnyMedia]

    struct AnyMedia: Codable {
        let media: Media

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(MediaType.self, forKey: .type)

            switch type {
            case .image:
                media = try ImageMedia(from: decoder)
            case .video:
                media = try VideoMedia(from: decoder)
            case .document:
                fatalError("Document type not implemented")
            }
        }

        func encode(to encoder: Encoder) throws {
            try media.encode(to: encoder)
        }

        enum CodingKeys: String, CodingKey {
            case type
        }
    }
}
```

## Model Mapping (DTO → Domain)

### Data Transfer Object (DTO) Pattern

```swift
// DTO: Matches API response exactly
struct UserDTO: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let profileImageURL: String?
    let createdAt: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
        case isActive = "is_active"
    }
}

// Domain Model: Application's internal representation
struct User {
    let id: String
    let fullName: String
    let email: String
    let profileImageURL: URL?
    let createdAt: Date
    let isActive: Bool

    // Computed properties
    var displayName: String {
        fullName.isEmpty ? email : fullName
    }

    var initials: String {
        let names = fullName.components(separatedBy: " ")
        let firstInitial = names.first?.prefix(1) ?? ""
        let lastInitial = names.last?.prefix(1) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
}

// Mapper: DTO → Domain
extension User {
    init(from dto: UserDTO) {
        self.id = dto.id
        self.fullName = "\(dto.firstName) \(dto.lastName)"
        self.email = dto.email
        self.profileImageURL = dto.profileImageURL.flatMap { URL(string: $0) }
        self.isActive = dto.isActive

        // Parse date
        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.date(from: dto.createdAt) ?? Date()
    }
}

// Usage
let userDTO = try decoder.decode(UserDTO.self, from: jsonData)
let user = User(from: userDTO)
```

### Mapper Protocol

```swift
protocol DTOConvertible {
    associatedtype DTO: Codable

    init(from dto: DTO)
    func toDTO() -> DTO
}

// Example implementation
struct Product: DTOConvertible {
    let id: String
    let name: String
    let price: Double

    struct DTO: Codable {
        let id: String
        let name: String
        let priceInCents: Int
    }

    init(from dto: DTO) {
        self.id = dto.id
        self.name = dto.name
        self.price = Double(dto.priceInCents) / 100.0
    }

    func toDTO() -> DTO {
        DTO(
            id: id,
            name: name,
            priceInCents: Int(price * 100)
        )
    }
}
```

## Computed Properties

### Derived Values

```swift
struct Rectangle: Codable {
    let width: Double
    let height: Double

    // Computed properties
    var area: Double {
        width * height
    }

    var perimeter: Double {
        2 * (width + height)
    }

    var aspectRatio: Double {
        width / height
    }

    var isSquare: Bool {
        width == height
    }
}
```

### Lazy Properties

```swift
struct Article: Codable {
    let id: String
    let title: String
    let body: String
    let tags: [String]

    // Lazy computed property
    lazy var wordCount: Int = {
        body.components(separatedBy: .whitespacesAndNewlines).count
    }()

    lazy var readingTimeMinutes: Int = {
        // Average reading speed: 200 words per minute
        max(1, wordCount / 200)
    }()
}
```

## Immutable Struct Patterns

### Value Semantics

```swift
// Immutable struct with `let` properties
struct User {
    let id: String
    let name: String
    let email: String

    // Create new instance with modified property
    func withName(_ newName: String) -> User {
        User(id: id, name: newName, email: email)
    }

    func withEmail(_ newEmail: String) -> User {
        User(id: id, name: name, email: newEmail)
    }
}

// Usage
let user = User(id: "123", name: "John", email: "john@example.com")
let updatedUser = user.withName("John Doe")  // Creates new instance
```

### Builder Pattern for Complex Models

```swift
struct User {
    let id: String
    let name: String
    let email: String
    let phoneNumber: String?
    let address: Address?
    let preferences: Preferences

    struct Address {
        let street: String
        let city: String
        let zipCode: String
    }

    struct Preferences {
        let notifications: Bool
        let theme: String
    }

    // Builder for complex initialization
    struct Builder {
        var id: String = UUID().uuidString
        var name: String = ""
        var email: String = ""
        var phoneNumber: String?
        var address: Address?
        var preferences: Preferences = Preferences(notifications: true, theme: "light")

        func build() -> User {
            User(
                id: id,
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                address: address,
                preferences: preferences
            )
        }
    }
}

// Usage
let user = User.Builder()
    .with(\.name, "John Doe")
    .with(\.email, "john@example.com")
    .build()
```

## Model Validation

### Validation at Initialization

```swift
struct Email {
    let value: String

    init?(_ value: String) {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard emailPredicate.evaluate(with: value) else {
            return nil
        }

        self.value = value
    }
}

struct User {
    let id: String
    let name: String
    let email: Email

    init?(id: String, name: String, email: String) {
        guard !id.isEmpty, !name.isEmpty else {
            return nil
        }

        guard let validEmail = Email(email) else {
            return nil
        }

        self.id = id
        self.name = name
        self.email = validEmail
    }
}
```

### Throwing Initializer

```swift
enum ValidationError: Error, LocalizedError {
    case emptyField(String)
    case invalidFormat(String)
    case outOfRange(String, min: Int, max: Int)

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidFormat(let field):
            return "\(field) has invalid format"
        case .outOfRange(let field, let min, let max):
            return "\(field) must be between \(min) and \(max)"
        }
    }
}

struct User {
    let id: String
    let name: String
    let email: String
    let age: Int

    init(id: String, name: String, email: String, age: Int) throws {
        guard !id.isEmpty else {
            throw ValidationError.emptyField("id")
        }

        guard !name.isEmpty else {
            throw ValidationError.emptyField("name")
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            throw ValidationError.invalidFormat("email")
        }

        guard age >= 0 && age <= 150 else {
            throw ValidationError.outOfRange("age", min: 0, max: 150)
        }

        self.id = id
        self.name = name
        self.email = email
        self.age = age
    }
}
```

## Best Practices

### 1. Use Structs for Models

```swift
// ✅ Good: Immutable struct
struct User: Codable {
    let id: String
    let name: String
}

// ❌ Avoid: Classes for simple data models
class User: Codable {
    var id: String
    var name: String
}
```

### 2. Separate DTO from Domain Models

```swift
// ✅ Good: Separate DTO and domain models
struct UserDTO: Codable { /* API contract */ }
struct User { /* Domain model */ }

// ❌ Avoid: Using API response directly
// Makes code fragile to API changes
```

### 3. Use CodingKeys for Clarity

```swift
// ✅ Good: Explicit CodingKeys
enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case userName = "user_name"
}

// ❌ Avoid: Snake_case in Swift
// Violates Swift naming conventions
```

### 4. Handle Optional Values Gracefully

```swift
// ✅ Good: Provide sensible defaults
let name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"

// ❌ Avoid: Force unwrapping
let name = try container.decode(String.self, forKey: .name)  // Crashes if missing
```

## Testing Model Decoding

### Unit Tests

```swift
final class UserModelTests: XCTestCase {
    func testUserDecoding() throws {
        // Given
        let json = """
        {
            "id": "123",
            "first_name": "John",
            "last_name": "Doe",
            "email": "john@example.com"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let user = try decoder.decode(UserDTO.self, from: data)

        // Then
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.firstName, "John")
        XCTAssertEqual(user.lastName, "Doe")
        XCTAssertEqual(user.email, "john@example.com")
    }

    func testInvalidEmailThrowsError() {
        // Given/When/Then
        XCTAssertThrowsError(
            try User(id: "123", name: "John", email: "invalid-email", age: 30)
        ) { error in
            XCTAssertEqual(error as? ValidationError, .invalidFormat("email"))
        }
    }
}
```

## References

- [Codable Documentation](https://developer.apple.com/documentation/swift/codable)
- [JSONEncoder/JSONDecoder](https://developer.apple.com/documentation/foundation/jsonencoder)
- [CodingKeys Protocol](https://developer.apple.com/documentation/swift/codingkey)
- [Advanced Encoding and Decoding](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)
