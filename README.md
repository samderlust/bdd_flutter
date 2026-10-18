# BDD Flutter

[![pub package](https://img.shields.io/pub/v/bdd_flutter.svg)](https://pub.dev/packages/bdd_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter package that simplifies Behavior Driven Development (BDD) by automatically generating test files from Gherkin feature files. Write expressive tests in plain English using Given/When/Then scenarios and let BDD Flutter handle the boilerplate code generation.

## Features

- Parses `.feature` files with the official Cucumber parser ([`cucumber_gherkin`](https://pub.dev/packages/cucumber_gherkin)), so the full Gherkin syntax and 70+ spoken languages work
- Generate boilerplate test files automatically
- Support for both widget tests and unit tests
- Incremental generation — new scenarios are appended without overwriting existing implementations
- Instance-based scenario classes for shared state between steps
- Background support for shared setup steps
- Examples tables for parameterized scenarios
- Configurable via `.bdd_flutter/config.yaml`
- Manifest tracking in `.bdd_flutter/manifest.yaml`

## Installation

Requires Dart 3.8 or later. Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  bdd_flutter: latest
```

## Quick Start

1. Create a `.feature` file in your test folder:

```gherkin
Feature: Counter
  Scenario: Increment
    Given I have a counter with value 0
    When I increment the counter by <value>
    Then the counter should have value <expected_value>
    Examples:
      | value | expected_value |
      | 1     | 1              |
      | 2     | 2              |
      | 3     | 3              |
```

2. Generate test files:

```bash
dart run bdd_flutter build
```

3. Implement the generated step methods in `counter.bdd_scenarios.dart`

4. Run your tests with BDD report:

```bash
dart run bdd_flutter test
```

Or run normally with `flutter test`.

## Generated Files

The generator creates two files per `.feature` file:

- **`.bdd_scenarios.dart`** — Scenario classes with step method stubs (your implementation goes here)
- **`.bdd_test.dart`** — Test orchestration file (auto-generated, do not edit)

### How It Works

- Scenario classes use **instance methods**, so you can add `late` fields for shared state (mocks, widgets, etc.)
- Each test instantiates a **fresh scenario** for proper test isolation
- When you add a new scenario to a `.feature` file, only the new scenario class is **appended** — existing implementations are preserved
- The test file is **always regenerated** (it contains no user code)

### Example Output

#### `counter.bdd_scenarios.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

class IncrementScenario {
  Future<void> iHaveACounterWithValue0(WidgetTester tester) async {
    // TODO: Implement Given I have a counter with value 0
  }

  Future<void> iIncrementTheCounterByValue(WidgetTester tester, String value) async {
    // TODO: Implement When I increment the counter by <value>
  }

  Future<void> theCounterShouldHaveValueExpectedValue(WidgetTester tester, String expectedValue) async {
    // TODO: Implement Then the counter should have value <expected_value>
  }
}
```

#### `counter.bdd_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'counter.bdd_scenarios.dart';

void main() {
  group('Counter', () {
    testWidgets('Increment', (tester) async {
      final scenario = IncrementScenario();
      final examples = [
        {'value': '1', 'expectedValue': '1'},
        {'value': '2', 'expectedValue': '2'},
        {'value': '3', 'expectedValue': '3'},
      ];
      for (var example in examples) {
        await scenario.iIncrementTheCounterByValue(tester, example['value']!);
        await scenario.theCounterShouldHaveValueExpectedValue(tester, example['expectedValue']!);
      }
    });
  });
}
```

## Configuration

Configure the generator in `.bdd_flutter/config.yaml`:

```yaml
# Where to scan for .feature files
test_dir: "test/"

# Generate widget tests or unit tests
generate_widget_tests: true

# Feature files to skip during generation
ignore_features:
  - test/features/login.feature
  - test/features/registration.feature

# Imports added to every generated .bdd_scenarios.dart file
additional_imports:
  - "package:mocktail/mocktail.dart"
  - "test/helpers/test_helpers.dart"

# Suffix for generated scenario class names (default: "Scenario")
# e.g., "Steps" → IncrementSteps instead of IncrementScenario
scenario_suffix: "Scenario"
```

Or use `--force` to regenerate everything:

```bash
dart run bdd_flutter build --force
```

### Config Options

| Option                  | Type   | Default      | Description                                              |
| ----------------------- | ------ | ------------ | -------------------------------------------------------- |
| `test_dir`              | String | `test/`      | Directory to scan for `.feature` files                   |
| `generate_widget_tests` | bool   | true         | Generate widget tests when true, unit tests when false   |
| `ignore_features`       | List   | []           | Feature file paths to skip during generation             |
| `additional_imports`    | List   | []           | Imports added to every generated scenario file           |
| `scenario_suffix`       | String | `Scenario`   | Class name suffix (e.g., `Steps` for `IncrementSteps`)  |

### CLI Flags

### Commands

| Command         | Description                                          |
| --------------- | ---------------------------------------------------- |
| `build`         | Generate test files from `.feature` files                        |
| `build --force` | Force regenerate all files (overwrites existing)                 |
| `test`          | Run all tests with formatted BDD and non-BDD reports             |

## Test Report

Running `dart run bdd_flutter test` discovers all test files in your project and produces a formatted report with two sections:

- **BDD Test Report** — `.bdd_test.dart` files grouped by Feature with Scenario pass/fail
- **Non-BDD Test Report** — regular `_test.dart` files grouped by file name and test group

### Example Output

```
Running 8 BDD + 1 regular test file(s)...

BDD Test Report
==================================================

  Feature: Calculator
    ✓ Add two numbers (170ms)
    ✓ Subtract two numbers (7ms)
    ✓ Multiply two numbers (4ms)
    ✓ Divide two numbers (4ms)

  Feature: Counter
    ✓ Increment (152ms)
    ✓ Decrement (6ms)

  Feature: Login
    ✓ Successful login (150ms)
    ✓ Failed login shows error (8ms)
    ✓ Logout after login (4ms)

Non-BDD Test Report
==================================================

  Test File: string_utils_test.dart
    capitalize
      ✓ capitalizes first letter (19ms)
      ✓ returns empty string for empty input (2ms)
      ✓ handles single character (1ms)
    add
      ✓ adds two positive numbers (2ms)
      ✓ adds negative numbers (3ms)
      ✓ adds zero (2ms)

──────────────────────────────────────────────────
  15 tests: 15 passed, 0 failed
  Time: 2781ms
```

## Gherkin Support

`.feature` files are parsed by [`cucumber_gherkin`](https://pub.dev/packages/cucumber_gherkin), the official Cucumber parser, and read through the [`cucumber_messages`](https://pub.dev/packages/cucumber_messages) data model.

| Syntax | How bdd_flutter uses it |
| --- | --- |
| `Given` / `When` / `Then` / `And` / `But` / `*` | One step method each |
| `Background:` | A `<Feature>Background` class, run before every scenario |
| `Scenario Outline:` and `Examples:` | One test that loops over every example row |
| Several `Examples:` blocks | Rows from all blocks are combined; columns can be in any order |
| `Rule:` | Its scenarios are generated like any other; a `Background:` inside a Rule runs as the first steps of each scenario in that Rule |
| Tags (`@unitTest @smoke`) | Several per line; tags on a Rule apply to its scenarios |
| Doc strings (`"""`) | Passed to the step method as `String docString` |
| Data tables | Passed to the step method as `List<List<String>> dataTable` (all rows, header row included) |
| `<column>` inside doc strings and tables | Replaced with the current example row's value |
| `# comments`, descriptions, `\|` in tables | Supported |
| `# language: fr` | Keywords in any [Gherkin language](https://cucumber.io/docs/gherkin/languages/) |

Invalid Gherkin is reported with line and column, and that file is skipped:

```
Failed: Invalid Gherkin in test/login/login.feature:
  (4:3): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, ..., got 'this line is not Gherkin'
```

**Not yet supported:**

- Dart identifiers are ASCII only, so letters such as `é` are dropped from generated names (`Incrémenter` → `IncrMenterScenario`).
- The Background runs once per test, so in a Scenario Outline all example rows share the state it sets up.

### Doc Strings and Data Tables

```gherkin
Scenario Outline: Send an order
  When I send the payload:
    """
    {"item": "<item>"}
    """
  Then the table shows:
    | item   | price   |
    | <item> | <price> |

  Examples:
    | item  | price |
    | apple | 1.50  |
```

generates

```dart
Future<void> iSendThePayload(String docString) async { ... }
Future<void> theTableShows(List<List<String>> dataTable) async { ... }
```

and the test file passes the values, with `<item>` and `<price>` filled in for each example row. Parameters come in this order: `tester` (widget tests), step placeholders, `docString`, `dataTable`.

## Decorators

Control test type with standard Gherkin tags:

| Decorator     | Scope             | Description                             |
| ------------- | ----------------- | --------------------------------------- |
| `@unitTest`   | Feature, Scenario | Generate unit test (overrides config)   |
| `@widgetTest` | Feature, Scenario | Generate widget test (overrides config) |

Scenario-level decorators override Feature-level ones.

To skip generation for specific features, use `ignore_features` in config.

## Generation Modes

### Incremental (Default)

```bash
dart run bdd_flutter build
```

- Skips unchanged features (tracked via manifest)
- New scenarios are **appended** to existing scenario files — implementations are preserved
- Test files are regenerated to include all scenarios

### Force Regenerate

```bash
dart run bdd_flutter build --force
```

- Regenerates all files from scratch
- **Overwrites** existing scenario implementations — use with caution

## Project Structure

```
your_project/
├── .bdd_flutter/
│   ├── config.yaml     # Configuration (commit to version control)
│   └── manifest.yaml   # Generation tracking (commit to version control)
├── test/
│   └── login/
│       ├── login.feature
│       ├── login.bdd_scenarios.dart   # Your implementations
│       └── login.bdd_test.dart        # Auto-generated orchestration
└── pubspec.yaml
```

## Best Practices

1. **Version Control** — Keep both `config.yaml` and `manifest.yaml` in version control. The manifest prevents incremental builds from overwriting implemented code on fresh clones.

2. **Scenario Files** — Implement your test logic in `.bdd_scenarios.dart`. Use `late` fields for shared state between steps (mocks, providers, widgets).

3. **Test Files** — Do not edit `.bdd_test.dart` files. They are regenerated automatically and contain no user code.

4. **Adding Scenarios** — When you add new scenarios to a `.feature` file, run `build` — new scenario classes are appended without touching existing ones.

5. **Feature Files** — Keep feature files about behavior. `@unitTest`/`@widgetTest` are the only tags bdd_flutter acts on; other tags are allowed and ignored. Tooling configuration belongs in `.bdd_flutter/config.yaml`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
