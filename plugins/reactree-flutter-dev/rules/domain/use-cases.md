---
paths: lib/domain/usecases/**/*.dart
---

# Use Case Rules

## Single Responsibility

**Rule**: Each use case does ONE thing.

```dart
// ✅ CORRECT: Single responsibility
class GetUser {
  final UserRepository repository;
  
  GetUser(this.repository);
  
  Future<Either<Failure, User>> call(String id) {
    return repository.getUser(id);
  }
}

// ❌ WRONG: Multiple responsibilities
class UserOperations {
  Future<User> getUser(String id) { }
  Future<void> deleteUser(String id) { }
  Future<User> updateUser(User user) { }
}
```

## Repository Dependency

**Rule**: Use cases depend on repository interfaces, not implementations.

```dart
// ✅ CORRECT: Depends on interface
class GetUser {
  final UserRepository repository;  // Abstract interface
  
  GetUser(this.repository);
}

// ❌ WRONG: Depends on implementation
class GetUser {
  final UserRepositoryImpl repository;  // Concrete class
  
  GetUser(this.repository);
}
```

## Return Either Type

**Rule**: Use cases return `Either<Failure, T>` for error handling.

```dart
// ✅ CORRECT: Either type
Future<Either<Failure, User>> call(String id) {
  return repository.getUser(id);
}

// ❌ WRONG: Throws exceptions
Future<User> call(String id) async {
  try {
    return await repository.getUser(id);
  } catch (e) {
    throw Exception(e);
  }
}
```

## Callable Pattern

**Rule**: Use `call` method for single-purpose use cases.

```dart
// ✅ CORRECT: Callable
class GetUser {
  Future<Either<Failure, User>> call(String id) {
    return repository.getUser(id);
  }
}

// Usage
final result = await getUser('123');

// ❌ WRONG: Named method
class GetUser {
  Future<Either<Failure, User>> execute(String id) {
    return repository.getUser(id);
  }
}
```
