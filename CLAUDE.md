# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

bdd_flutter is a Dart CLI tool that generates Flutter/Dart test files from Gherkin `.feature` files. Users write BDD scenarios in `.feature` files, run `dart run bdd_flutter build`, and get three files next to each feature: a generated steps contract (`.bdd_steps.dart`), a steps file the user owns (`_steps.dart`, created once) and the generated tests (`.bdd_test.dart`).

## Common Commands

```bash
# Run package tests (not example — example uses flutter_test)
dart test

# Run the CLI locally against the example project
cd example && dart run bdd_flutter build

# Move a 1.x project (.bdd_scenarios.dart files) to 2.0
cd example && dart run bdd_flutter migrate

# Run BDD tests with formatted report
cd example && dart run bdd_flutter test

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
  → BDDController.generateFeatureTestCases()
    → ConfigParser.loadConfig()                       # .bdd_flutter/config.yaml
    → FeatureParser.parseFeature(filePath)            # cucumber_gherkin → GherkinDocument
      → GherkinMapper.toFeature(document, path)       # GherkinDocument → Feature model
    → StepsCatalog.of(feature)                        # distinct step patterns → StepMethods
    → StepsContractBuilder.build(...)                 # → .bdd_steps.dart (always rewritten)
    → TestFileBuilder.build(...)                      # → .bdd_test.dart (always rewritten)
    → StepsStubBuilder.build(...)                     # → _steps.dart (only if missing)
    → checkStepsFile(...)                             # warn about missing/unused steps
    → DartFormatCommand.formatFiles(...)              # SDK `dart format`, no dart_style dependency
```

`MigrateController.migrate()` reads a 1.x `.bdd_scenarios.dart` (`LegacyScenariosFile`, a brace/string-aware reader, no analyzer), maps its method bodies onto the new methods (`LegacyCodeMapper`, using 1.x naming in `LegacyNames`), writes the steps file with that code and renames the old file to `.bak`.

### Layers

- **`domain/`** — Feature, Rule, Scenario, ExamplesTable, Step, Background, Decorator, ValueType, StepPattern/StepSlot, StepMethod, FeatureFiles (paths and class names), BDDConfig
- **`infrastructure/parsers/`** — FeatureParser (wraps `cucumber_gherkin`), GherkinMapper (the only code that touches `cucumber_messages` types), ConfigParser
- **`infrastructure/steps/`** — StepPatternParser (takes quoted text, standalone numbers and `<column>` placeholders out of step text), columnTypes, StepsCatalog (one method per pattern key, names and parameters)
- **`infrastructure/builders/`** — StepsContractBuilder, StepsStubBuilder, TestFileBuilder, ScenarioSettings (test kind, skip, tags), stepArguments
- **`infrastructure/migration/`** — 1.x → 2.0 migration
- **`infrastructure/formatting/`** — CodeFormatter (`DartFormatCommand`, `NoFormatting` for tests)
- **`presentation/cli/`** — BDDCLI entry point, argument parsing
- **`presentation/controllers/`** — BDDController (build), MigrateController, BuildReport, steps file check
- **`presentation/reporter/`** — BDDTestRunner (CLI `test` command), BDDReportFormatter

### Step patterns

A step's pattern key is its text with slots replaced by type markers, plus `+docString`/`+dataTable`. Slots: `"quoted text"` → String; a bare `<column>` with a matching Examples column → type from the column; a standalone number that `num.parse(v).toString() == v` → num. Numbers next to letters, `:`, `$`, `%`, `,`, `/`, `-` stay text. Steps with the same key share one method regardless of keyword.

### Generated Code Pattern

```dart
// cart.bdd_steps.dart (generated)
abstract interface class ShoppingCartStepsContract {
  Future<void> iAddAtEach(num quantity, String item, num price);
}

// cart_steps.dart (user-owned)
class ShoppingCartSteps implements ShoppingCartStepsContract {
  late Cart cart;
  @override
  Future<void> iAddAtEach(num quantity, String item, num price) async => ...;
}

// cart.bdd_test.dart (generated)
test('Add', () async {
  final steps = ShoppingCartSteps();          // widget tests: ..tester = tester
  await steps.iAddAtEach(2, 'apple', 1.5);
});
```

Scenario Outlines generate a `group(scenarioName)` with one test per row; Rules generate `group('Rule: name')`.

### Decorators and tags

- `@unitTest` / `@widgetTest` — closest wins: scenario, rule, feature, then `generate_widget_tests`
- `@skip` — `skip: true`, also on Examples blocks
- Any other tag → `tags:` on the test (invalid `dart test` tag names are dropped)

### CLI Commands

- `build` — Rewrite generated files; create missing `_steps.dart`; skip features that still have a 1.x `.bdd_scenarios.dart` and no `_steps.dart`
- `migrate` — 1.x → 2.0
- `test` — Run tests with formatted Feature/Scenario report

### Config File

`.bdd_flutter/config.yaml`:
- `test_dir` (string, default `test/`) — where to scan for `.feature` files
- `generate_widget_tests` (bool, default true) — test kind for scenarios without a decorator
- `ignore_features` (list of paths to skip)
- `additional_imports` (list of imports added to new `_steps.dart` files)
- `steps_suffix` (string, default `Steps`) — steps class suffix
- `scenario_suffix` — 1.x only, read by `migrate`

## Coding Conventions

- Use PascalCase for classes, camelCase for variables/functions, underscore_case for files
- Always declare explicit types; avoid `dynamic`
- One export per file
- Functions should be <20 lines with a single purpose
- Prefer composition over inheritance
- Use early returns to avoid deep nesting
- Follow Arrange-Act-Assert for tests
