---
name: flutter-init
description: Initialize Flutter project with ReactTree Flutter Dev patterns, skills, rules, and agents
allowed-tools: ["*"]
---

# Flutter Project Initialization Command

Initialize a Flutter project with ReactTree Flutter Dev patterns, copying selected skills, rules, and agents to the project's `.claude/` directory and setting up the recommended Clean Architecture structure.

## Usage

```
/flutter-init [options]
```

### Options

- `--minimal`: Copy only essential skills and rules (flutter-conventions, clean-architecture-patterns, getx-patterns)
- `--full`: Copy all skills, rules, and agents to project (recommended for new projects)
- `--custom`: Interactive selection of which skills, rules, and agents to copy
- `--structure-only`: Create directory structure without copying files

**Default**: Interactive mode (asks questions if no option provided)

## Examples

```
/flutter-init
/flutter-init --full
/flutter-init --minimal
/flutter-init --custom
/flutter-init --structure-only
```

## What This Command Does

This command sets up a Flutter project for development with ReactTree Flutter Dev by:

1. **Validating** the Flutter project environment
2. **Creating** `.claude/` directory structure for skills, rules, and agents
3. **Copying** selected skills, rules, and agents from plugin to project
4. **Generating** quality gate configuration
5. **Creating** Clean Architecture directory structure in `lib/`
6. **Creating** initial boilerplate files (failures, exceptions, main.dart)
7. **Updating** `pubspec.yaml` with required dependencies
8. **Reporting** what was set up and next steps

## Workflow Steps

### Step 1: Validation

Verify the environment is ready:

1. **Check for `pubspec.yaml`** - Ensures we're in a Flutter project root
2. **Verify Flutter version** - Check `flutter --version` for compatibility (Flutter 3.x+)
3. **Check required dependencies** - Verify if get, dartz, http, get_storage are in pubspec.yaml
4. **Detect existing `.claude/` directory** - Warn if already exists, offer to merge or overwrite

**Validation Checks**:
```bash
# Check 1: pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Error: pubspec.yaml not found. This doesn't appear to be a Flutter project."
  exit 1
fi

# Check 2: Flutter version
flutter --version | grep "Flutter 3"
if [ $? -ne 0 ]; then
  echo "⚠️  Warning: Flutter 3.x+ recommended. Current version may not support all features."
fi

# Check 3: Existing .claude/ directory
if [ -d ".claude" ]; then
  echo "⚠️  Warning: .claude/ directory already exists."
  # Ask user: Merge, Overwrite, or Cancel
fi
```

### Step 2: Interactive Setup

Ask the user to configure their setup (unless `--full` or `--minimal` is specified):

**Question 1: Architecture Choice**
```
Which architecture pattern do you want to use?

1. Clean Architecture (recommended)
   - Three-layer separation (Domain → Data → Presentation)
   - Dependency inversion principle
   - Testable and maintainable

2. Feature-first
   - Feature-based folder structure
   - Features are independent modules
   - Good for large teams

3. Layer-first
   - Traditional MVC-style layers
   - Simpler for small projects
   - Easy to understand for beginners

Your choice [1-3]: _
```

**Question 2: Skills to Copy**
```
Which skills should I copy to your project?

1. All skills (recommended) - 16 skills
   - Foundation: flutter-conventions, clean-architecture-patterns, core-layer-patterns
   - State: getx-patterns, advanced-getx-patterns
   - Data: repository-patterns, model-patterns, http-integration, get-storage-patterns
   - Presentation: navigation-patterns, accessibility-patterns
   - Quality: testing-patterns, performance-optimization, error-handling
   - i18n: internationalization-patterns
   - Cross-cutting: code-quality-gates

2. Core skills only - 8 essential skills
   - flutter-conventions
   - clean-architecture-patterns
   - getx-patterns
   - repository-patterns
   - model-patterns
   - http-integration
   - testing-patterns
   - code-quality-gates

3. Custom selection (I'll ask about each skill)

Your choice [1-3]: _
```

**Question 3: Rules to Enforce**
```
Which rules should I enforce in your project?

1. All rules (recommended) - 13 rules
   - Domain: entities.md, use-cases.md
   - Data: models.md, repositories.md
   - Presentation: controllers.md, bindings.md, navigation.md, widgets.md
   - Core: errors.md
   - Quality Gates: dart-analysis.md, test-coverage.md, getx-compliance.md, performance.md, accessibility.md

2. Essential rules only - 8 rules
   - Domain: entities.md, use-cases.md
   - Data: models.md, repositories.md
   - Presentation: controllers.md, bindings.md
   - Quality Gates: dart-analysis.md, test-coverage.md

3. Custom selection (I'll ask about each rule)

Your choice [1-3]: _
```

**Question 4: Project-Specific Agents**
```
Do you want to copy agents to your project?

Copying agents to .claude/agents/ allows you to customize them for your project.
If you don't copy them, the plugin's default agents will be used.

1. Yes, copy all 9 agents
   - workflow-orchestrator, codebase-inspector, flutter-planner
   - implementation-executor, domain-lead, data-lead
   - presentation-lead, test-oracle, quality-guardian

2. No, use plugin agents only (recommended for most projects)

Your choice [1-2]: _
```

### Step 3: Directory Creation

Create the `.claude/` directory structure:

```
.claude/
├── skills/           # Project-specific skills (user selected)
├── agents/           # Project-specific agents (optional)
├── rules/            # Project-specific rules (user selected)
└── config.json       # Quality gate configuration
```

Create the `lib/` Clean Architecture structure (if architecture choice is Clean Architecture):

```
lib/
├── core/
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── validators.dart
│   ├── config/
│   │   ├── app_config.dart
│   │   └── theme_config.dart
│   └── di/
│       └── injection_container.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── models/
│   ├── repositories/
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   └── sources/
└── presentation/
    ├── controllers/
    ├── bindings/
    ├── pages/
    ├── widgets/
    └── routes/
```

Create the `test/` directory structure:

```
test/
├── domain/
│   ├── entities/
│   └── usecases/
├── data/
│   ├── models/
│   └── repositories/
├── presentation/
│   ├── controllers/
│   └── widgets/
├── fixtures/
│   └── sample_data.json
└── helpers/
    └── test_helper.dart
```

### Step 4: Copy Files

Copy selected skills, rules, and agents from the plugin to the project.

**Skills Copying Logic**:
```bash
# Determine plugin path
PLUGIN_PATH="$HOME/.claude/plugins/reactree-flutter-dev"
if [ ! -d "$PLUGIN_PATH" ]; then
  echo "❌ Error: Plugin not found at $PLUGIN_PATH"
  exit 1
fi

# Copy selected skills
for skill in "${SELECTED_SKILLS[@]}"; do
  echo "Copying skill: $skill"
  cp -r "$PLUGIN_PATH/skills/$skill" ".claude/skills/$skill"
done
```

**Rules Copying Logic**:
```bash
# Copy selected rules (preserve directory structure)
for rule in "${SELECTED_RULES[@]}"; do
  echo "Copying rule: $rule"

  # Create parent directory if needed
  rule_dir=$(dirname "$rule")
  mkdir -p ".claude/rules/$rule_dir"

  # Copy rule file
  cp "$PLUGIN_PATH/rules/$rule" ".claude/rules/$rule"
done
```

**Agents Copying Logic** (if user selected to copy agents):
```bash
# Copy all agents
if [ "$COPY_AGENTS" = "yes" ]; then
  echo "Copying all agents to .claude/agents/"
  mkdir -p ".claude/agents"

  for agent in workflow-orchestrator codebase-inspector flutter-planner \
               implementation-executor domain-lead data-lead \
               presentation-lead test-oracle quality-guardian; do
    cp "$PLUGIN_PATH/agents/$agent.md" ".claude/agents/$agent.md"
  done
fi
```

### Step 5: Create Configuration

Generate `.claude/config.json` with quality gate settings:

```json
{
  "flutter": {
    "version": "3.x",
    "architecture": "clean",
    "quality_gates": {
      "dart_analysis": {
        "enabled": true,
        "severity": "error",
        "rules": ["avoid_print", "prefer_const_constructors"]
      },
      "test_coverage": {
        "enabled": true,
        "threshold": 80,
        "exclude": ["**/*.g.dart", "**/*.freezed.dart"]
      },
      "build_validation": {
        "enabled": true,
        "platforms": ["android", "ios"]
      },
      "getx_compliance": {
        "enabled": true,
        "check_reactive_state": true,
        "check_bindings": true,
        "check_navigation": true
      },
      "performance_checks": {
        "enabled": true,
        "check_const_constructors": true,
        "check_unnecessary_rebuilds": true,
        "check_image_optimization": true
      },
      "accessibility_checks": {
        "enabled": true,
        "check_semantic_labels": true,
        "check_touch_targets": true,
        "check_color_contrast": true
      }
    },
    "skills": [
      "flutter-conventions",
      "clean-architecture-patterns",
      "getx-patterns"
    ],
    "rules": [
      "domain/entities.md",
      "domain/use-cases.md",
      "data/repositories.md",
      "presentation/controllers.md",
      "presentation/bindings.md",
      "quality-gates/dart-analysis.md",
      "quality-gates/test-coverage.md"
    ]
  }
}
```

### Step 6: Create Initial Files

Generate boilerplate Dart files to get started:

**`lib/core/errors/failures.dart`**:
```dart
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation error occurred']) : super(message);
}
```

**`lib/core/errors/exceptions.dart`**:
```dart
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
```

**`lib/main.dart`** (with GetX setup):
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Welcome to Flutter with Clean Architecture!'),
      ),
    );
  }
}
```

### Step 7: Update pubspec.yaml

Add required dependencies if they're missing:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management & Navigation
  get: ^4.6.6

  # Local Storage
  get_storage: ^2.1.1

  # HTTP Client
  http: ^1.1.2

  # Functional Programming
  dartz: ^0.10.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Testing
  mocktail: ^1.0.3

  # Code Generation
  build_runner: ^2.4.8
  json_serializable: ^6.7.1

  # Linting
  flutter_lints: ^3.0.1
```

### Step 8: Final Report

Display a comprehensive summary of what was set up:

```
✅ Flutter project initialized successfully!

📁 Created directories:
  ✓ .claude/ (skills, rules, agents, config)
  ✓ lib/core/ (errors, utils, config, di)
  ✓ lib/domain/ (entities, repositories, usecases)
  ✓ lib/data/ (models, repositories, datasources/local, datasources/remote, sources)
  ✓ lib/presentation/ (controllers, bindings, pages, widgets, routes)
  ✓ test/ (domain, data, presentation, fixtures, helpers)

📋 Copied 8 skills:
  ✓ flutter-conventions
  ✓ clean-architecture-patterns
  ✓ getx-patterns
  ✓ repository-patterns
  ✓ model-patterns
  ✓ http-integration
  ✓ testing-patterns
  ✓ code-quality-gates

📏 Copied 8 rules:
  ✓ domain/entities.md
  ✓ domain/use-cases.md
  ✓ data/models.md
  ✓ data/repositories.md
  ✓ presentation/controllers.md
  ✓ presentation/bindings.md
  ✓ quality-gates/dart-analysis.md
  ✓ quality-gates/test-coverage.md

⚙️  Created configuration:
  ✓ .claude/config.json (quality gates configured)

📄 Created boilerplate files:
  ✓ lib/core/errors/failures.dart
  ✓ lib/core/errors/exceptions.dart
  ✓ lib/main.dart (GetX setup)

📦 Updated dependencies:
  ✓ get: ^4.6.6
  ✓ get_storage: ^2.1.1
  ✓ http: ^1.1.2
  ✓ dartz: ^0.10.1
  ✓ mocktail: ^1.0.3
  ✓ build_runner: ^2.4.8
  ✓ json_serializable: ^6.7.1

🎯 Next steps:

1. Install dependencies:
   $ flutter pub get

2. Run the app:
   $ flutter run

3. Start developing with ReactTree Flutter Dev:
   $ /flutter-dev add user authentication with JWT

4. Use specialized commands:
   - /flutter-feature - Feature-driven development
   - /flutter-debug - Debug existing issues
   - /flutter-refactor - Refactor code safely

5. Explore your skills:
   $ ls .claude/skills/

6. Review quality gates:
   $ cat .claude/config.json

Happy coding! 🚀
```

## Activation

When the user invokes `/flutter-init [options]`:

1. **Parse options** - Detect `--minimal`, `--full`, `--custom`, or `--structure-only`
2. **Run Step 1: Validation** - Check pubspec.yaml, Flutter version, existing .claude/
3. **Run Step 2: Interactive Setup** (if no `--minimal` or `--full` option)
   - Ask about architecture choice
   - Ask about skills to copy
   - Ask about rules to enforce
   - Ask about project-specific agents
4. **Run Step 3: Directory Creation** - Create `.claude/`, `lib/`, and `test/` structures
5. **Run Step 4: Copy Files** - Copy selected skills, rules, and agents
6. **Run Step 5: Create Configuration** - Generate `.claude/config.json`
7. **Run Step 6: Create Initial Files** - Generate failures.dart, exceptions.dart, main.dart
8. **Run Step 7: Update pubspec.yaml** - Add required dependencies
9. **Run Step 8: Final Report** - Show summary and next steps

## Integration with Other Commands

After running `/flutter-init`, users can immediately start using:

- `/flutter-dev [task]` - Main development workflow
- `/flutter-feature [description]` - Feature-driven development
- `/flutter-debug [issue]` - Debugging workflow
- `/flutter-refactor [target]` - Refactoring workflow

All commands will automatically discover the skills, rules, and agents that were copied to the project.

## Notes

- **Idempotent**: Safe to run multiple times (will warn if .claude/ exists)
- **Non-destructive**: Never overwrites files without asking
- **Flexible**: Can copy all, minimal, or custom selection of skills/rules
- **Portable**: Works with any Flutter 3.x+ project
- **Convention over configuration**: Uses sensible defaults with option to customize
- **Clean Architecture by default**: Sets up proper layer separation from day one

## Customization

After initialization, users can:
- Add custom skills to `.claude/skills/`
- Modify copied rules in `.claude/rules/`
- Customize agents in `.claude/agents/` (if copied)
- Adjust quality gates in `.claude/config.json`
- Extend directory structure as needed

## Troubleshooting

**"pubspec.yaml not found"**
- Ensure you're in the Flutter project root directory
- Run `flutter create my_app` to create a new project first

**"Plugin not found"**
- Install the plugin: Copy `reactree-flutter-dev/` to `~/.claude/plugins/`
- Or install via Claude Code plugin marketplace

**".claude/ already exists"**
- Choose to merge (keeps existing, adds new) or overwrite (replaces all)
- Backup existing `.claude/` directory before overwriting

**"Dependencies already exist"**
- The command only adds missing dependencies, won't duplicate existing ones
- Manually resolve version conflicts if needed
