---
paths: lib/presentation/bindings/**/*.dart
---

# Binding Rules

## Implement Bindings Interface

**Rule**: All bindings must implement `Bindings`.

```dart
// ✅ CORRECT
class UserBinding extends Bindings {
  @override
  void dependencies() {
    // Inject dependencies
  }
}
```

## Use Lazy Injection

**Rule**: Prefer `Get.lazyPut()` for lazy initialization.

```dart
// ✅ CORRECT: Lazy loading
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UserController(getUserUseCase: Get.find()));
  }
}

// ❌ WRONG: Immediate loading (only if needed)
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(UserController(getUserUseCase: Get.find()));
  }
}
```

## Layer Order

**Rule**: Inject dependencies in order: Data Sources → Repositories → Use Cases → Controllers.

```dart
class UserBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Data sources
    Get.lazyPut(() => UserProvider(Get.find()));
    Get.lazyPut(() => UserLocalSource(Get.find()));
    
    // 2. Repository
    Get.lazyPut<UserRepository>(
      () => UserRepositoryImpl(Get.find(), Get.find()),
    );
    
    // 3. Use cases
    Get.lazyPut(() => GetUser(Get.find()));
    
    // 4. Controller
    Get.lazyPut(() => UserController(getUserUseCase: Get.find()));
  }
}
```
