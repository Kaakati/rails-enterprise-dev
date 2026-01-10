---
paths: lib/data/repositories/**/*.dart
---

# Repository Implementation Rules

## Implement Domain Interface

**Rule**: Repository implementations must implement domain interfaces.

```dart
// ✅ CORRECT
class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<Failure, User>> getUser(String id) {
    // Implementation
  }
}

// ❌ WRONG: No interface
class UserRepository {
  Future<User> getUser(String id) {
    // Direct implementation
  }
}
```

## Convert Exceptions to Failures

**Rule**: Catch exceptions and convert to failures.

```dart
// ✅ CORRECT
Future<Either<Failure, User>> getUser(String id) async {
  try {
    final model = await provider.fetchUser(id);
    return Right(model.toEntity());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException {
    return Left(NetworkFailure());
  }
}

// ❌ WRONG: Let exceptions propagate
Future<User> getUser(String id) async {
  final model = await provider.fetchUser(id);
  return model.toEntity();  // Exceptions not handled
}
```

## Coordinate Data Sources

**Rule**: Repositories coordinate between remote and local sources.

```dart
// ✅ CORRECT: Offline-first pattern
Future<Either<Failure, User>> getUser(String id) async {
  if (await networkInfo.isConnected) {
    try {
      final remote = await remoteSource.fetchUser(id);
      await localSource.cacheUser(remote);
      return Right(remote.toEntity());
    } catch (e) {
      return _getCachedUser(id);  // Fallback
    }
  } else {
    return _getCachedUser(id);
  }
}
```
