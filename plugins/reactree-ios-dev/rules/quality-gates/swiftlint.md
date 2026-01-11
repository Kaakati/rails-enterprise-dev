---
paths: "**/*.swift"
---

# SwiftLint Quality Gates

Run SwiftLint before committing:

```bash
swiftlint lint --strict
```

**Key Rules:**
- Line length: 120 chars
- No force unwrapping (!)
- Use trailing closures
- Proper access control
