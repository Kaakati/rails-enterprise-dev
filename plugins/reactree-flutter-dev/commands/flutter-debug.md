---
name: flutter-debug
description: Debugging workflow for Flutter applications with systematic issue investigation and resolution
allowed-tools: ["*"]
---

# Flutter Debug Command

Systematic debugging workflow for investigating and resolving issues in Flutter applications using GetX and Clean Architecture.

## Usage

```
/flutter-debug [issue description]
```

## Examples

```
/flutter-debug GetX controller not updating UI when data changes
/flutter-debug App crashes when submitting form with empty fields
/flutter-debug API call returns 401 but token seems valid
/flutter-debug Widget rebuilding too many times causing performance issues
/flutter-debug GetStorage not persisting data after app restart
/flutter-debug Navigation breaks after going back from detail screen
```

## What This Command Does

This command provides systematic debugging assistance:

### 1. Issue Analysis
- Parse issue description
- Identify affected layers (domain/data/presentation)
- Categorize issue type (state, network, storage, UI, navigation)
- Determine debug strategy

### 2. Code Investigation
- Examine related controllers and bindings
- Check use case implementations
- Review repository and data source code
- Inspect widget structure and state management
- Analyze error logs and stack traces

### 3. Root Cause Identification
- Test hypotheses systematically
- Isolate problematic code sections
- Identify pattern violations
- Check for common anti-patterns

### 4. Solution Implementation
- Fix identified issues
- Add defensive checks
- Improve error handling
- Add logging for future debugging

### 5. Verification
- Write regression tests
- Verify fix across scenarios
- Check for side effects
- Run quality gates

## Common Issue Categories

### GetX State Management Issues

**Issue**: UI not updating when controller state changes

**Investigation**:
```dart
// Check 1: Is state reactive?
// ❌ BAD
class MyController extends GetxController {
  String title = 'Hello'; // Not reactive
  void updateTitle() {
    title = 'World'; // UI won't update
  }
}

// ✅ GOOD
class MyController extends GetxController {
  final title = 'Hello'.obs;
  void updateTitle() {
    title.value = 'World'; // UI updates
  }
}

// Check 2: Is widget observing correctly?
// ❌ BAD
Widget build(BuildContext context) {
  final controller = Get.find<MyController>();
  return Text(controller.title.value); // Not observing
}

// ✅ GOOD
Widget build(BuildContext context) {
  return Obx(() {
    final controller = Get.find<MyController>();
    return Text(controller.title.value); // Observing
  });
}
```

**Issue**: GetX controller not found

**Investigation**:
```dart
// Check 1: Is controller registered in binding?
class MyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MyController(useCase: Get.find()));
  }
}

// Check 2: Is binding attached to route?
GetPage(
  name: '/my-page',
  page: () => MyPage(),
  binding: MyBinding(), // Must specify binding
)

// Check 3: Using Get.find() too early?
// ❌ BAD - Called before binding initialized
class MyWidget extends StatelessWidget {
  final controller = Get.find<MyController>(); // Error!
}

// ✅ GOOD - Called during build
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyController>(); // Works
    return ...;
  }
}
```

### Network & API Issues

**Issue**: API calls failing with 401/403

**Investigation**:
```dart
// Check 1: Is token being sent?
class AuthenticatedClient {
  Future<http.Response> get(String endpoint) async {
    final token = await _storage.getToken();
    print('DEBUG: Token = $token'); // Log token

    return _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}

// Check 2: Is token expired?
bool isTokenExpired(String token) {
  try {
    final parts = token.split('.');
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
    );
    final exp = payload['exp'] as int;
    return DateTime.now().millisecondsSinceEpoch / 1000 > exp;
  } catch (e) {
    return true;
  }
}

// Check 3: Are refresh tokens handled?
Future<http.Response> _getWithRetry(String endpoint) async {
  var response = await _get(endpoint);

  if (response.statusCode == 401) {
    // Try refreshing token
    await _refreshToken();
    response = await _get(endpoint); // Retry
  }

  return response;
}
```

**Issue**: API calls timing out

**Investigation**:
```dart
// Check 1: Is timeout set appropriately?
final client = http.Client();
try {
  final response = await client.get(uri).timeout(
    Duration(seconds: 10), // Adjust timeout
    onTimeout: () {
      throw TimeoutException('Request timed out');
    },
  );
} catch (e) {
  if (e is TimeoutException) {
    // Handle timeout specifically
    return Left(NetworkFailure(message: 'Request timed out'));
  }
  rethrow;
}

// Check 2: Is network connectivity checked?
Future<bool> hasConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
```

### GetStorage Issues

**Issue**: Data not persisting across app restarts

**Investigation**:
```dart
// Check 1: Is GetStorage initialized?
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // MUST call before using
  runApp(MyApp());
}

// Check 2: Are writes awaited?
// ❌ BAD
void saveData(String data) {
  _storage.write('key', data); // Not awaited
}

// ✅ GOOD
Future<void> saveData(String data) async {
  await _storage.write('key', data); // Awaited
}

// Check 3: Is data serializable?
// ❌ BAD
class User {
  final String name;
  User(this.name);
}
_storage.write('user', User('John')); // Can't serialize

// ✅ GOOD
_storage.write('user', {'name': 'John'}); // JSON-serializable
```

### Performance Issues

**Issue**: Widget rebuilding too frequently

**Investigation**:
```dart
// Check 1: Are you using Obx() correctly?
// ❌ BAD - Observing entire controller
Obx(() {
  final controller = Get.find<MyController>();
  return Column(
    children: [
      Text(controller.title.value), // Only this needs to rebuild
      ExpensiveWidget(), // Rebuilds unnecessarily
    ],
  );
})

// ✅ GOOD - Minimize observable scope
Column(
  children: [
    Obx(() => Text(Get.find<MyController>().title.value)),
    ExpensiveWidget(), // Doesn't rebuild
  ],
)

// Check 2: Are you creating unnecessary observables?
// ❌ BAD
class MyController extends GetxController {
  final config = AppConfig().obs; // Config doesn't change
}

// ✅ GOOD
class MyController extends GetxController {
  final config = AppConfig(); // Not observable
}

// Check 3: Use const constructors
// ❌ BAD
return Container(child: Text('Static'));

// ✅ GOOD
return const Container(child: Text('Static'));
```

**Issue**: Memory leaks

**Investigation**:
```dart
// Check 1: Are controllers being disposed?
class MyController extends GetxController {
  late StreamSubscription _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = someStream.listen((_) {});
  }

  @override
  void onClose() {
    _subscription.cancel(); // MUST cancel
    super.onClose();
  }
}

// Check 2: Are permanent controllers necessary?
// ❌ BAD - Creates permanent instance
Get.put(MyController(), permanent: true);

// ✅ GOOD - Disposed when not needed
Get.lazyPut(() => MyController());

// Check 3: Check for circular references
// Use Flutter DevTools → Memory → Snapshot
```

### Navigation Issues

**Issue**: GetX navigation not working

**Investigation**:
```dart
// Check 1: Is GetMaterialApp used?
// ❌ BAD
MaterialApp(
  home: MyHomePage(),
)

// ✅ GOOD
GetMaterialApp(
  home: MyHomePage(),
)

// Check 2: Are routes defined?
GetMaterialApp(
  initialRoute: '/',
  getPages: [
    GetPage(name: '/', page: () => HomePage()),
    GetPage(name: '/details', page: () => DetailsPage()),
  ],
)

// Check 3: Using correct navigation method?
// For named routes
Get.toNamed('/details', arguments: {'id': 123});

// For route instances
Get.to(() => DetailsPage(id: 123));

// For replacing
Get.off(() => NewPage());

// For clearing stack
Get.offAll(() => HomePage());
```

## Debug Workflow Phases

### Phase 1: Issue Understanding (5 minutes)
- Read error messages and stack traces
- Identify symptoms vs root cause
- Determine affected components
- List relevant files to investigate

### Phase 2: Code Investigation (10-15 minutes)
- Examine controllers and bindings
- Review use cases and repositories
- Check data sources and models
- Inspect UI widgets and state management
- Look for pattern violations

### Phase 3: Hypothesis Testing (15-30 minutes)
- Add debug logging strategically
- Test different scenarios
- Isolate problematic code
- Verify assumptions
- Check for common anti-patterns

### Phase 4: Root Cause Analysis (10 minutes)
- Identify exact cause of issue
- Document why issue occurred
- Note related issues to check
- Plan prevention strategy

### Phase 5: Fix Implementation (20-40 minutes)
- Implement targeted fix
- Add defensive programming
- Improve error handling
- Add debug logging for future
- Update tests

### Phase 6: Verification (10 minutes)
- Test fix in multiple scenarios
- Run regression tests
- Check for side effects
- Verify quality gates pass
- Document resolution

## Debugging Tools & Techniques

### Flutter DevTools
```bash
# Launch DevTools
flutter run
# Press 'w' to open DevTools in browser
```

**Key Features**:
- **Inspector**: Widget tree, layout issues
- **Timeline**: Performance profiling
- **Memory**: Heap snapshots, leak detection
- **Network**: HTTP request monitoring
- **Logging**: Console output

### Debug Logging
```dart
// Development-only logging
import 'package:flutter/foundation.dart';

void debugLog(String message) {
  if (kDebugMode) {
    print('[DEBUG] ${DateTime.now()}: $message');
  }
}

// Structured logging
class AppLogger {
  static void error(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('❌ ERROR: $message');
    if (error != null) debugPrint('  Error: $error');
    if (stack != null) debugPrint('  Stack: $stack');
  }

  static void warning(String message) {
    debugPrint('⚠️  WARNING: $message');
  }

  static void info(String message) {
    debugPrint('ℹ️  INFO: $message');
  }
}
```

### GetX Debugging
```dart
// Enable GetX logs
void main() {
  // Show routes, snackbars, dialogs, bottomsheets
  Get.config(
    enableLog: true,
    defaultTransition: Transition.fade,
    opaqueRoute: Get.isOpaqueRouteDefault,
    defaultOpaqueRoute: Get.isOpaqueRouteDefault,
    defaultGlobalState: Get.isLogEnable,
  );

  runApp(MyApp());
}

// Log controller lifecycle
class MyController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    debugPrint('MyController initialized');
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('MyController ready');
  }

  @override
  void onClose() {
    debugPrint('MyController closing');
    super.onClose();
  }
}
```

### Network Debugging
```dart
// HTTP client with logging
class LoggingClient {
  final http.Client _client;

  LoggingClient(this._client);

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    debugPrint('→ GET $url');
    debugPrint('  Headers: $headers');

    final response = await _client.get(url, headers: headers);

    debugPrint('← Response ${response.statusCode}');
    debugPrint('  Body: ${response.body.substring(0, 200)}...');

    return response;
  }
}
```

## Activation

When the user invokes `/flutter-debug [issue]`:

1. Parse the issue description
2. Spawn the **workflow-orchestrator** agent in debug mode
3. Analyze the issue systematically
4. Investigate code and identify root cause
5. Implement fix with proper testing
6. Verify solution and run quality gates
7. Document resolution and prevention strategies

## Integration with Other Commands

- Use `/flutter-dev` to implement fixes requiring new features
- Use `/flutter-refactor` to improve problematic code structure
- Use `/flutter-feature` to add defensive features preventing issues

## Notes

- Always add regression tests for fixed bugs
- Document common issues in project wiki
- Use debug logging liberally during investigation
- Check Flutter DevTools for performance issues
- Verify fixes don't introduce new problems
- Consider preventive refactoring after fixing
