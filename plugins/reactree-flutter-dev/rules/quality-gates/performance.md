---
name: Performance Quality Gate
paths:
  - lib/**/*.dart
description: Performance validation rules to ensure applications maintain 60 FPS and optimal memory usage
---

# Performance Quality Gate

Validation rules to ensure Flutter applications meet performance standards and maintain smooth 60 FPS (or 120 FPS on capable devices).

## Performance Targets

| Metric | Target | Validation Method |
|--------|--------|-------------------|
| Frame time | < 16ms (60 FPS) | Flutter DevTools Performance |
| Build time | < 5ms for simple widgets | Debug logging |
| Memory usage | < 100MB typical screen | DevTools Memory |
| App startup | < 2 seconds | Stopwatch |
| Image load | < 1 second | Network monitoring |
| API response | < 500ms | Network monitoring |

## Validation Rules

### Rule 1: Const Constructors Required For Static Widgets

**Validation**: Scan for StatelessWidget that don't use const constructors

**✅ PASS**:
```dart
class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Header'),
    );
  }
}
```

**❌ FAIL**:
```dart
class Header extends StatelessWidget {
  Header({Key? key}) : super(key: key); // Missing const

  @override
  Widget build(BuildContext context) {
    return Padding( // Not const
      padding: EdgeInsets.all(16.0), // Not const
      child: Text('Header'), // Not const
    );
  }
}
```

**Impact**: Non-const widgets rebuild unnecessarily, causing performance degradation.

### Rule 2: No Unnecessary Widget Rebuilds

**Validation**: Check that Obx/GetBuilder wraps only changing widgets

**✅ PASS**:
```dart
Column(
  children: [
    Obx(() => Text(controller.title.value)), // Minimal scope
    const ExpensiveWidget(), // Not affected
  ],
)
```

**❌ FAIL**:
```dart
Obx(() => Column( // Entire Column rebuilds
  children: [
    Text(controller.title.value),
    ExpensiveWidget(), // Rebuilds unnecessarily
  ],
))
```

**Detection**: Static analysis to find Obx/GetBuilder wrapping large widget trees.

### Rule 3: ListView.builder Required For Dynamic Lists

**Validation**: Ensure ListView.builder is used for lists with > 10 items

**✅ PASS**:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)
```

**❌ FAIL**:
```dart
// Creates all items upfront
ListView(
  children: items.map((item) => ItemWidget(item: item)).toList(),
)

// Not scrollable, creates all children
Column(
  children: items.map((item) => ItemWidget(item: item)).toList(),
)
```

**Detection**: Scan for `ListView(children:` pattern with more than 10 children.

### Rule 4: Keys Required For Dynamic Lists

**Validation**: Verify list items have stable keys

**✅ PASS**:
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(
      key: ValueKey(items[index].id), // Stable key
      product: items[index],
    );
  },
)
```

**❌ FAIL**:
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(product: items[index]); // No key
  },
)

// Index as key (wrong if list reorders)
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(
      key: ValueKey(index), // Unstable
      product: items[index],
    );
  },
)
```

**Detection**: Check for list builders without keys or using index as key.

### Rule 5: No Heavy Computation In Build Methods

**Validation**: Build methods should not contain expensive operations

**✅ PASS**:
```dart
class ProductController extends GetxController {
  final _filteredProducts = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    _filteredProducts.value = _computeFiltered(); // Pre-compute
  }
}

class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
      itemCount: controller.filteredProducts.length, // Use cached
      itemBuilder: (context, index) => ProductCard(product: controller.filteredProducts[index]),
    ));
  }
}
```

**❌ FAIL**:
```dart
@override
Widget build(BuildContext context) {
  // Heavy computation on every build!
  final filtered = products.where((p) => p.isActive).toList();
  final sorted = filtered..sort((a, b) => a.name.compareTo(b.name));

  return ListView.builder(...);
}
```

**Detection**: Scan build methods for:
- `.where()`, `.map()`, `.sort()` on large collections
- Database queries
- API calls
- Complex calculations

### Rule 6: Images Must Use CachedNetworkImage

**Validation**: Network images should use caching

**✅ PASS**:
```dart
CachedNetworkImage(
  imageUrl: product.imageUrl,
  width: 200,
  height: 200,
  memCacheWidth: 400, // 2x for high DPI
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

**❌ FAIL**:
```dart
// No caching
Image.network(product.imageUrl)
```

**Detection**: Scan for `Image.network()` usage.

### Rule 7: Controllers Must Dispose Resources

**Validation**: GetxController must dispose all resources in onClose()

**✅ PASS**:
```dart
class MyController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  late final StreamSubscription _subscription;

  @override
  void onClose() {
    scrollController.dispose();
    textController.dispose();
    _subscription.cancel();
    super.onClose();
  }
}
```

**❌ FAIL**:
```dart
class MyController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  // Missing onClose() - memory leak
}
```

**Detection**: Check for controllers with ScrollController, TextEditingController, StreamSubscription, AnimationController without onClose() disposal.

### Rule 8: Lazy Loading For Controllers

**Validation**: Controllers should use lazyPut instead of put

**✅ PASS**:
```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController()); // Loaded when first accessed
  }
}
```

**❌ FAIL**:
```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController()); // Loaded immediately
  }
}
```

**Exception**: Use `put` only for singletons needed immediately (like AuthService).

### Rule 9: AnimatedWidget For Custom Animations

**Validation**: Custom animations should extend AnimatedWidget

**✅ PASS**:
```dart
class ScaleTransition extends AnimatedWidget {
  const ScaleTransition({
    required Animation<double> scale,
    required this.child,
  }) : super(listenable: scale);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.scale(
      scale: animation.value,
      child: child, // Child not rebuilt
    );
  }
}
```

**❌ FAIL**:
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _controller.value,
      child: ExpensiveWidget(), // Rebuilt every frame!
    );
  }
}
```

## Automated Performance Checks

### Build-Time Checks

Run these validations during build:

```bash
# 1. Const constructor validation
flutter analyze | grep "prefer_const_constructors"

# 2. Large list optimization
flutter analyze | grep "avoid_slow_async_io"

# 3. Memory leak detection
flutter analyze | grep "cancel_subscriptions"
```

### Runtime Profiling

Profile in release mode:

```bash
# Run in profile mode (NOT debug)
flutter run --profile

# Check for jank (frames > 16ms)
# Use Flutter DevTools Performance tab
```

### Performance Metrics Collection

```dart
// Add to app initialization
void measureAppStartup() {
  final startTime = DateTime.now();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    if (duration.inMilliseconds > 2000) {
      print('WARNING: App startup took ${duration.inMilliseconds}ms (target: < 2000ms)');
    }
  });
}
```

## Quality Gate Checklist

Before merging:

- [ ] All widgets use const constructors where possible
- [ ] Obx/GetBuilder scope is minimized
- [ ] Dynamic lists use ListView.builder with keys
- [ ] No heavy computation in build methods
- [ ] Images use CachedNetworkImage
- [ ] All controllers dispose resources
- [ ] Controllers use lazyPut in bindings
- [ ] Custom animations extend AnimatedWidget
- [ ] App startup < 2 seconds
- [ ] No frames > 16ms during scrolling
- [ ] Memory usage < 100MB for typical screens
- [ ] Flutter analyze reports no performance warnings

## Performance Profiling Commands

```bash
# Run performance profiling
flutter run --profile

# Measure build times
flutter run --trace-startup --profile

# Check for slow operations
flutter run --verbose

# Analyze bundle size
flutter build apk --analyze-size
flutter build ios --analyze-size

# Check for unused code
flutter analyze --suggestions
```

## Common Performance Issues

### Issue 1: Excessive Rebuilds

**Symptom**: UI feels sluggish, DevTools shows many widget rebuilds

**Fix**: Minimize Obx scope, use const constructors, extract widgets

### Issue 2: Slow Scrolling

**Symptom**: Dropped frames during list scrolling

**Fix**: Use ListView.builder, add cacheExtent, optimize item widgets

### Issue 3: Memory Growth

**Symptom**: App memory increases over time

**Fix**: Dispose controllers, cancel streams, clear caches

### Issue 4: Slow App Startup

**Symptom**: App takes > 2 seconds to show first screen

**Fix**: Use lazy loading, defer heavy initialization, optimize main()

### Issue 5: Image Loading Lag

**Symptom**: Images flash or load slowly

**Fix**: Use CachedNetworkImage, precache critical images, optimize sizes
