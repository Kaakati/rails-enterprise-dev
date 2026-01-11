---
paths: "**/*.swift"
---

# Build Validation

Ensure clean builds:

```bash
xcodebuild clean build -scheme AppScheme -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Validation:**
- Zero build errors
- Warnings < 10
- CocoaPods integrated
