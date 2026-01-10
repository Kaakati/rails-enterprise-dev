---
paths: "**/*.dart"
---

# Dart Analysis Rules

## Run Before Commit

```bash
flutter analyze
```

**Pass criteria**: 0 errors

## Configure analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
  
  errors:
    invalid_annotation_target: ignore
    missing_required_param: error
    missing_return: error
    
linter:
  rules:
    - prefer_const_constructors
    - avoid_print
    - prefer_single_quotes
```

## Fix Before Proceeding

All analysis errors must be fixed before moving to next phase.
