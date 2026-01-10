---
paths: test/**/*.dart
---

# Test Coverage Rules

## Minimum Coverage

**80% line coverage required**

```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

## Test All Layers

- Domain: Use cases
- Data: Repositories, models
- Presentation: Controllers

## Test Quality

- Use mocks for dependencies
- Test success AND error cases
- Test edge cases
- Include assertions
