---
name: Accessibility Quality Gate
paths:
  - lib/**/*.dart
description: Accessibility validation rules to ensure WCAG 2.2 Level AA compliance for inclusive applications
---

# Accessibility Quality Gate

Validation rules to ensure Flutter applications meet WCAG 2.2 Level AA accessibility standards.

## WCAG 2.2 Level AA Requirements

### Perceivable
- Text alternatives for non-text content
- Color contrast: 4.5:1 for normal text, 3:1 for large text
- UI component contrast: 3:1 minimum
- Content can be resized to 200% without loss of functionality

### Operable
- All functionality available via keyboard
- Touch targets: Minimum 44x44 logical pixels
- Clear focus indicators
- No keyboard traps

### Understandable
- Content language declared
- Consistent navigation and identification
- Input labels and error identification

### Robust
- Compatible with assistive technologies
- Status messages announced to screen readers

## Validation Rules

### Rule 1: Interactive Widgets Must Have Semantic Labels

**Validation**: All buttons, icons, and interactive elements must have semantic labels

**✅ PASS**:
```dart
// Using Semantics
Semantics(
  label: 'Add to cart',
  hint: 'Double tap to add product to cart',
  button: true,
  child: IconButton(
    icon: Icon(Icons.add_shopping_cart),
    onPressed: () => addToCart(),
  ),
)

// Using Tooltip (automatic semantic label)
Tooltip(
  message: 'Add to cart',
  child: IconButton(
    icon: Icon(Icons.add_shopping_cart),
    onPressed: () => addToCart(),
  ),
)
```

**❌ FAIL**:
```dart
// No semantic label
IconButton(
  icon: Icon(Icons.add_shopping_cart),
  onPressed: () => addToCart(),
)
```

**Detection**: Scan for IconButton, GestureDetector, InkWell without Semantics or Tooltip.

### Rule 2: Touch Targets Must Be At Least 44x44 Logical Pixels

**Validation**: All interactive widgets must meet minimum size requirements

**✅ PASS**:
```dart
// IconButton default size is 48x48
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
    child: Icon(Icons.check),
  ),
)
```

**❌ FAIL**:
```dart
// Touch target too small
GestureDetector(
  onTap: () => toggle(),
  child: Icon(Icons.check, size: 16), // Only 16x16
)

// Small button without padding
TextButton(
  onPressed: () {},
  style: TextButton.styleFrom(
    padding: EdgeInsets.all(2), // Too small
    minimumSize: Size(20, 20), // Below minimum
  ),
  child: Text('X'),
)
```

**Detection**: Check widget sizes and padding to ensure combined size ≥ 44x44.

### Rule 3: Text Must Have Sufficient Color Contrast

**Validation**: Text and UI components must meet contrast requirements

**✅ PASS**:
```dart
// Normal text - 4.5:1 contrast minimum
Text(
  'Normal text',
  style: TextStyle(
    color: Color(0xFF212121), // 16.1:1 on white ✓
    fontSize: 16,
  ),
)

// Large text - 3:1 contrast minimum
Text(
  'Large heading',
  style: TextStyle(
    color: Color(0xFF767676), // 4.6:1 on white ✓
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
)

// UI components - 3:1 contrast minimum
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: Color(0xFF757575), // 3:1 on white ✓
      ),
    ),
  ),
)
```

**❌ FAIL**:
```dart
// Insufficient contrast
Text(
  'Low contrast',
  style: TextStyle(
    color: Color(0xFFCCCCCC), // 1.6:1 on white ✗
  ),
)

TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: Color(0xFFE0E0E0), // < 3:1 ✗
      ),
    ),
  ),
)
```

**Contrast Requirements**:
- Normal text (< 24px): ≥ 4.5:1
- Large text (≥ 24px or ≥ 18px bold): ≥ 3:1
- UI components (borders, icons): ≥ 3:1

### Rule 4: Form Fields Must Have Labels

**Validation**: All input fields must have accessible labels

**✅ PASS**:
```dart
// TextField with label
TextField(
  decoration: InputDecoration(
    labelText: 'Email', // Provides semantic label
    hintText: 'name@example.com',
  ),
)

// TextFormField with label
TextFormField(
  decoration: InputDecoration(
    labelText: 'Password',
    helperText: 'Must be at least 8 characters',
  ),
  validator: (value) {
    if (value == null || value.length < 8) {
      return 'Password too short';
    }
    return null;
  },
)
```

**❌ FAIL**:
```dart
// Only hint text (not a label)
TextField(
  decoration: InputDecoration(
    hintText: 'Enter email', // Not a label
  ),
)

// No label at all
TextField()
```

**Detection**: Check TextField/TextFormField for labelText in InputDecoration.

### Rule 5: Status Changes Must Be Announced

**Validation**: Dynamic content changes must announce to screen readers

**✅ PASS**:
```dart
Future<void> submitForm() async {
  isSubmitting.value = true;

  // Announce loading state
  SemanticsService.announce(
    'Submitting form',
    TextDirection.ltr,
  );

  final result = await repository.submit();

  result.fold(
    (failure) {
      SemanticsService.announce(
        'Error: ${failure.message}',
        TextDirection.ltr,
      );
    },
    (success) {
      SemanticsService.announce(
        'Form submitted successfully',
        TextDirection.ltr,
      );
    },
  );

  isSubmitting.value = false;
}
```

**❌ FAIL**:
```dart
// Silent updates
Future<void> submitForm() async {
  isSubmitting.value = true;
  final result = await repository.submit();
  // No announcement
  isSubmitting.value = false;
}
```

**Detection**: Check for state changes without SemanticsService.announce() calls.

### Rule 6: Focus Order Must Be Logical

**Validation**: Tab order should follow visual order (top to bottom, left to right)

**✅ PASS**:
```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: NumericFocusOrder(1.0),
        child: TextField(decoration: InputDecoration(labelText: 'First')),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(2.0),
        child: TextField(decoration: InputDecoration(labelText: 'Second')),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(3.0),
        child: ElevatedButton(onPressed: () {}, child: Text('Submit')),
      ),
    ],
  ),
)
```

**❌ FAIL**:
```dart
// Random focus order
Column(
  children: [
    TextField(), // Focus order unclear
    ElevatedButton(),
    TextField(),
  ],
)
```

### Rule 7: Images Must Have Alternative Text

**Validation**: All meaningful images must have semantic descriptions

**✅ PASS**:
```dart
Semantics(
  label: 'Product: Blue cotton shirt',
  image: true,
  child: Image.network(product.imageUrl),
)

// Decorative images excluded
ExcludeSemantics(
  child: Image.asset('assets/decorative_border.png'),
)
```

**❌ FAIL**:
```dart
// Meaningful image without description
Image.network(product.imageUrl)
```

### Rule 8: Focus Indicators Must Be Visible

**Validation**: Focused elements must have clear visual indicators

**✅ PASS**:
```dart
Focus(
  child: Builder(
    builder: (context) {
      final isFocused = Focus.of(context).hasFocus;
      return Container(
        decoration: BoxDecoration(
          border: isFocused
              ? Border.all(color: Colors.blue, width: 3) // Visible
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: () {},
          child: Text('Button'),
        ),
      );
    },
  ),
)
```

**❌ FAIL**:
```dart
// No focus indicator
ElevatedButton(
  style: ElevatedButton.styleFrom(
    focusColor: Colors.transparent, // Invisible
  ),
  onPressed: () {},
  child: Text('Button'),
)
```

### Rule 9: Adequate Spacing Between Touch Targets

**Validation**: Interactive elements must have at least 8px spacing

**✅ PASS**:
```dart
Row(
  spacing: 16, // Adequate spacing
  children: [
    IconButton(icon: Icon(Icons.edit), onPressed: () => edit()),
    IconButton(icon: Icon(Icons.delete), onPressed: () => delete()),
  ],
)
```

**❌ FAIL**:
```dart
Row(
  spacing: 2, // Too close
  children: [
    IconButton(icon: Icon(Icons.edit), onPressed: () => edit()),
    IconButton(icon: Icon(Icons.delete), onPressed: () => delete()),
  ],
)
```

### Rule 10: No Keyboard Traps

**Validation**: Users must be able to navigate away from all elements

**✅ PASS**:
```dart
// Dialog with proper focus management
class AccessibleDialog extends StatefulWidget {
  @override
  State<AccessibleDialog> createState() => _AccessibleDialogState();
}

class _AccessibleDialogState extends State<AccessibleDialog> {
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusScopeNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusScopeNode,
      child: AlertDialog(
        title: Text('Confirm'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Can escape
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), // Can escape
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
```

**❌ FAIL**:
```dart
// Modal without escape mechanism
AlertDialog(
  title: Text('Locked Dialog'),
  // No dismiss action
  content: Text('Cannot escape'),
)
```

## Automated Accessibility Checks

### Semantic Debugger

Enable during development:

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showSemanticsDebugger: true, // Visualize semantic tree
      home: HomePage(),
    );
  }
}
```

### Testing

```dart
testWidgets('Button has semantic label', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Tooltip(
          message: 'Submit form',
          child: IconButton(
            icon: Icon(Icons.send),
            onPressed: () {},
          ),
        ),
      ),
    ),
  );

  // Verify semantic label exists
  expect(
    tester.getSemantics(find.byType(IconButton)),
    matchesSemantics(
      label: 'Submit form',
      isButton: true,
    ),
  );
});

testWidgets('Touch target meets minimum size', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: IconButton(
        icon: Icon(Icons.close),
        onPressed: () {},
      ),
    ),
  );

  final size = tester.getSize(find.byType(IconButton));
  expect(size.width, greaterThanOrEqualTo(44));
  expect(size.height, greaterThanOrEqualTo(44));
});
```

## Quality Gate Checklist

Before merging:

- [ ] All interactive widgets have semantic labels
- [ ] All touch targets ≥ 44x44 logical pixels
- [ ] Text contrast ≥ 4.5:1 (normal), ≥ 3:1 (large)
- [ ] UI component contrast ≥ 3:1
- [ ] All form fields have labels
- [ ] Status changes announced to screen readers
- [ ] Focus order is logical
- [ ] All meaningful images have alt text
- [ ] Focus indicators are visible
- [ ] Adequate spacing between touch targets (≥ 8px)
- [ ] No keyboard traps
- [ ] Tested with TalkBack (Android)
- [ ] Tested with VoiceOver (iOS)
- [ ] Semantic debugger shows correct tree structure

## Platform-Specific Testing

### Android TalkBack

```bash
# Enable TalkBack
adb shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService

# Navigate with D-pad
# Swipe right: Next element
# Swipe left: Previous element
# Double tap: Activate
```

### iOS VoiceOver

```bash
# Enable VoiceOver in Simulator
# Settings > Accessibility > VoiceOver

# Shortcuts:
# Swipe right: Next element
# Swipe left: Previous element
# Double tap: Activate
# Three-finger swipe: Scroll
```

## Common Accessibility Issues

### Issue 1: Missing Semantic Labels

**Symptom**: Screen reader says "Button" without context

**Fix**: Add Tooltip or Semantics widget with descriptive label

### Issue 2: Small Touch Targets

**Symptom**: Users miss buttons on touch

**Fix**: Ensure minimum 44x44 size, add padding

### Issue 3: Low Contrast Text

**Symptom**: Text hard to read in certain lighting

**Fix**: Use darker colors meeting 4.5:1 ratio

### Issue 4: Silent State Changes

**Symptom**: Screen reader users don't know when content updates

**Fix**: Use SemanticsService.announce() for important changes

### Issue 5: Keyboard Traps

**Symptom**: Cannot navigate away from modal

**Fix**: Add dismiss actions, proper focus management
