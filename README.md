# BDD Flutter

[![pub package](https://img.shields.io/pub/v/bdd_flutter.svg)](https://pub.dev/packages/bdd_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter package that simplifies Behavior Driven Development (BDD) by automatically generating test files from Gherkin feature files. Write expressive tests in plain English using Given/When/Then scenarios and let BDD Flutter handle the boilerplate code generation.

## Features

- Parse `.feature` files written in Gherkin syntax (Given/When/Then/And)
- Generate boilerplate test files automatically
- Support for both widget tests and unit tests
- Incremental generation — new scenarios are appended without overwriting existing implementations
- Instance-based scenario classes for shared state between steps
- Background support for shared setup steps
- Examples tables for parameterized scenarios
- Configurable via `.bdd_flutter/config.yaml`
- Manifest tracking in `.bdd_flutter/manifest.yaml`

## Installation

Add to your `pubspec.yaml`:

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
| `build`         | Generate test files from `.feature` files            |
| `build --force` | Force regenerate all files (overwrites existing)     |
| `test`          | Run BDD tests with formatted Feature/Scenario report |

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

5. **Feature Files** — Keep feature files clean. Only use `@unitTest`/`@widgetTest` decorators. All other configuration belongs in `.bdd_flutter/config.yaml`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
