---
name: flutter-refactor
description: Refactoring workflow for Flutter applications with safety guarantees and test-driven improvements
allowed-tools: ["*"]
---

# Flutter Refactor Command

Systematic refactoring workflow for improving Flutter application code structure while maintaining functionality and ensuring safety through comprehensive testing.

## Usage

```
/flutter-refactor [refactoring description]
```

## Examples

```
/flutter-refactor extract common form validation logic into reusable service
/flutter-refactor split large UserController into separate profile and settings controllers
/flutter-refactor move API endpoints to centralized configuration
/flutter-refactor convert stateful widgets to GetX controllers
/flutter-refactor extract repeated UI patterns into reusable components
/flutter-refactor improve error handling across all repositories
```

## What This Command Does

This command performs safe, test-driven refactoring:

### 1. Refactoring Analysis
- Understand current code structure
- Identify refactoring goals
- Assess impact and risks
- Plan incremental changes

### 2. Test Coverage Baseline
- Run existing tests (baseline)
- Identify missing test coverage
- Add missing tests BEFORE refactoring
- Ensure ≥ 80% coverage of refactoring targets

### 3. Incremental Refactoring
- Make small, safe changes
- Run tests after each change
- Verify functionality preserved
- Commit after each successful step

### 4. Quality Validation
- Run full test suite
- Verify dart analysis passes
- Check performance impact
- Validate Clean Architecture boundaries

### 5. Documentation
- Update code documentation
- Record refactoring decisions
- Note any breaking changes
- Update architecture docs

## Common Refactoring Patterns

### Extract Service Object

**Before**:
```dart
class UserController extends GetxController {
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);

  Future<void> validateAndSaveProfile(String name, String email) async {
    // Complex validation logic
    if (name.isEmpty || name.length < 2) {
      _error.value = 'Name must be at least 2 characters';
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _error.value = 'Invalid email format';
      return;
    }

    // Additional validation...
    _isLoading.value = true;
    // Save logic...
  }
}
```

**After**:
```dart
// New service
class ValidationService {
  Either<String, String> validateName(String name) {
    if (name.isEmpty || name.length < 2) {
      return Left('Name must be at least 2 characters');
    }
    return Right(name);
  }

  Either<String, String> validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return Left('Invalid email format');
    }
    return Right(email);
  }
}

// Simplified controller
class UserController extends GetxController {
  final ValidationService _validationService;
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);

  UserController(this._validationService);

  Future<void> validateAndSaveProfile(String name, String email) async {
    final nameValidation = _validationService.validateName(name);
    if (nameValidation.isLeft()) {
      _error.value = nameValidation.fold((l) => l, (r) => null);
      return;
    }

    final emailValidation = _validationService.validateEmail(email);
    if (emailValidation.isLeft()) {
      _error.value = emailValidation.fold((l) => l, (r) => null);
      return;
    }

    _isLoading.value = true;
    // Save logic...
  }
}
```

**Tests Added**:
```dart
// test/services/validation_service_test.dart
void main() {
  late ValidationService validationService;

  setUp(() {
    validationService = ValidationService();
  });

  group('validateName', () {
    test('returns error for empty name', () {
      final result = validationService.validateName('');
      expect(result.isLeft(), true);
    });

    test('returns error for name less than 2 characters', () {
      final result = validationService.validateName('A');
      expect(result.isLeft(), true);
    });

    test('returns success for valid name', () {
      final result = validationService.validateName('John');
      expect(result.isRight(), true);
    });
  });

  group('validateEmail', () {
    test('returns error for invalid email', () {
      final result = validationService.validateEmail('invalid');
      expect(result.isLeft(), true);
    });

    test('returns success for valid email', () {
      final result = validationService.validateEmail('test@example.com');
      expect(result.isRight(), true);
    });
  });
}
```

### Split Large Controller

**Before**:
```dart
class UserController extends GetxController {
  // Profile management
  final _user = Rx<User?>(null);
  final _isLoadingProfile = false.obs;

  Future<void> loadProfile() async { /* ... */ }
  Future<void> updateProfile(User user) async { /* ... */ }
  Future<void> uploadAvatar(File file) async { /* ... */ }

  // Settings management
  final _settings = Rx<Settings?>(null);
  final _isLoadingSettings = false.obs;

  Future<void> loadSettings() async { /* ... */ }
  Future<void> updateSettings(Settings settings) async { /* ... */ }

  // Notification preferences
  final _notificationEnabled = true.obs;
  final _emailEnabled = true.obs;

  void toggleNotifications() { /* ... */ }
  void toggleEmail() { /* ... */ }

  // Account management
  Future<void> deleteAccount() async { /* ... */ }
  Future<void> exportData() async { /* ... */ }
}
```

**After**:
```dart
// Separate controllers by responsibility
class ProfileController extends GetxController {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;

  final _user = Rx<User?>(null);
  final _isLoading = false.obs;

  User? get user => _user.value;
  bool get isLoading => _isLoading.value;

  ProfileController(
    this._getUserProfileUseCase,
    this._updateProfileUseCase,
    this._uploadAvatarUseCase,
  );

  Future<void> loadProfile() async {
    _isLoading.value = true;
    final result = await _getUserProfileUseCase();
    result.fold(
      (failure) => _handleError(failure),
      (user) => _user.value = user,
    );
    _isLoading.value = false;
  }

  Future<void> updateProfile(User user) async { /* ... */ }
  Future<void> uploadAvatar(File file) async { /* ... */ }
}

class SettingsController extends GetxController {
  final GetSettingsUseCase _getSettingsUseCase;
  final UpdateSettingsUseCase _updateSettingsUseCase;

  final _settings = Rx<Settings?>(null);
  final _isLoading = false.obs;

  Settings? get settings => _settings.value;
  bool get isLoading => _isLoading.value;

  SettingsController(
    this._getSettingsUseCase,
    this._updateSettingsUseCase,
  );

  Future<void> loadSettings() async { /* ... */ }
  Future<void> updateSettings(Settings settings) async { /* ... */ }
}

class NotificationController extends GetxController {
  final _notificationEnabled = true.obs;
  final _emailEnabled = true.obs;

  bool get notificationEnabled => _notificationEnabled.value;
  bool get emailEnabled => _emailEnabled.value;

  void toggleNotifications() {
    _notificationEnabled.value = !_notificationEnabled.value;
    _savePreferences();
  }

  void toggleEmail() {
    _emailEnabled.value = !_emailEnabled.value;
    _savePreferences();
  }

  Future<void> _savePreferences() async { /* ... */ }
}
```

**Bindings Updated**:
```dart
// Before
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UserController(/* many dependencies */));
  }
}

// After
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileController(
      Get.find(),
      Get.find(),
      Get.find(),
    ));
  }
}

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController(
      Get.find(),
      Get.find(),
    ));
  }
}
```

### Extract Reusable Widget

**Before**:
```dart
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(products[index].imageUrl),
            ),
            title: Text(
              products[index].name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('\$${products[index].price.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () => addToCart(products[index]),
            ),
          ),
        );
      },
    );
  }
}
```

**After**:
```dart
// Extracted reusable widget
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(product.imageUrl),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: onAddToCart,
        ),
      ),
    );
  }
}

// Simplified usage
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onAddToCart: () => addToCart(products[index]),
        );
      },
    );
  }
}
```

**Widget Test Added**:
```dart
// test/presentation/widgets/product_card_test.dart
void main() {
  testWidgets('ProductCard displays product information', (tester) async {
    final product = Product(
      id: '1',
      name: 'Test Product',
      price: 29.99,
      imageUrl: 'https://example.com/image.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(
            product: product,
            onAddToCart: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('\$29.99'), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
  });

  testWidgets('ProductCard calls onAddToCart when button tapped', (tester) async {
    var called = false;
    final product = Product(id: '1', name: 'Test', price: 10.0, imageUrl: '');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(
            product: product,
            onAddToCart: () => called = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    expect(called, true);
  });
}
```

### Improve Error Handling

**Before**:
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final userModel = await remoteDataSource.getUser(id);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ServerFailure()); // Generic error
    }
  }
}
```

**After**:
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    // Check network connectivity
    if (!await networkInfo.isConnected) {
      logger.warning('No network connection');
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final userModel = await remoteDataSource.getUser(id);
      logger.info('Successfully fetched user: $id');
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      logger.error('Server error fetching user', e);
      return Left(ServerFailure(
        message: e.message ?? 'Server error occurred',
        statusCode: e.statusCode,
      ));
    } on TimeoutException catch (e) {
      logger.error('Request timeout for user', e);
      return Left(NetworkFailure(message: 'Request timed out'));
    } on FormatException catch (e) {
      logger.error('Invalid response format', e);
      return Left(ServerFailure(message: 'Invalid server response'));
    } catch (e, stackTrace) {
      logger.error('Unexpected error fetching user', e, stackTrace);
      return Left(UnexpectedFailure(
        message: 'An unexpected error occurred',
        exception: e,
      ));
    }
  }
}
```

### Centralize Configuration

**Before**:
```dart
// Scattered throughout codebase
class UserProvider {
  final baseUrl = 'https://api.example.com';
  // ...
}

class ProductProvider {
  final baseUrl = 'https://api.example.com';
  // ...
}
```

**After**:
```dart
// Centralized configuration
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const Duration apiTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  static const String storageKey = 'app_storage';
  static const Duration cacheExpiry = Duration(hours: 1);
}

// Usage
class UserProvider {
  final http.Client client;
  final String baseUrl;

  UserProvider({
    required this.client,
    this.baseUrl = AppConfig.apiBaseUrl,
  });

  Future<UserModel> getUser(String id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/users/$id'),
    ).timeout(AppConfig.apiTimeout);
    // ...
  }
}
```

## Refactoring Workflow Phases

### Phase 1: Analysis (10-15 minutes)
- Understand current implementation
- Identify refactoring opportunities
- Assess risks and impact
- Plan incremental steps

### Phase 2: Test Coverage (15-20 minutes)
- Run existing tests (baseline)
- Identify gaps in test coverage
- Write missing tests FIRST
- Ensure ≥ 80% coverage of target code

### Phase 3: Incremental Changes (30-60 minutes)
- Make one small change at a time
- Run tests after each change
- Verify functionality preserved
- Commit successful changes
- Rollback if tests fail

### Phase 4: Quality Validation (10 minutes)
- Run full test suite
- Check dart analysis
- Verify performance unchanged
- Validate architecture boundaries

### Phase 5: Documentation (10 minutes)
- Update code comments
- Document design decisions
- Update architecture docs
- Note breaking changes (if any)

## Refactoring Safety Checklist

Before refactoring:
- [ ] Existing tests pass (baseline)
- [ ] Test coverage ≥ 80% of target code
- [ ] Clear refactoring goal defined
- [ ] Impact assessment completed

During refactoring:
- [ ] Make incremental changes
- [ ] Run tests after each change
- [ ] Commit after successful steps
- [ ] Keep git history clean

After refactoring:
- [ ] All tests still pass
- [ ] No new dart analysis errors
- [ ] Performance not degraded
- [ ] Documentation updated
- [ ] Code review completed

## Activation

When the user invokes `/flutter-refactor [description]`:

1. Parse refactoring description
2. Spawn **workflow-orchestrator** in refactor mode
3. Analyze current code structure
4. Establish test coverage baseline
5. Plan incremental refactoring steps
6. Execute refactoring with continuous testing
7. Validate with quality gates
8. Update documentation

## Integration with Other Commands

- Use `/flutter-dev` to add new features after refactoring
- Use `/flutter-debug` if refactoring introduces issues
- Use `/flutter-feature` to rebuild features with better architecture

## Best Practices

1. **Test First**: Ensure comprehensive tests before refactoring
2. **Small Steps**: Make incremental changes, test frequently
3. **Keep It Working**: Code should always be in working state
4. **One Thing at a Time**: Don't mix refactoring with feature additions
5. **Measure Impact**: Verify performance not degraded
6. **Document Decisions**: Record why refactoring was done
7. **Code Review**: Get peer review for significant refactorings
8. **Avoid Over-Engineering**: Refactor for current needs, not hypothetical future

## Common Anti-Patterns to Avoid

### ❌ Big Bang Refactoring
```dart
// DON'T: Rewrite entire module at once
// This makes debugging impossible if something breaks
```

### ✅ Incremental Refactoring
```dart
// DO: Refactor piece by piece with tests
// 1. Extract method A, test
// 2. Extract method B, test
// 3. Combine into new structure, test
```

### ❌ Refactoring Without Tests
```dart
// DON'T: Change code without safety net
// Risk: Breaking functionality without knowing
```

### ✅ Test-Driven Refactoring
```dart
// DO: Write/verify tests first
// 1. Ensure existing tests pass
// 2. Add missing tests
// 3. Refactor with confidence
// 4. Verify tests still pass
```

### ❌ Mixing Refactoring and Features
```dart
// DON'T: Add features while refactoring
// Hard to track what caused issues
```

### ✅ Separate Concerns
```dart
// DO: Refactor in dedicated commit
// 1. Commit: "Refactor UserController into smaller controllers"
// 2. Commit: "Add new profile feature"
```

## Notes

- Always maintain working code during refactoring
- Use feature flags for large refactorings
- Consider backward compatibility
- Update all dependent code
- Refactor tests along with production code
- Don't refactor without clear goal
- Measure before and after (performance, complexity)
