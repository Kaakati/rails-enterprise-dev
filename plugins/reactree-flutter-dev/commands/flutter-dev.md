---
name: flutter-dev
description: |
  Primary Flutter development workflow with GetX and Clean Architecture.
  Multi-agent orchestration with quality gates.
color: green
allowed-tools: ["*"]
---

# Flutter Development Workflow

You are initiating the **primary Flutter development workflow** powered by multi-agent orchestration with Clean Architecture and GetX.

## Development Philosophy

**Clean Architecture + GetX means:**
1. **Layer separation** - Domain → Data → Presentation
2. **Dependency inversion** - Depend on abstractions, not concretions
3. **Reactive state** - Use GetX `.obs` for reactive UI
4. **Quality gates** - Dart analysis, test coverage, build validation
5. **Testability** - Mock dependencies, test all layers

## Usage

```
/flutter-dev [your feature request]
```

## Examples

**Authentication & Authorization:**
```
/flutter-dev add JWT authentication with login/logout
/flutter-dev implement Google OAuth login
/flutter-dev create role-based access control
```

**API Integration:**
```
/flutter-dev create user management API with CRUD operations
/flutter-dev add product catalog with search and pagination
/flutter-dev implement real-time chat with WebSocket
```

**Offline-First Features:**
```
/flutter-dev implement offline-first notes app with sync
/flutter-dev add offline product catalog with GetStorage
/flutter-dev create cache-first user profile
```

**State Management:**
```
/flutter-dev add shopping cart with GetX state
/flutter-dev implement multi-step form with validation
/flutter-dev create global theme controller
```

## Workflow Activation

When user invokes `/flutter-dev [feature description]`, you MUST:

1. **Invoke workflow-orchestrator agent** immediately
2. Pass full feature description to orchestrator
3. Let orchestrator manage the entire 6-phase workflow
4. Do NOT attempt to implement directly

**Example invocation**:
```
User: /flutter-dev add user authentication with JWT
Assistant: I'll invoke the workflow orchestrator to handle this feature.

<invoke name="Task">
<parameter name="subagent_type">workflow-orchestrator</parameter>
<parameter name="description">User authentication feature</parameter>
<parameter name="prompt">
Implement user authentication feature with the following requirements:
- JWT token-based authentication
- Login and logout functionality
- Token storage with GetStorage
- Token refresh mechanism
- Protected routes

Please execute the 6-phase workflow:
1. Understand requirements
2. Inspect existing codebase patterns
3. Plan Clean Architecture implementation
4. Execute: Domain → Data → Presentation
5. Run quality gates (analyze, test, build)
6. Validate and report

Use TodoWrite for task tracking.
</parameter>
</invoke>
```

## Development Principles

1. **Clean Architecture First**: Always respect layer boundaries
2. **Test-Driven**: Write tests alongside implementation
3. **Quality Gates**: All gates must pass before completion
4. **GetX Best Practices**: Use bindings, reactive state, proper DI
5. **Offline-First**: Consider offline scenarios for data features

## Quality Expectations

- ✅ Dart analyze: 0 errors
- ✅ Test coverage: ≥ 80%
- ✅ Build: Succeeds
- ✅ GetX compliance: Bindings, reactive state, DI
- ✅ Clean Architecture: Layer separation, dependency flow

---

**Remember**: This command delegates to workflow-orchestrator. Do NOT implement features directly.
