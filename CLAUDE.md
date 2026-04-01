# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

bdd_flutter is a Dart CLI tool that generates Flutter/Dart test files from Gherkin `.feature` files. Users write BDD scenarios in `.feature` files, run `dart run bdd_flutter build`, and get `.bdd_scenarios.dart` (step stubs) and `.bdd_test.dart` (runnable tests) files generated alongside the feature file.

## Common Commands

```bash
# Run package tests (not example — example uses flutter_test)
dart test test/parsers/ test/builders/

# Run the CLI locally against the example project
cd example && dart run bdd_flutter build

# Run BDD tests with formatted report
cd example && dart run bdd_flutter test

# Force regenerate all
cd example && dart run bdd_flutter build --force

# Analyze code
dart analyze

# Get dependencies
dart pub get
```

## Architecture

Clean Architecture in `lib/src/`. The CLI entry point is `bin/bdd_flutter.dart`.

### Code Generation Pipeline

```
BDDCLI.run(args)
  → BDDController.generateFeatureTestCases(options)
    → ConfigParser.loadConfig()                      # .bdd_flutter/config.yaml
    → ManifestParser.loadManifest()                  # .bdd_flutter/manifest.yaml
    → FeatureParser.parseFeature(filePath)            # .feature → Feature model
    → ScenariosFileBuilder.buildScenarioFile(feature) # Feature → .bdd_scenarios.dart
    → TestFileBuilder.buildTestFile(feature)          # Feature → .bdd_test.dart
    → ManifestParser.saveManifest()                  # update manifest
```

### Layers

- **`domain/`** — Core models: Feature, Scenario, Step, Decorator, Background, BDDConfig, Manifest, BuildOptions
- **`infrastructure/parsers/`** — FeatureParser, ConfigParser, ManifestParser
- **`infrastructure/builders/`** — ScenariosFileBuilder, TestFileBuilder (domain models → Dart code)
- **`presentation/cli/`** — BDDCLI entry point, argument parsing
- **`presentation/controllers/`** — BDDController orchestrates config, manifest, parsing, building
- **`presentation/reporter/`** — BDDTestRunner (CLI `test` command), BDDReportFormatter (output formatting), BDDTestReporter (legacy, exported)

### Domain Models

- **Feature** — name, path, scenarios, decorators, optional background
- **Scenario** — name, steps, optional examples table, decorators, optional customClassName
- **Step** — keyword (Given/When/Then/And) + text with `<param>` placeholders
- **Decorator** — enum: `unitTest`, `widgetTest`
- **Background** — shared setup steps applied to all scenarios in a feature
- **BDDConfig** — generate_widget_tests, enable_reporter, ignore_features
- **Manifest** — tracks generated features, scenario hashes for incremental builds
- **BuildOptions** — CLI flags: widgetTest, reporter, force, newOnly

### Generated Code Pattern

Scenario classes use **instance methods** (not static), so users can add `late` fields for shared state between steps:

```dart
// .bdd_scenarios.dart
class IncrementScenario {
  Future<void> iHaveACounter(WidgetTester tester) async { ... }
  Future<void> iIncrementIt(WidgetTester tester) async { ... }
}

// .bdd_test.dart
final scenario = IncrementScenario();
await scenario.iHaveACounter(tester);
```

### Generation Modes

- **Incremental (default)** — compares scenario hashes against manifest, skips unchanged, appends new scenarios
- **Force (`--force`)** — regenerates everything

### Decorators

- `@unitTest` / `@widgetTest` — on feature or scenario (scenario overrides feature)
- Feature files only contain behavior-relevant tags; tooling config lives in `.bdd_flutter/config.yaml`

### CLI Commands

- `build` — Generate test files (incremental by default)
- `build --force` — Regenerate all files regardless of changes
- `test` — Run BDD tests with formatted Feature/Scenario report

### Config File

`.bdd_flutter/config.yaml`:
- `test_dir` (string, default `test/`) — where to scan for `.feature` files
- `generate_widget_tests` (bool, default true)
- `ignore_features` (list of paths to skip)
- `additional_imports` (list of imports added to every generated `_scenarios.dart`)
- `scenario_suffix` (string, default `Scenario`) — class name suffix (e.g., `Steps`)

### Manifest File

`.bdd_flutter/manifest.yaml` — auto-generated, tracks per-feature paths, timestamps, and scenario hashes for incremental builds.

## Coding Conventions

- Use PascalCase for classes, camelCase for variables/functions, underscore_case for files
- Always declare explicit types; avoid `dynamic`
- One export per file
- Functions should be <20 lines with a single purpose
- Prefer composition over inheritance
- Use early returns to avoid deep nesting
- Follow Arrange-Act-Assert for tests
