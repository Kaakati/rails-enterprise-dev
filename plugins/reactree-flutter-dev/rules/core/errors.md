---
name: Core Error Handling Rules
paths:
  - lib/core/errors/**/*.dart
description: Enforcement rules for error handling in the core layer including Failure and Exception classes
---

# Core Error Handling Rules

Rules for implementing error handling in `lib/core/errors/` following Clean Architecture principles.

## File Organization

```
lib/core/errors/
├── failures.dart         # Domain layer Failures (returned via Either)
└── exceptions.dart       # Data layer Exceptions (thrown and caught)
```

## Failure Classes (lib/core/errors/failures.dart)

### Rule 1: All Failures Must Extend Base Failure Class

**✅ CORRECT**:
```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}
```

**❌ INCORRECT**:
```dart
// Standalone failure class without extending Failure
class ServerError {
  final String message;
  const ServerError(this.message);
}
```

### Rule 2: Failures Must Be Immutable (const constructors)

**✅ CORRECT**:
```dart
class ValidationFailure extends Failure {
  final Map<String, String> errors;
  const ValidationFailure(this.errors, [String message = 'Validation error'])
      : super(message);
}
```

**❌ INCORRECT**:
```dart
class ValidationFailure extends Failure {
  Map<String, String> errors; // Mutable field
  ValidationFailure(this.errors) : super('Validation error');
}
```

### Rule 3: Provide Default Error Messages

**✅ CORRECT**:
```dart
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found']) : super(message);
}

// Usage
return Left(NotFoundFailure()); // Uses default message
return Left(NotFoundFailure('User not found')); // Custom message
```

**❌ INCORRECT**:
```dart
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message); // No default
}

// Always requires message
return Left(NotFoundFailure('Resource not found'));
```

### Rule 4: Override toString() and Equality

**✅ CORRECT**:
```dart
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
```

### Rule 5: Use Sealed Classes for Exhaustive Matching (Dart 3.x)

**✅ CORRECT** (Dart 3.0+):
```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error']) : super(message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error']) : super(message);
}

// Exhaustive matching
String handleFailure(Failure failure) {
  return switch (failure) {
    ServerFailure() => 'Server is down',
    NetworkFailure() => 'Check your connection',
    // Compiler ensures all cases covered
  };
}
```

## Exception Classes (lib/core/errors/exceptions.dart)

### Rule 6: All Exceptions Must Implement Exception

**✅ CORRECT**:
```dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}
```

**❌ INCORRECT**:
```dart
// Does not implement Exception
class ServerException {
  final String message;
  const ServerException(this.message);
}
```

### Rule 7: Exceptions Should Include Contextual Information

**✅ CORRECT**:
```dart
class ParseException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const ParseException(
    this.message,
    this.originalError,
    [this.stackTrace],
  );

  @override
  String toString() => 'ParseException: $message\nOriginal: $originalError';
}
```

**❌ INCORRECT**:
```dart
class ParseException implements Exception {
  final String message;
  const ParseException(this.message); // Missing context
}
```

### Rule 8: Override toString() for Better Debugging

**✅ CORRECT**:
```dart
class CacheException implements Exception {
  final String message;
  final String? key;

  const CacheException(this.message, [this.key]);

  @override
  String toString() {
    if (key != null) {
      return 'CacheException: $message (key: $key)';
    }
    return 'CacheException: $message';
  }
}
```

**❌ INCORRECT**:
```dart
class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
  // Missing toString() override
}
```

## Usage Patterns

### Rule 9: Failures in Domain Layer, Exceptions in Data Layer

**Domain Layer (Use Cases)** - Return Failures:
```dart
// ✅ CORRECT
class LoginUser {
  Future<Either<Failure, User>> call(String email, String password) async {
    return await repository.login(email, password);
  }
}

// ❌ INCORRECT - Never throw exceptions from use cases
class LoginUser {
  Future<User> call(String email, String password) async {
    return await repository.login(email, password); // Throws exception
  }
}
```

**Data Layer (Repositories)** - Catch Exceptions, Return Failures:
```dart
// ✅ CORRECT
class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}

// ❌ INCORRECT - Don't let exceptions escape
class UserRepositoryImpl implements UserRepository {
  @override
  Future<User> login(String email, String password) async {
    final userModel = await remoteDataSource.login(email, password);
    return userModel.toEntity(); // Throws exception if error
  }
}
```

**Data Layer (Data Sources)** - Throw Exceptions:
```dart
// ✅ CORRECT
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  @override
  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Invalid credentials');
    } else {
      throw ServerException('Server error', response.statusCode);
    }
  }
}
```

### Rule 10: Stack Trace Preservation

**✅ CORRECT**:
```dart
try {
  final result = await someOperation();
} on ServerException catch (e, stackTrace) {
  // Preserve stack trace for debugging
  debugPrint('Error: $e\nStack: $stackTrace');
  return Left(ServerFailure(e.message));
}
```

**❌ INCORRECT**:
```dart
try {
  final result = await someOperation();
} on ServerException catch (e) {
  // Stack trace lost
  return Left(ServerFailure(e.message));
}
```

## Common Failure Types

Required failure types for most applications:

1. **ServerFailure** - API server errors (500, 502, etc.)
2. **NetworkFailure** - Network connectivity issues
3. **CacheFailure** - Local storage errors
4. **ValidationFailure** - Input validation errors
5. **UnauthorizedFailure** - Authentication errors (401)
6. **ForbiddenFailure** - Authorization errors (403)
7. **NotFoundFailure** - Resource not found (404)
8. **ParseFailure** - JSON parsing errors
9. **TimeoutFailure** - Request timeout errors

## Common Exception Types

Required exception types for most applications:

1. **ServerException** - HTTP server errors
2. **NetworkException** - Network failures
3. **CacheException** - Local storage failures
4. **ParseException** - JSON parsing failures
5. **UnauthorizedException** - Auth token invalid/expired
6. **TimeoutException** - Request timeout

## Validation Checklist

- [ ] All Failure classes extend base `Failure`
- [ ] All Exception classes implement `Exception`
- [ ] Failures are immutable (const constructors)
- [ ] Default error messages provided
- [ ] toString() overridden for debugging
- [ ] Equality operators implemented for Failures
- [ ] Use cases return `Either<Failure, T>`, never throw
- [ ] Repositories catch exceptions and return Failures
- [ ] Data sources throw exceptions
- [ ] Stack traces preserved when catching exceptions
- [ ] Contextual information included in exceptions
- [ ] Sealed classes used for exhaustive matching (Dart 3.x)

## Anti-Patterns to Avoid

### ❌ Mixing Failures and Exceptions
```dart
// WRONG - Repository returning Either AND throwing
Future<Either<Failure, User>> getUser(String id) async {
  if (id.isEmpty) throw ArgumentError('ID required'); // Don't throw
  return await dataSource.getUser(id);
}
```

### ❌ Generic Error Handling
```dart
// WRONG - Too generic, loses error context
} catch (e) {
  return Left(Failure('Error occurred')); // Use specific failure type
}
```

### ❌ Swallowing Exceptions
```dart
// WRONG - Silent failure
try {
  await operation();
} catch (e) {
  // No handling, no logging, error lost
}
```

### ❌ Exception for Flow Control
```dart
// WRONG - Don't use exceptions for normal flow
if (user == null) {
  throw NotFoundException('User not found'); // Use Failure instead
}
```
