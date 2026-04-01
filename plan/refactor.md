# Refactoring Plan: bdd_flutter CLI

## Context

The project was rewritten from a `build_runner`-based approach to a CLI tool. The new clean architecture lives in `lib/src/` but only has basic parsing and generation. The README documents a full-featured CLI with config files, manifest tracking, incremental builds, multiple flags, and several decorators — most of which are not yet implemented.

**Goal**: Bring `lib/src/` to feature parity with what the README promises, iteratively.

## Design Decision: Instance-Based Scenario Classes

Change from static methods to instance methods, one class per scenario:

```dart
// _scenarios.dart
class IncrementScenario {
  Future<void> iHaveACounterWithValue0(WidgetTester tester) async {
    // TODO: Implement
  }
  Future<void> iIncrementTheCounterBy(WidgetTester tester, String value) async {
    // TODO: Implement
  }
}

// _test.dart
testWidgets('Increment', (tester) async {
  final scenario = IncrementScenario();
  await scenario.iHaveACounterWithValue0(tester);
  await scenario.iIncrementTheCounterBy(tester, '1');
});
```

**Why instance over static:**
- Users can add `late` fields to share state between steps (mocks, widgets, counters)
- Each test gets a fresh instance — proper test isolation
- No global state or parameter threading needed for complex cases

## Gap Analysis

| Feature | Status |
|---------|--------|
| Parse .feature files (Feature, Scenario, Given/When/Then) | Done |
| Background support | Done |
| Examples table | Done |
| @unitTest / @widgetTest decorators | Done |
| @enableReporter decorator | Done |
| `And` step keyword | **Missing** |
| @ignore decorator | **Missing** |
| @className("Name") decorator | **Missing** |
| @disableReporter decorator | **Missing** |
| Feature-level decorator inheritance to scenarios | **Missing** |
| CLI argument parsing (build/rename commands, flags) | **Missing** |
| --widget-test, --reporter, --force, --new-only flags | **Missing** |
| Config file (.bdd_flutter/config.yaml) | **Missing** |
| Manifest tracking (.bdd_flutter/manifest.yaml) | **Missing** |
| Incremental generation (default mode) | **Missing** |
| Force regeneration mode | **Missing** |
| New-only generation mode | **Missing** |
| `rename` command (remove .bdd_ prefix) | **Missing** |
| ignore_features filtering | **Missing** |
| Remove debug print() statements | **Missing** |
| Unit tests | **Missing** (test/ dirs are empty) |

---

## Iteration 1: Core Pipeline Works End-to-End

**Goal**: `dart run bdd_flutter build` parses any .feature file and generates correct instance-based _scenarios.dart and _test.dart files. Basic `build` command works with no flags.

### 1.1 Fix FeatureParser — `lib/src/infrastructure/parsers/feature_parser.dart`
- Add `And` step keyword support
- Remove debug `print()` statement (line 131)

### 1.2 Update ScenariosFileBuilder — `lib/src/infrastructure/builders/scenario_file_builder.dart`
- Change from static methods to instance methods (drop `static` keyword)
- Background class also instance-based

### 1.3 Update TestFileBuilder — `lib/src/infrastructure/builders/test_file_builder.dart`
- Instantiate scenario: `final scenario = IncrementScenario();`
- Call `scenario.step(tester, ...)` instead of `IncrementScenario.step(tester, ...)`
- Background: `final background = {FeatureName}Background();` instantiated per test
- Remove debug `print()` statements (lines 64-65)

### 1.4 Basic CLI — `lib/src/presentation/cli/bbd_cli.dart`
- Parse `build` command (just route to controller, no flags yet)

### 1.5 Tests for Iteration 1
- `test/parsers/feature_parser_test.dart` — basic features, scenarios, steps, And, Background, Examples
- `test/builders/scenario_file_builder_test.dart` — instance methods, params, Background
- `test/builders/test_file_builder_test.dart` — instantiation, widget vs unit, examples loop

### Verification
- `dart run bin/bdd_flutter.dart build` generates correct output for all example .feature files
- `dart analyze` passes
- `flutter test` at package root passes

---

## Iteration 2: Decorators & CLI Flags

**Goal**: All decorators work. CLI accepts flags that override defaults.

### 2.1 Add missing decorators — `lib/src/domain/decorator.dart`
- Add `ignore`, `className`, `disableReporter` to enum
- `@className("Name")` parses the argument string
- Update `fromString()` for new patterns

### 2.2 Update FeatureParser for new decorators
- Parse `@ignore`, `@className("Name")`, `@disableReporter`

### 2.3 Feature-level decorator inheritance — `lib/src/domain/scenario.dart`
- Scenario decorators override feature-level; fall back to feature if absent
- Builders pass feature decorators context

### 2.4 Update builders for decorators
- `@className` overrides scenario class name
- `@ignore` skips generation for that feature/scenario
- `@disableReporter` support

### 2.5 CLI flags — `lib/src/presentation/cli/bbd_cli.dart`
- Parse flags: `--widget-test`, `--reporter`, `--force`, `--new-only`
- Create `lib/src/domain/build_options.dart` to encapsulate options
- Pass options to controller

### 2.6 Tests for Iteration 2
- Decorator parsing tests (all types including @className)
- Builder tests for @className, @ignore
- Feature-level inheritance tests

### Verification
- Decorators in example .feature files produce correct output
- `dart run bdd_flutter build --widget-test` works
- `dart analyze` and `flutter test` pass

---

## Iteration 3: Config File & Manifest Tracking

**Goal**: Config file drives defaults. Manifest enables incremental generation. Three generation modes work.

### 3.1 Config model & parser
- New file `lib/src/domain/config.dart`
- New file `lib/src/infrastructure/parsers/config_parser.dart`
- Read `.bdd_flutter/config.yaml` using `yaml` package
- Create default config if missing

### 3.2 Manifest model & parser/writer
- New file `lib/src/domain/manifest.dart`
- New file `lib/src/infrastructure/parsers/manifest_parser.dart`
- Track per-feature: path, last modified, scenario hashes
- Read/write `.bdd_flutter/manifest.yaml`

### 3.3 Refactor BDDController — `lib/src/presentation/controllers/bdd_controller.dart`
- Load config, merge with CLI flags (CLI overrides config)
- Filter out `ignore_features` from config
- Implement generation modes:
  - **Default (incremental)**: check manifest, only regenerate changed features
  - **Force (`--force`)**: regenerate everything
  - **New-only (`--new-only`)**: only generate for features not in manifest
- Update manifest after generation

### 3.4 Tests for Iteration 3
- Config parser: defaults, custom values, missing file
- Manifest parser: read/write round-trip, change detection
- Controller: incremental vs force vs new-only behavior

### Verification
- `dart run bdd_flutter build` only regenerates changed files
- `dart run bdd_flutter build --force` regenerates all
- `dart run bdd_flutter build --new-only` skips existing
- Config file options are respected
- `dart analyze` and `flutter test` pass

---

## Iteration 4: Rename Command & Polish

**Goal**: `rename` command works. Clean up, final docs.

### 4.1 Rename command
- `dart run bdd_flutter rename` strips `.bdd_` prefix from generated files
- Add to CLI parser and controller

### 4.2 Cleanup
- Remove all remaining debug `print()` statements
- Update CLAUDE.md to reflect final architecture
- Update README if needed

### 4.3 Final verification
- All commands work end-to-end against example project
- `dart analyze` — no issues
- `flutter test` — all tests pass

---

## Files to Modify

| File | Iteration |
|------|-----------|
| `lib/src/infrastructure/parsers/feature_parser.dart` | 1, 2 |
| `lib/src/infrastructure/builders/scenario_file_builder.dart` | 1, 2 |
| `lib/src/infrastructure/builders/test_file_builder.dart` | 1, 2 |
| `lib/src/presentation/cli/bbd_cli.dart` | 1, 2, 4 |
| `lib/src/presentation/controllers/bdd_controller.dart` | 2, 3, 4 |
| `lib/src/domain/decorator.dart` | 2 |
| `lib/src/domain/scenario.dart` | 2 |
| `lib/src/domain/feature.dart` | 2 |

## New Files

| File | Iteration |
|------|-----------|
| `test/parsers/feature_parser_test.dart` | 1 |
| `test/builders/scenario_file_builder_test.dart` | 1 |
| `test/builders/test_file_builder_test.dart` | 1 |
| `lib/src/domain/build_options.dart` | 2 |
| `lib/src/domain/config.dart` | 3 |
| `lib/src/domain/manifest.dart` | 3 |
| `lib/src/infrastructure/parsers/config_parser.dart` | 3 |
| `lib/src/infrastructure/parsers/manifest_parser.dart` | 3 |
