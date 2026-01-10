---
name: flutter-feature
description: Feature-driven Flutter development workflow with GetX, Clean Architecture, and quality gates
allowed-tools: ["*"]
---

# Flutter Feature Development Command

Feature-driven development workflow for Flutter applications using GetX state management and Clean Architecture patterns.

## Usage

```
/flutter-feature [feature description]
```

## Examples

```
/flutter-feature add user profile with avatar upload and bio editing
/flutter-feature implement shopping cart with add/remove items and checkout
/flutter-feature create chat feature with real-time messaging and typing indicators
/flutter-feature add offline-first todo list with sync when online
```

## What This Command Does

This command implements complete vertical slices of functionality following Clean Architecture:

### 1. Feature Analysis
- Parse feature requirements
- Identify domain entities and use cases
- Plan data flow (API, cache, UI)
- Define acceptance criteria

### 2. Domain Layer Implementation
- Create entities (pure Dart classes)
- Define repository interfaces
- Implement use cases (business logic)
- Write domain layer tests

### 3. Data Layer Implementation
- Create data models with JSON serialization
- Implement repository concrete classes
- Build HTTP providers for API calls
- Create GetStorage local data sources
- Implement offline-first strategies
- Write data layer tests

### 4. Presentation Layer Implementation
- Create GetX controllers with reactive state
- Implement dependency injection bindings
- Build UI widgets with Material Design
- Handle loading/error/success states
- Write widget tests

### 5. Integration & Testing
- Create integration tests for full feature flow
- Validate user journey end-to-end
- Test offline scenarios
- Verify error handling

### 6. Quality Gates
- Run `flutter analyze` (0 errors)
- Verify test coverage ≥ 80%
- Validate build success
- Check GetX pattern compliance
- Verify Clean Architecture boundaries

## Feature Structure

Each feature creates a complete vertical slice:

```
lib/
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── usecases/
│       ├── create_feature.dart
│       ├── get_feature.dart
│       └── update_feature.dart
├── data/
│   ├── models/
│   │   └── feature_model.dart
│   ├── repositories/
│   │   └── feature_repository_impl.dart
│   └── datasources/
│       ├── feature_remote_datasource.dart
│       └── feature_local_datasource.dart
└── presentation/
    ├── controllers/
    │   └── feature_controller.dart
    ├── bindings/
    │   └── feature_binding.dart
    └── pages/
        └── feature_page.dart

test/
├── domain/
│   └── usecases/
│       └── feature_usecases_test.dart
├── data/
│   ├── models/
│   │   └── feature_model_test.dart
│   └── repositories/
│       └── feature_repository_impl_test.dart
├── presentation/
│   ├── controllers/
│   │   └── feature_controller_test.dart
│   └── widgets/
│       └── feature_widget_test.dart
└── integration/
    └── feature_flow_test.dart
```

## Workflow Phases

### Phase 1: Understanding (5 minutes)
- Parse feature description
- Identify entities and boundaries
- Define user stories
- List acceptance criteria

### Phase 2: Inspection (5-10 minutes)
- Analyze existing project structure
- Discover naming conventions
- Check existing similar features
- Identify reusable patterns

### Phase 3: Planning (10-15 minutes)
- Design domain entities and use cases
- Plan data models and API endpoints
- Design UI screens and navigation
- Define test scenarios
- Map dependencies

### Phase 4: Implementation (30-60 minutes)
- Implement domain layer (entities, use cases, interfaces)
- Implement data layer (models, repositories, data sources)
- Implement presentation layer (controllers, bindings, UI)
- Write comprehensive tests
- Handle edge cases and errors

### Phase 5: Quality Validation (10 minutes)
- Run dart analysis
- Check test coverage
- Build application
- Verify GetX patterns
- Validate Clean Architecture

### Phase 6: Documentation (5 minutes)
- Update feature documentation
- Add usage examples
- Document API contracts
- Note any limitations

## Best Practices

### Clean Architecture Boundaries
```dart
// ✅ CORRECT: Use cases depend on repository interfaces
class GetUser {
  final UserRepository repository; // Interface from domain
  GetUser(this.repository);

  Future<Either<Failure, User>> call(String id) {
    return repository.getUser(id);
  }
}

// ❌ WRONG: Use cases depend on concrete implementations
class GetUser {
  final UserRepositoryImpl repository; // Concrete class from data layer
  // Violates Clean Architecture dependency rule
}
```

### GetX State Management
```dart
// ✅ CORRECT: Reactive state with proper initialization
class FeatureController extends GetxController {
  final _items = <Item>[].obs;
  List<Item> get items => _items.toList();

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}

// ❌ WRONG: Non-reactive state
class FeatureController extends GetxController {
  List<Item> items = []; // Not reactive
  bool isLoading = false; // Won't trigger UI updates
}
```

### Offline-First Patterns
```dart
// ✅ CORRECT: Cache-first with network refresh
Future<Either<Failure, List<Item>>> getItems() async {
  try {
    // Try cache first
    final cachedItems = await localDataSource.getItems();

    // Return cached data immediately
    if (cachedItems.isNotEmpty) {
      // Refresh in background
      _refreshFromNetwork();
      return Right(cachedItems.map((m) => m.toEntity()).toList());
    }

    // No cache, fetch from network
    return await _fetchFromNetwork();
  } catch (e) {
    return Left(CacheFailure());
  }
}
```

### Error Handling
```dart
// ✅ CORRECT: Comprehensive error handling
Future<void> loadFeature() async {
  _isLoading.value = true;
  _error.value = null;

  final result = await getFeatureUseCase(id);

  result.fold(
    (failure) {
      _error.value = _mapFailureToMessage(failure);
      // Log error for debugging
      logger.error('Failed to load feature', failure);
    },
    (feature) {
      _feature.value = feature;
    },
  );

  _isLoading.value = false;
}

String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return 'Server error. Please try again.';
    case NetworkFailure:
      return 'No internet connection.';
    case CacheFailure:
      return 'Failed to load cached data.';
    default:
      return 'Unexpected error occurred.';
  }
}
```

## Activation

When the user invokes `/flutter-feature [description]`:

1. Parse the feature description
2. Spawn the **workflow-orchestrator** agent
3. Set workflow mode to "feature-driven"
4. Execute all 6 phases with focus on vertical slice
5. Ensure complete feature implementation from domain to UI
6. Validate with quality gates
7. Report completion with feature summary

## Integration with Other Commands

- Use `/flutter-debug` to troubleshoot feature issues
- Use `/flutter-refactor` to improve feature structure
- Use `/flutter-dev` for general development tasks

## Notes

- Features should be sized for 1-2 hours of implementation
- Break large features into multiple smaller features
- Each feature should have clear acceptance criteria
- All features must pass quality gates before completion
- Focus on user value and complete user journeys
