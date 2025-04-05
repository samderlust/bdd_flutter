# BDD Flutter

A Flutter package that helps you write BDD (Behavior Driven Development) tests using Gherkin syntax.

## Features

- Parse `.feature` files written in Gherkin syntax
- Generate boilerplate test files
- Support for both widget tests and unit tests
- Configurable test generation

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dev_dependencies:
  bdd_flutter: any
  build_runner: any
```

## Usage

Create a `.feature` file in your project:

```
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

Run the build command to generate the test files:

```bash
flutter pub run build_runner build
```

This will generate:

- a `sample.scenario.dart` file, containing the scenario implementation.
- a `sample_test.dart` file, containing the test implementation.

then run the test file:

```bash
flutter test
```

## Configuration

You can configure the test generation by passing options to the builder:

```yaml
targets:
  $default:
    builders:
      bdd_flutter|bdd_test_builder:
        options:
          generate_widget_tests: false
```

by default, the builder will generate widget tests. By setting `generate_widget_tests` to `false`, the builder will generate unit tests instead.

## Decorators

You can use the following decorators to control the test generation:

- `@unitTest`: Generate a unit test (ignore build.yaml config)
- `@widgetTest`: Generate a widget test (ignore build.yaml config)

decorators can be used at the feature, scenario level. The lower the level, the more specific the decorator and it will override the upper level decorator.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Example

1. create a feature file (e.g. `counter.feature`)

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

2. run the builder

```bash
flutter pub run build_runner build
```

3. generated file

- `counter_scenarios.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

class IncrementScenario {
  static Future<void> iHaveACounterWithValue0(WidgetTester tester) async {
    // TODO: Implement Given I have a counter with value 0
  }

  static Future<void> iIncrementTheCounterBy(WidgetTester tester,dynamic value) async {
    // TODO: Implement When I increment the counter by <value>
  }

  static Future<void> theCounterShouldHaveValue(WidgetTester tester,dynamic expected_value) async {
    // TODO: Implement Then the counter should have value <expected_value>
  }
}
```

- `counter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'counter_scenarios.dart';

void main() {
  group('Counter', () {
    testWidgets('Increment', (tester) async {
      await IncrementScenario.iHaveACounterWithValue0(tester);
      // Example with values: 1, 1
      await IncrementScenario.iIncrementTheCounterBy(tester, '1');
      await IncrementScenario.theCounterShouldHaveValue(tester, '1');
      // Example with values: 2, 2
      await IncrementScenario.iIncrementTheCounterBy(tester, '2');
      await IncrementScenario.theCounterShouldHaveValue(tester, '2');
      // Example with values: 3, 3
      await IncrementScenario.iIncrementTheCounterBy(tester, '3');
      await IncrementScenario.theCounterShouldHaveValue(tester, '3');
    });
  });
}
```

4. run the test

```bash
flutter test
```
