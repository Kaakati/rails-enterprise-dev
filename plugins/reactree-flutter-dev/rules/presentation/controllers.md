---
paths: lib/presentation/controllers/**/*.dart
---

# GetX Controller Rules

## Extend GetxController

**Rule**: All controllers must extend GetxController.

```dart
// ✅ CORRECT
class UserController extends GetxController {
  // ...
}

// ❌ WRONG
class UserController {
  // Not extending GetxController
}
```

## Reactive State with .obs

**Rule**: Use `.obs` for reactive variables.

```dart
// ✅ CORRECT
class UserController extends GetxController {
  final _user = Rx<User?>(null);
  User? get user => _user.value;
  
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
}

// ❌ WRONG: Non-reactive
class UserController extends GetxController {
  User? user;  // Not reactive
  bool isLoading = false;
}
```

## Call Use Cases, Not Repositories

**Rule**: Controllers call use cases for business logic.

```dart
// ✅ CORRECT
class UserController extends GetxController {
  final GetUser getUserUseCase;
  
  Future<void> loadUser(String id) async {
    final result = await getUserUseCase(id);
    // Handle result
  }
}

// ❌ WRONG: Direct repository access
class UserController extends GetxController {
  final UserRepository repository;
  
  Future<void> loadUser(String id) async {
    final result = await repository.getUser(id);  // Skip use case
  }
}
```

## Clean Up Resources

**Rule**: Override `onClose()` to clean up.

```dart
// ✅ CORRECT
class UserController extends GetxController {
  late StreamSubscription _subscription;
  
  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
```
