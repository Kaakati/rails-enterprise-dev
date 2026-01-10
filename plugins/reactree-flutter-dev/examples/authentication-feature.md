# Example: Authentication Feature with JWT

This example demonstrates implementing a complete authentication feature using Clean Architecture, GetX, HTTP, and GetStorage.

## Requirements

- User login with email and password
- JWT token storage
- Token refresh mechanism
- Logout functionality
- Protected routes

## Implementation Structure

```
lib/
├── core/
│   └── constants/
│       └── api_endpoints.dart
├── domain/
│   ├── entities/
│   │   └── auth_user.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── login_user.dart
│       ├── logout_user.dart
│       └── refresh_token.dart
├── data/
│   ├── models/
│   │   └── auth_user_model.dart
│   ├── repositories/
│   │   └── auth_repository_impl.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   └── local/
│       └── auth_local_source.dart
└── presentation/
    ├── controllers/
    │   └── auth_controller.dart
    ├── bindings/
    │   └── auth_binding.dart
    └── pages/
        ├── login_page.dart
        └── register_page.dart
```

## Domain Layer

### Entity
```dart
// lib/domain/entities/auth_user.dart
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String name;
  
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
  });
  
  @override
  List<Object?> get props => [id, email, name];
}
```

### Repository Interface
```dart
// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, String>> refreshToken();
}
```

### Use Case
```dart
// lib/domain/usecases/login_user.dart
class LoginUser {
  final AuthRepository repository;
  
  LoginUser(this.repository);
  
  Future<Either<Failure, AuthUser>> call(String email, String password) {
    return repository.login(email, password);
  }
}
```

## Data Layer

### Model
```dart
// lib/data/models/auth_user_model.dart
class AuthUserModel extends AuthUser {
  final String token;
  final String refreshToken;
  
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.name,
    required this.token,
    required this.refreshToken,
  });
  
  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      token: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }
  
  AuthUser toEntity() {
    return AuthUser(id: id, email: email, name: name);
  }
}
```

### HTTP Provider
```dart
// lib/data/providers/auth_provider.dart
class AuthProvider {
  final http.Client _client;
  final String _baseUrl;
  
  Future<AuthUserModel> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      return AuthUserModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException(message: 'Login failed');
    }
  }
}
```

### Local Storage
```dart
// lib/data/local/auth_local_source.dart
class AuthLocalSource {
  final GetStorage _storage;
  
  Future<void> saveToken(String token) async {
    await _storage.write('auth_token', token);
  }
  
  String? getToken() {
    return _storage.read('auth_token');
  }
  
  Future<void> clearToken() async {
    await _storage.remove('auth_token');
  }
}
```

## Presentation Layer

### Controller
```dart
// lib/presentation/controllers/auth_controller.dart
class AuthController extends GetxController {
  final LoginUser loginUserUseCase;
  final LogoutUser logoutUserUseCase;
  
  final _user = Rx<AuthUser?>(null);
  AuthUser? get user => _user.value;
  
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  bool get isAuthenticated => _user.value != null;
  
  Future<void> login(String email, String password) async {
    _isLoading.value = true;
    
    final result = await loginUserUseCase(email, password);
    
    result.fold(
      (failure) => Get.snackbar('Error', failure.message),
      (user) {
        _user.value = user;
        Get.offAllNamed('/home');
      },
    );
    
    _isLoading.value = false;
  }
  
  Future<void> logout() async {
    await logoutUserUseCase();
    _user.value = null;
    Get.offAllNamed('/login');
  }
}
```

### Binding
```dart
// lib/presentation/bindings/auth_binding.dart
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthProvider(Get.find()));
    Get.lazyPut(() => AuthLocalSource(Get.find()));
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(Get.find(), Get.find()),
    );
    Get.lazyPut(() => LoginUser(Get.find()));
    Get.lazyPut(() => LogoutUser(Get.find()));
    Get.lazyPut(() => AuthController(
      loginUserUseCase: Get.find(),
      logoutUserUseCase: Get.find(),
    ));
  }
}
```

### UI
```dart
// lib/presentation/pages/login_page.dart
class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            GetX<AuthController>(
              builder: (controller) {
                return ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.login(
                            emailController.text,
                            passwordController.text,
                          ),
                  child: controller.isLoading
                      ? CircularProgressIndicator()
                      : Text('Login'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing

```dart
// test/domain/usecases/login_user_test.dart
void main() {
  late LoginUser useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUser(mockRepository);
  });

  test('should return AuthUser when login is successful', () async {
    // Arrange
    final tUser = AuthUser(id: '1', email: 'test@example.com', name: 'Test');
    when(() => mockRepository.login('test@example.com', 'password'))
        .thenAnswer((_) async => Right(tUser));

    // Act
    final result = await useCase('test@example.com', 'password');

    // Assert
    expect(result, Right(tUser));
    verify(() => mockRepository.login('test@example.com', 'password')).called(1);
  });
}
```

## Workflow Command

```
/flutter-dev add authentication with JWT, login, logout, and token refresh
```

This will generate all files above following Clean Architecture + GetX patterns.
