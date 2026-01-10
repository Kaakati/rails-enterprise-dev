---
paths: lib/presentation/**/*.dart
---

# GetX Compliance Rules

## 1. Controllers Use Bindings

Controllers must be registered in bindings, not instantiated directly.

```bash
# This should return 0 results
grep -r "Get.put<.*Controller>" lib/presentation/pages/
```

## 2. Reactive Variables

All state must use `.obs` for reactivity.

## 3. No Business Logic

Controllers call use cases, not repositories.

```bash
# This should return 0 results
grep -r "Repository" lib/presentation/controllers/
```
