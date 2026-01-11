---
name: Widget Rules
paths:
  - lib/presentation/widgets/**/*.dart
  - lib/presentation/pages/**/*.dart
description: Enforcement rules for Flutter widget design including composition, performance, accessibility, and best practices
---

# Widget Rules

Rules for building high-quality, performant, and accessible Flutter widgets.

## Widget Design Principles

### Rule 1: Prefer StatelessWidget Over StatefulWidget

**✅ CORRECT**:
```dart
// State managed by GetX controller
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(product.name),
          Text('\$${product.price}'),
        ],
      ),
    );
  }
}

// With reactive state from controller
class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();
    return Obx(() => ListView.builder(
      itemCount: controller.products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: controller.products[index]);
      },
    ));
  }
}
```

**❌ INCORRECT**:
```dart
// Unnecessary StatefulWidget for simple state
class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isExpanded = false; // Should be in controller

  @override
  Widget build(BuildContext context) {
    return Card(...);
  }
}
```

### Rule 2: Use Const Constructors Whenever Possible

**✅ CORRECT**:
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

// Usage
const Header()
```

**❌ INCORRECT**:
```dart
class Header extends StatelessWidget {
  // Missing const constructor
  Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0), // Not const
      child: Text('Header'), // Not const
    );
  }
}
```

**Why**: Const widgets are built once and reused, improving performance significantly.

### Rule 3: Extract Complex Widgets Into Separate Classes

**✅ CORRECT**:
```dart
// Extract into separate widget class
class UserProfileCard extends StatelessWidget {
  final User user;
  const UserProfileCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          UserAvatar(user: user),
          UserInfo(user: user),
          UserActions(user: user),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final User user;
  const UserAvatar({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: NetworkImage(user.avatarUrl),
      radius: 40,
    );
  }
}
```

**❌ INCORRECT**:
```dart
// Everything in build method
class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: Column(
            children: [
              // Inline complex widget - should be extracted
              Container(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.avatarUrl),
                      radius: 40,
                    ),
                    Column(
                      children: [
                        Text(user.name),
                        Text(user.email),
                        Row(
                          children: [
                            Icon(Icons.star),
                            Text('${user.rating}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**Why**: Improves readability, reusability, and performance (isolated rebuilds).

## Key Management

### Rule 4: Use Proper Keys For Dynamic Lists

**✅ CORRECT**:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ProductCard(
      key: ValueKey(items[index].id), // Stable unique key
      product: items[index],
    );
  },
)

// For objects
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(
      key: ObjectKey(items[index]), // Object-based key
      product: items[index],
    );
  },
)

// When to use different key types:
// - ValueKey: For primitive values (int, String)
// - ObjectKey: For entire objects
// - UniqueKey: Force rebuild every time (rare)
// - GlobalKey: Access widget state from anywhere (expensive, rare)
```

**❌ INCORRECT**:
```dart
// No keys - Flutter may rebuild unnecessarily
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(product: items[index]);
  },
)

// Index as key - wrong if list can reorder
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(
      key: ValueKey(index), // Wrong - index changes
      product: items[index],
    );
  },
)
```

## Performance Optimization

### Rule 5: Minimize Rebuild Scope

**✅ CORRECT**:
```dart
// Obx only wraps changing widget
Column(
  children: [
    Obx(() => Text(controller.title.value)), // Only Text rebuilds
    const ExpensiveWidget(), // Never rebuilds
    const AnotherExpensiveWidget(), // Never rebuilds
  ],
)

// Or use GetBuilder for specific controller updates
GetBuilder<ProductController>(
  id: 'product-list',
  builder: (controller) {
    return ListView.builder(
      itemCount: controller.products.length,
      itemBuilder: (context, index) => ProductCard(product: controller.products[index]),
    );
  },
)
```

**❌ INCORRECT**:
```dart
// Entire Column rebuilds
Obx(() => Column(
  children: [
    Text(controller.title.value),
    ExpensiveWidget(), // Rebuilds unnecessarily
    AnotherExpensiveWidget(), // Rebuilds unnecessarily
  ],
))
```

### Rule 6: Use ListView.builder For Dynamic Lists

**✅ CORRECT**:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)

// With separator
ListView.separated(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
  separatorBuilder: (context, index) => const Divider(),
)
```

**❌ INCORRECT**:
```dart
// Creates all items upfront - bad for large lists
ListView(
  children: items.map((item) => ItemWidget(item: item)).toList(),
)

// Column is not scrollable and creates all children
Column(
  children: items.map((item) => ItemWidget(item: item)).toList(),
)
```

### Rule 7: Avoid Heavy Computation in Build Methods

**✅ CORRECT**:
```dart
class ProductController extends GetxController {
  final _products = <Product>[].obs;
  final _filteredProducts = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    _filteredProducts.value = _computeFiltered(); // Compute once
  }

  void updateFilter(String query) {
    _filteredProducts.value = _computeFiltered(); // Compute on demand
  }
}

class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();
    return Obx(() => ListView.builder(
      itemCount: controller.filteredProducts.length, // Pre-computed
      itemBuilder: (context, index) => ProductCard(product: controller.filteredProducts[index]),
    ));
  }
}
```

**❌ INCORRECT**:
```dart
@override
Widget build(BuildContext context) {
  // Heavy computation on every build!
  final filteredProducts = products.where((p) => p.isActive).toList();
  final sortedProducts = filteredProducts..sort((a, b) => a.name.compareTo(b.name));

  return ListView.builder(
    itemCount: sortedProducts.length,
    itemBuilder: (context, index) => ProductCard(product: sortedProducts[index]),
  );
}
```

## Accessibility

### Rule 8: Provide Semantic Labels For Interactive Widgets

**✅ CORRECT**:
```dart
// Using Semantics widget
Semantics(
  label: 'Add to cart',
  hint: 'Double tap to add this product to your shopping cart',
  button: true,
  enabled: true,
  child: IconButton(
    icon: Icon(Icons.add_shopping_cart),
    onPressed: () => controller.addToCart(product),
  ),
)

// Using Tooltip (provides semantic label automatically)
Tooltip(
  message: 'Add to cart',
  child: IconButton(
    icon: Icon(Icons.add_shopping_cart),
    onPressed: () => controller.addToCart(product),
  ),
)

// Text fields with labels
TextField(
  decoration: InputDecoration(
    labelText: 'Email', // Provides semantic label
    hintText: 'name@example.com',
  ),
)
```

**❌ INCORRECT**:
```dart
// No semantic information
IconButton(
  icon: Icon(Icons.add_shopping_cart),
  onPressed: () => controller.addToCart(product),
)

// No label for text field
TextField(
  decoration: InputDecoration(
    hintText: 'Enter email', // Hint is not a label
  ),
)
```

### Rule 9: Ensure Touch Targets Are At Least 44x44 Logical Pixels

**✅ CORRECT**:
```dart
// IconButton has 48x48 default size
IconButton(
  icon: Icon(Icons.close),
  onPressed: () => close(),
)

// Custom widget with adequate size
GestureDetector(
  onTap: () => toggle(),
  child: Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    child: Icon(Icons.check, size: 16),
  ),
)

// Adequate spacing between targets
Row(
  spacing: 16, // Minimum 8px recommended
  children: [
    IconButton(icon: Icon(Icons.edit), onPressed: () => edit()),
    IconButton(icon: Icon(Icons.delete), onPressed: () => delete()),
  ],
)
```

**❌ INCORRECT**:
```dart
// Touch target too small
GestureDetector(
  onTap: () => toggle(),
  child: Icon(Icons.check, size: 16), // Only 16x16
)

// Insufficient spacing
Row(
  spacing: 2,
  children: [
    IconButton(icon: Icon(Icons.edit), onPressed: () => edit()),
    IconButton(icon: Icon(Icons.delete), onPressed: () => delete()),
  ],
)
```

### Rule 10: Ensure Sufficient Color Contrast

**✅ CORRECT**:
```dart
Text(
  'Normal text',
  style: TextStyle(
    color: Color(0xFF212121), // 16.1:1 contrast on white ✓
    fontSize: 16,
  ),
)

Text(
  'Large text',
  style: TextStyle(
    color: Color(0xFF767676), // 4.6:1 contrast on white ✓
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
)

// Form fields with sufficient contrast
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: Color(0xFF757575), // 3:1 contrast ✓
      ),
    ),
  ),
)
```

**❌ INCORRECT**:
```dart
Text(
  'Low contrast text',
  style: TextStyle(
    color: Color(0xFFCCCCCC), // 1.6:1 contrast ✗
  ),
)

TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: Color(0xFFE0E0E0), // Insufficient contrast
      ),
    ),
  ),
)
```

**Minimum Requirements**:
- Normal text (< 24px): 4.5:1 contrast ratio
- Large text (≥ 24px or ≥ 18px bold): 3:1 contrast ratio
- UI components (borders, icons): 3:1 contrast ratio

## Widget Composition

### Rule 11: Use Composition Over Inheritance

**✅ CORRECT**:
```dart
// Composition - reusable parts
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text),
    );
  }
}
```

**❌ INCORRECT**:
```dart
// Inheritance - harder to maintain
abstract class BaseButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const BaseButton({
    Key? key,
    required this.text,
    this.onPressed,
  }) : super(key: key);

  ButtonStyle getButtonStyle();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: getButtonStyle(),
      child: Text(text),
    );
  }
}

class PrimaryButton extends BaseButton {
  const PrimaryButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
  }) : super(key: key, text: text, onPressed: onPressed);

  @override
  ButtonStyle getButtonStyle() {
    return ElevatedButton.styleFrom(backgroundColor: Colors.blue);
  }
}
```

## Best Practices Checklist

### Widget Structure
- [ ] Prefer StatelessWidget over StatefulWidget
- [ ] Use const constructors for immutable widgets
- [ ] Extract complex widgets into separate classes
- [ ] Keep widget build methods simple and readable
- [ ] Use composition over inheritance

### Performance
- [ ] Minimize Obx/GetBuilder scope
- [ ] Use ListView.builder for dynamic lists
- [ ] Use proper keys for list items
- [ ] Avoid heavy computation in build methods
- [ ] Dispose controllers and listeners properly

### Accessibility
- [ ] Provide semantic labels for all interactive widgets
- [ ] Ensure touch targets are at least 44x44 logical pixels
- [ ] Maintain sufficient color contrast (4.5:1 for text, 3:1 for UI)
- [ ] Support keyboard navigation
- [ ] Test with screen readers (TalkBack, VoiceOver)

### Code Quality
- [ ] Follow consistent naming conventions
- [ ] Document complex widget behavior
- [ ] Write widget tests for critical UI components
- [ ] Use meaningful widget and variable names

## Common Anti-Patterns

### Anti-Pattern 1: Unnecessary StatefulWidget

```dart
// ❌ BAD - StatefulWidget for simple toggle
class ToggleButton extends StatefulWidget {
  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: isOn,
      onChanged: (value) => setState(() => isOn = value),
    );
  }
}

// ✅ GOOD - State in controller
class ToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return Obx(() => Switch(
      value: controller.isOn.value,
      onChanged: (value) => controller.isOn.value = value,
    ));
  }
}
```

### Anti-Pattern 2: Missing Const Constructors

```dart
// ❌ BAD - Not const
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)

// ✅ GOOD - Const
const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

### Anti-Pattern 3: Inline Complex Widgets

```dart
// ❌ BAD - Complex widget inline
return Card(
  child: Column(
    children: [
      Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(...),
            Column(
              children: [
                Text(user.name),
                Text(user.email),
                // ... more complex UI
              ],
            ),
          ],
        ),
      ),
    ],
  ),
);

// ✅ GOOD - Extracted widget
return UserCard(user: user);
```

### Anti-Pattern 4: Missing Accessibility Labels

```dart
// ❌ BAD - No semantic label
IconButton(
  icon: Icon(Icons.favorite),
  onPressed: () => like(),
)

// ✅ GOOD - Tooltip provides label
Tooltip(
  message: 'Like',
  child: IconButton(
    icon: Icon(Icons.favorite),
    onPressed: () => like(),
  ),
)
```
