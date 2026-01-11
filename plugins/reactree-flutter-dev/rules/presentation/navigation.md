---
name: Navigation Rules
paths:
  - lib/presentation/routes/**/*.dart
  - lib/presentation/pages/**/*_page.dart
description: Enforcement rules for GetX navigation including route definitions, parameters, and navigation methods
---

# Navigation Rules

Rules for implementing navigation in Flutter applications using GetX routing system.

## File Organization

```
lib/presentation/routes/
├── app_routes.dart        # Route name constants
├── app_pages.dart         # GetPage definitions
└── middlewares/           # Navigation guards
    ├── auth_middleware.dart
    └── role_middleware.dart
```

## Route Definitions

### Rule 1: Use Named Routes Only

**✅ CORRECT**:
```dart
// Define routes as constants
class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const profile = '/profile';
  static const productDetails = '/product/:id';
}

// Navigate using named routes
Get.toNamed(AppRoutes.profile);
Get.toNamed('/product/123');
```

**❌ INCORRECT**:
```dart
// Don't navigate with widget instances directly (loses type safety)
Get.to(() => ProfilePage());

// Don't use magic strings
Get.toNamed('/profile'); // Use AppRoutes.profile instead
```

### Rule 2: Route Names Must Follow Conventions

- Use lowercase with dashes: `/user-profile` ✅
- NOT camelCase: `/userProfile` ❌
- NOT underscores: `/user_profile` ❌

**✅ CORRECT**:
```dart
class AppRoutes {
  static const userProfile = '/user-profile';
  static const productDetails = '/product-details/:id';
  static const editPost = '/post/:postId/edit';
}
```

**❌ INCORRECT**:
```dart
class AppRoutes {
  static const userProfile = '/userProfile'; // Wrong casing
  static const productDetails = '/product_details/:id'; // Underscores
}
```

### Rule 3: Parameters Must Use Colon Syntax

**✅ CORRECT**:
```dart
static const productDetails = '/product/:id';
static const userProfile = '/user/:userId';
static const editComment = '/post/:postId/comment/:commentId';

// Access parameters
final productId = Get.parameters['id'];
```

**❌ INCORRECT**:
```dart
static const productDetails = '/product/{id}'; // Wrong syntax
static const userProfile = '/user/<userId>'; // Wrong syntax
```

## GetPage Configuration

### Rule 4: All Routes Must Have Bindings

**✅ CORRECT**:
```dart
GetPage(
  name: AppRoutes.profile,
  page: () => ProfilePage(),
  binding: ProfileBinding(), // Always include binding
)
```

**❌ INCORRECT**:
```dart
GetPage(
  name: AppRoutes.profile,
  page: () => ProfilePage(),
  // Missing binding - controller won't be registered
)
```

### Rule 5: Use Middlewares for Route Guards

**✅ CORRECT**:
```dart
GetPage(
  name: AppRoutes.adminPanel,
  page: () => AdminPanelPage(),
  binding: AdminBinding(),
  middlewares: [
    AuthMiddleware(),  // Check authentication
    AdminMiddleware(), // Check admin role
  ],
)
```

**❌ INCORRECT**:
```dart
// Don't check auth in controller
class AdminPanelController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    if (!authService.isAuthenticated) {
      Get.offAllNamed(AppRoutes.login); // Wrong place for this
    }
  }
}
```

### Rule 6: Specify Transitions for Consistency

**✅ CORRECT**:
```dart
GetPage(
  name: AppRoutes.login,
  page: () => LoginPage(),
  binding: LoginBinding(),
  transition: Transition.fadeIn,
  transitionDuration: const Duration(milliseconds: 300),
)
```

## Navigation Methods

### Rule 7: Use Appropriate Navigation Method

**Navigation Methods**:
- `Get.toNamed()` - Push new route
- `Get.offNamed()` - Replace current route
- `Get.offAllNamed()` - Clear stack and navigate
- `Get.back()` - Pop current route

**✅ CORRECT**:
```dart
// Login success - clear stack, go to home
Get.offAllNamed(AppRoutes.home);

// Logout - clear stack, go to login
Get.offAllNamed(AppRoutes.login);

// Cancel/Close - go back
Get.back();

// Navigate to details - push
Get.toNamed(AppRoutes.productDetails, arguments: {'id': product.id});
```

**❌ INCORRECT**:
```dart
// Wrong method - should clear stack after login
Get.toNamed(AppRoutes.home); // User can go back to login

// Wrong method - should use Get.back()
Get.offNamed(previousRoute); // Complicated and error-prone
```

### Rule 8: Pass Parameters Correctly

**Route Parameters** (in URL):
```dart
// ✅ CORRECT
Get.toNamed('/product/123'); // Parameter in URL
final productId = Get.parameters['id']; // '123'
```

**Arguments** (separate object):
```dart
// ✅ CORRECT
Get.toNamed(
  AppRoutes.profile,
  arguments: {
    'userId': 123,
    'userName': 'John',
  },
);

final args = Get.arguments as Map<String, dynamic>;
final userId = args['userId'];
```

**❌ INCORRECT**:
```dart
// Don't mix route params and arguments for same data
Get.toNamed(
  '/product/123',
  arguments: {'id': 123}, // Redundant - use route param OR argument
);
```

## Middleware Implementation

### Rule 9: Middleware Must Implement GetMiddleware

**✅ CORRECT**:
```dart
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    if (!authService.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null; // Allow navigation
  }
}
```

**❌ INCORRECT**:
```dart
// Don't create custom middleware class without extending GetMiddleware
class AuthMiddleware {
  bool canAccess(String route) {
    return Get.find<AuthService>().isAuthenticated;
  }
}
```

### Rule 10: Use Priority for Middleware Order

**✅ CORRECT**:
```dart
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1; // Runs first
}

class RoleMiddleware extends GetMiddleware {
  @override
  int? get priority => 2; // Runs after auth
}
```

## Deep Linking

### Rule 11: Configure Deep Links in Platform Files

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="myapp.com" />
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

## Best Practices

### ✅ DO:
- Define all routes in `app_routes.dart` as constants
- Use bindings for all routes
- Use middlewares for authentication/authorization
- Use appropriate navigation methods (`toNamed`, `offNamed`, `offAllNamed`)
- Specify transitions for consistency
- Use route parameters for IDs
- Use arguments for complex data
- Configure deep linking for production apps

### ❌ DON'T:
- Use magic strings for routes
- Navigate without bindings
- Check auth in controllers (use middleware)
- Mix route parameters and arguments for same data
- Use `Get.to(() => Widget())` in production (loses type safety)
- Forget to handle back navigation
- Use inconsistent transition durations
- Skip deep linking configuration

## Validation Checklist

- [ ] All routes defined in `AppRoutes` class
- [ ] Route names use lowercase with dashes
- [ ] All `GetPage` definitions include bindings
- [ ] Authentication routes use `AuthMiddleware`
- [ ] Admin routes use `AdminMiddleware`
- [ ] Transitions specified for consistency
- [ ] Deep linking configured for both platforms
- [ ] Route parameters use `:param` syntax
- [ ] Arguments passed as Map<String, dynamic>
- [ ] Back navigation handled properly

## Common Anti-Patterns

### ❌ Circular Navigation
```dart
// LoginPage
if (success) {
  Get.toNamed(AppRoutes.home); // Can go back to login
}

// Should be:
Get.offAllNamed(AppRoutes.home); // Clear stack
```

### ❌ Navigation in Build Method
```dart
@override
Widget build(BuildContext context) {
  if (!isAuthenticated) {
    Get.offAllNamed(AppRoutes.login); // Don't navigate in build
  }
  return Scaffold(...);
}

// Should use middleware or onInit
```

### ❌ Hard-Coded Routes
```dart
Get.toNamed('/profile'); // Use AppRoutes.profile
Get.toNamed('/product/details'); // Use AppRoutes.productDetails
```

### ❌ Missing Error Handling
```dart
Get.toNamed(AppRoutes.productDetails);
// What if route doesn't exist or parameters are missing?

// Should validate parameters
if (productId != null) {
  Get.toNamed('/product/$productId');
} else {
  Get.snackbar('Error', 'Product ID required');
}
```
