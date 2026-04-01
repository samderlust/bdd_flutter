# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

bdd_flutter is a Dart CLI tool that generates Flutter/Dart test files from Gherkin `.feature` files. Users write BDD scenarios in `.feature` files, run `dart run bdd_flutter build`, and get `.bdd_scenarios.dart` (step stubs) and `.bdd_test.dart` (runnable tests) files generated alongside the feature file.

## Common Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/file_procesors/feature_parser_test.dart

# Run the CLI locally against the example project
dart run bin/bdd_flutter.dart build

# Analyze code
dart analyze

# Get dependencies
dart pub get
```

## Architecture

Clean Architecture in `lib/src2/`. The CLI entry point is `bin/bdd_flutter.dart`.

### Code Generation Pipeline

```
BDDCLI.run(args)
  → BDDController.generateFeatureTestCases()
    → FeatureParser.parseFeature(filePath)     # .feature → Feature model
    → ScenariosFileBuilder.buildScenarioFile()  # Feature → .bdd_scenarios.dart
    → TestFileBuilder.buildTestFile()           # Feature → .bdd_test.dart
```

### Layers

- **`domain/`** — Core models: Feature, Scenario, Step, Decorator, Background
- **`infrastructure/parsers/`** — FeatureParser (reads `.feature` files into domain models)
- **`infrastructure/builders/`** — ScenariosFileBuilder, TestFileBuilder (domain models → Dart code)
- **`presentation/cli/`** — BDDCLI entry point
- **`presentation/controllers/`** — BDDController orchestrates parsing and building

### Domain Models

- **Feature** — name, path, scenarios, decorators, optional background
- **Scenario** — name, steps, optional examples table, decorators
- **Step** — keyword (Given/When/Then/And) + text with `<param>` placeholders
- **Decorator** — enum: `unitTest`, `widgetTest`, `enableReporter`, `ignore`
- **Background** — shared setup steps applied to all scenarios in a feature

### Generated File Conventions

- `.bdd_scenarios.dart` — Static classes with step method stubs
- `.bdd_test.dart` — Executable test file using `test()` or `testWidgets()`
- `.feature` — Gherkin source files
- Generated files are placed alongside the `.feature` file

### CLI Flags

- `--widget-test` — Generate widget tests (uses `testWidgets` + `WidgetTester`)
- `--reporter` — Enable BDD test reporter
- `--force` — Regenerate all files regardless of changes
- `--new-only` — Only generate for new feature files

### Config File

User projects store config at `.bdd_flutter/config.yaml` with options: `generate_widget_tests`, `enable_reporter`, `ignore_features`.

## Coding Conventions

- Use PascalCase for classes, camelCase for variables/functions, underscore_case for files
- Always declare explicit types; avoid `dynamic`
- One export per file
- Functions should be <20 lines with a single purpose
- Prefer composition over inheritance
- Use early returns to avoid deep nesting
- Follow Arrange-Act-Assert for tests
