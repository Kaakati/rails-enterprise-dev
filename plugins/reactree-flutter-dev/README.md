# ReAcTree Flutter Development Plugin

Multi-agent orchestration for Flutter development with GetX state management, Clean Architecture, and comprehensive quality gates.

## 🚀 Features

- **Clean Architecture**: Enforces domain → data → presentation layer separation
- **GetX State Management**: Best practices for controllers, bindings, and reactive programming
- **Quality Gates**: Automated dart analysis, test coverage, build validation, and GetX compliance
- **Multi-Agent Workflow**: Specialized agents for domain, data, presentation, and testing
- **Comprehensive Testing**: Unit, widget, integration, and golden tests with 80% coverage threshold
- **Http Integration**: Best practices for REST API calls with proper error handling
- **GetStorage Patterns**: Efficient local storage with caching strategies

## 📦 Installation

### Option 1: Manual Installation

1. Copy the plugin directory to your project:
```bash
cp -r plugins/reactree-flutter-dev /path/to/your/flutter/project/.claude/plugins/
```

2. Ensure your Flutter project has `pubspec.yaml` at the root

### Option 2: Clone from Repository

```bash
cd /path/to/your/flutter/project/.claude/plugins
git clone https://github.com/kaakati/flutter-enterprise-dev.git reactree-flutter-dev
```

## 🎯 Quick Start

### Basic Usage

```
/flutter-dev add user authentication with JWT tokens
```

The plugin will:
1. ✅ Detect Flutter project root
2. ✅ Parse requirements into user stories
3. ✅ Analyze existing code patterns
4. ✅ Plan implementation with Clean Architecture
5. ✅ Generate domain entities and use cases
6. ✅ Create data models, repositories, and data sources
7. ✅ Implement GetX controllers, bindings, and UI
8. ✅ Generate comprehensive tests
9. ✅ Run quality gates (analyze, test, build)

## 📚 Available Commands

### `/flutter-dev` - Main Development Workflow

Full-featured development with all quality gates.

**Examples:**

**Authentication & User Management:**
```
/flutter-dev add user authentication with JWT tokens
/flutter-dev implement OAuth2 login with Google
/flutter-dev create user profile with avatar upload
/flutter-dev add password reset flow with email verification
```

**API Integration:**
```
/flutter-dev create product catalog with REST API
/flutter-dev implement GraphQL client for posts
/flutter-dev add WebSocket real-time chat
/flutter-dev build pagination for user list
```

**Offline-First Features:**
```
/flutter-dev implement offline-first notes app with sync
/flutter-dev add offline product catalog with GetStorage
/flutter-dev create cache-first user profile
```

**State Management:**
```
/flutter-dev add shopping cart with GetX state
/flutter-dev implement multi-step form with validation
/flutter-dev create global theme controller
/flutter-dev add settings screen with reactive preferences
```

**Data & Models:**
```
/flutter-dev create Order model with JSON serialization
/flutter-dev implement polymorphic User model (admin/customer)
/flutter-dev add full-text search for products
```

### `/flutter-feature` - Feature-Driven Development

Focused on complete vertical slices (domain → data → presentation).

```
/flutter-feature user authentication
```

### `/flutter-debug` - Debugging Workflow

Investigate and fix issues in existing code.

```
/flutter-debug GetX controller not updating UI
```

### `/flutter-refactor` - Refactoring Workflow

Safe refactoring with test guarantees.

```
/flutter-refactor extract authentication logic to use case
```

## 🏗️ Architecture

### Clean Architecture Layers

```
lib/
├── core/                       # Shared utilities
│   ├── error/                  # Failure & exception classes
│   ├── network/                # Network info
│   └── usecases/               # Base use case class
├── domain/                     # Business Logic (Pure Dart)
│   ├── entities/               # Business objects
│   ├── repositories/           # Repository interfaces
│   └── usecases/               # Business logic
├── data/                       # Data Layer
│   ├── models/                 # JSON serialization
│   ├── repositories/           # Repository implementations
│   └── datasources/            # API & local storage
│       ├── remote/             # Http API calls
│       └── local/              # GetStorage caching
└── presentation/               # UI Layer
    ├── controllers/            # GetX controllers
    ├── bindings/               # Dependency injection
    ├── pages/                  # Screens
    └── widgets/                # Reusable components
```

### Dependency Flow

```
Presentation → Data → Domain
    ↓           ↓        ↑
  GetX      Repository  Pure
Controllers  Impl      Business
  & UI               Logic
```

**Rule**: Outer layers depend on inner layers, NEVER reverse.

## 🧪 Quality Gates

### 1. Dart Analysis
```bash
flutter analyze
```
- ✅ 0 errors required
- ⚠️ Warnings acceptable with justification

### 2. Test Coverage
```bash
flutter test --coverage
```
- ✅ Minimum 80% code coverage
- ✅ Covers domain, data, and presentation layers

### 3. Build Validation
```bash
flutter build apk --debug
```
- ✅ Build succeeds without errors

### 4. GetX Compliance
- ✅ Controllers use bindings (not direct instantiation)
- ✅ Reactive variables declared with `.obs`
- ✅ Business logic delegated to use cases
- ✅ Proper dependency injection

## 📖 Best Practices

### Domain Layer

**Entities** (Pure Dart):
```dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, email];
}
```

**Use Cases**:
```dart
import 'package:dartz/dartz.dart';

class GetUser {
  final UserRepository repository;

  GetUser(this.repository);

  Future<Either<Failure, User>> call(String id) {
    return repository.getUser(id);
  }
}
```

### Data Layer

**Models** (JSON Serialization):
```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() => User(id: id, name: name, email: email);
}
```

**Repositories**:
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getUser(id);
        await localDataSource.cacheUser(user);
        return Right(user.toEntity());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      final cachedUser = await localDataSource.getCachedUser();
      return cachedUser != null
          ? Right(cachedUser.toEntity())
          : Left(CacheFailure());
    }
  }
}
```

**Data Sources**:
```dart
// Remote
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  @override
  Future<UserModel> getUser(String id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw ServerException(response.body);
    }
  }
}

// Local
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final GetStorage storage;

  @override
  Future<void> cacheUser(UserModel user) async {
    await storage.write('cached_user', user.toJson());
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final json = storage.read('cached_user');
    return json != null ? UserModel.fromJson(json) : null;
  }
}
```

### Presentation Layer

**GetX Controllers**:
```dart
class UserController extends GetxController {
  final GetUser getUserUseCase;

  UserController({required this.getUserUseCase});

  final user = Rx<User?>(null);
  final isLoading = false.obs;
  final error = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  Future<void> loadUser() async {
    isLoading.value = true;
    error.value = null;

    final result = await getUserUseCase('user-id');

    result.fold(
      (failure) => error.value = _mapFailureToMessage(failure),
      (userData) => user.value = userData,
    );

    isLoading.value = false;
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}
```

**Bindings**:
```dart
class UserBinding extends Bindings {
  @override
  void dependencies() {
    // Data sources
    Get.lazyPut<UserRemoteDataSource>(
      () => UserRemoteDataSourceImpl(
        client: Get.find(),
        baseUrl: AppConfig.apiUrl,
      ),
    );

    Get.lazyPut<UserLocalDataSource>(
      () => UserLocalDataSourceImpl(storage: Get.find()),
    );

    // Repository
    Get.lazyPut<UserRepository>(
      () => UserRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
        networkInfo: Get.find(),
      ),
    );

    // Use case
    Get.lazyPut(() => GetUser(Get.find()));

    // Controller
    Get.lazyPut(() => UserController(getUserUseCase: Get.find()));
  }
}
```

**UI Widgets**:
```dart
class UserPage extends StatelessWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: GetX<UserController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.error.value != null) {
            return Center(child: Text(controller.error.value!));
          }

          final user = controller.user.value;
          if (user == null) {
            return Center(child: Text('No user found'));
          }

          return Column(
            children: [
              Text(user.name),
              Text(user.email),
            ],
          );
        },
      ),
    );
  }
}
```

## 🧰 Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  get: ^4.6.6

  # HTTP Client
  http: ^1.1.0

  # Local Storage
  get_storage: ^2.1.1

  # Functional Programming
  dartz: ^0.10.1

  # Equality
  equatable: ^2.0.5

  # JSON Serialization
  json_annotation: ^4.8.1

dev_dependencies:
  # JSON Code Generation
  json_serializable: ^6.7.1
  build_runner: ^2.4.6

  # Testing
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.1
```

## 🎓 Learning Resources

### GetX
- [Official GetX Documentation](https://pub.dev/packages/get)
- [GetX State Management](https://github.com/jonataslaw/getx/blob/master/documentation/en_US/state_management.md)
- [GetX Dependency Injection](https://github.com/jonataslaw/getx/blob/master/documentation/en_US/dependency_management.md)

### Clean Architecture
- [The Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) by Robert C. Martin
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/) by Reso Coder

### Testing
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details

## 👨‍💻 Author

**Mohamad Kaakati**
- Email: hello@kaakati.me
- GitHub: [@kaakati](https://github.com/kaakati)

## 🙏 Acknowledgments

This plugin is inspired by:
- [reactree-rails-dev](https://github.com/kaakati/rails-enterprise-dev) - Rails development plugin
- ReAcTree architecture pattern
- Clean Architecture by Robert C. Martin
- GetX state management by Jonny Borges

---

**Version**: 1.0.0
