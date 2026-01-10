---
paths: lib/domain/entities/**/*.dart
---

# Entity Rules

## Pure Dart Classes

**Rule**: Entities must be pure Dart classes with no Flutter or external package dependencies.

```dart
// ✅ CORRECT: Pure Dart class
import 'package:equatable/equatable.dart';  // OK: Dart package

class User extends Equatable {
  final String id;
  final String name;
  
  const User({required this.id, required this.name});
  
  @override
  List<Object?> get props => [id, name];
}

// ❌ WRONG: Flutter dependency
import 'package:flutter/material.dart';  // NOT ALLOWED

class User {
  final Color avatarColor;  // Flutter type
}
```

## Immutability

**Rule**: All entity fields must be `final`.

```dart
// ✅ CORRECT
class User {
  final String id;
  final String name;
}

// ❌ WRONG
class User {
  String id;  // Mutable
  String name;
}
```

## Equality

**Rule**: Override `==` and `hashCode` or use Equatable.

```dart
// ✅ CORRECT: Using Equatable
class User extends Equatable {
  final String id;
  
  @override
  List<Object?> get props => [id];
}

// ✅ CORRECT: Manual override
class User {
  final String id;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}
```

## No Business Logic

**Rule**: Entities contain only data, no business logic.

```dart
// ✅ CORRECT: Pure data
class Order {
  final String id;
  final double total;
  final List<OrderItem> items;
}

// ❌ WRONG: Business logic in entity
class Order {
  double calculateDiscount() {  // Business logic
    // ...
  }
  
  bool canBeCancelled() {  // Business logic
    // ...
  }
}
```

Use cases should handle business logic, not entities.
