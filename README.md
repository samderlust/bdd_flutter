# 🚀 BDD Flutter

[![pub package](https://img.shields.io/pub/v/bdd_flutter.svg)](https://pub.dev/packages/bdd_flutter)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/samderlust)

A powerful Flutter package that simplifies Behavior Driven Development (BDD) by automatically generating test files from Gherkin feature files. Write expressive tests in plain English using Given/When/Then scenarios and let BDD Flutter handle the boilerplate code generation.

## 🚨 Breaking Changes in v1.0.0

- The package no longer uses `build_runner`. Instead, it now uses a simpler CLI approach:
  1. Remove `build_runner` from your dev_dependencies if you added it previously
  2. Use `dart run bdd_flutter build` to generate test files
  3. Generated files will use the `.bdd.dart` extension for better clarity

To migrate:

1. Remove build_runner if present in your dev_dependencies
2. If you want to keep current test files, consider add `.feature` file paths into `bdd_config.yaml` under `ignore_features` section (see [Configuration](#-configuration) for more details)

## ✨ Features

- 📝 Parse `.feature` files written in Gherkin syntax
- ⚡ Generate boilerplate test files automatically
- 🧪 Support for both widget tests and unit tests
- ⚙️ Configurable test generation
- 📄 Ignore specific generated files using `.bdd_config.yaml`
- 📄 Incremental generation to preserve user-written code
- 📄 Configuration in `.bdd_flutter/config.yaml`
- 📄 Manifest tracking in `.bdd_flutter/manifest.yaml`

## 📦 Installation

Add the following dependencies to your package's `pubspec.yaml` file:

```yaml
dev_dependencies:
  bdd_flutter: ^1.0.0
```

## 🚀 Quick Start

1. Create a `.feature` file in your project:

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

2. Run the generator to create test files:

```bash
dart run bdd_flutter build
```

3. Run your tests:

```bash
flutter test
```

## 💡 Recommendations

When working with generated test files, follow these best practices:

1. **Generated Files**:

   - Generated files will have the `.bdd.*.dart` extension (e.g., `counter_test.bdd.test.dart` or `counter_scenarios.bdd.scenarios.dart`)
   - After implementing your tests, it's recommended to:
     - Remove the `.bdd.*` extension from the file name
     - or you can run `dart run bdd_flutter rename` to rename the files
     - Add an ignore decorator to your feature file (@ignore)
   - This will prevent the generated files from being overwritten by subsequent builds

2. **Feature File Ignore**:
   Add this comment at the top of your feature file:
   ```gherkin
   @ignore
   Feature: Counter
   ```

This approach ensures that:

- Your implemented tests won't be overwritten by subsequent builds
- Generated files are properly ignored in version control
- You maintain a clean project structure

## 🚀 Configuration

You can configure the generator in `bdd_config.yaml`:

```yaml
generate_widget_tests: true
enable_reporter: false
ignore_features:
  - test/features/login.feature
  - test/features/registration.feature
```

Or use command-line arguments:

```bash
dart run bdd_flutter build --no-widget-tests --enable-reporter --ignore login.feature
```

### Configuration Options

| Option                  | Type | Default | Description                                            |
| ----------------------- | ---- | ------- | ------------------------------------------------------ |
| `generate_widget_tests` | bool | true    | Generate widget tests when true, unit tests when false |
| `enable_reporter`       | bool | false   | Enable/disable test reporter                           |
| `ignore_features`       | List | []      | List of feature file paths to ignore during generation |

## 🏷️ Decorators

Control test generation with decorators:

| Decorator                  | Scope             | Description                             |
| -------------------------- | ----------------- | --------------------------------------- |
| `@unitTest`                | Feature, Scenario | Generate unit test (overrides config)   |
| `@widgetTest`              | Feature, Scenario | Generate widget test (overrides config) |
| `@className("CustomName")` | Scenario          | Generate custom class name              |
| `@enableReporter`          | Feature           | Enable test reporter                    |
| `@disableReporter`         | Feature           | Disable test reporter                   |

> 💡 Decorators follow a hierarchy: Scenario-level decorators override Feature-level ones.

## 📝 Complete Example

### 1. Feature File (`counter.feature`)

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

### 2. Generated Files

#### `counter_scenarios.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

class IncrementScenario {
  static Future<void> iHaveACounterWithValue0(WidgetTester tester) async {
    // TODO: Implement Given I have a counter with value 0
  }

  static Future<void> iIncrementTheCounterBy(WidgetTester tester, dynamic value) async {
    // TODO: Implement When I increment the counter by <value>
  }

  static Future<void> theCounterShouldHaveValue(WidgetTester tester, dynamic expected_value) async {
    // TODO: Implement Then the counter should have value <expected_value>
  }
}
```

#### `counter_test.dart`

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

## 🤝 Contributing

We welcome contributions! Please feel free to:

- Open an issue
- Submit a pull request
- Share your feedback

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Additional Information

For more information, visit the [documentation](https://example.com/bdd_flutter).

## Project Structure

```
your_project/
├── .bdd_flutter/
│   ├── config.yaml     # Configuration settings
│   └── manifest.yaml   # Generation state tracking
├── test/
│   ├── features/
│   │   └── login.feature
│   └── features_test/
│       ├── login_test.dart
│       └── login_scenarios.dart
└── pubspec.yaml
```

## Generation Modes

The package supports three generation modes:

### 1. Incremental Update (Default)

```bash
dart run bdd_flutter build
```

- Processes new and modified scenarios
- Preserves user-written code
- Tracks changes in `.bdd_flutter/manifest.yaml`

### 2. Force Regenerate

```bash
dart run bdd_flutter build --force
```

- Regenerates all test files
- Overwrites existing files
- Use with caution

### 3. New Files Only

```bash
dart run bdd_flutter build --new-only
```

- Only processes new feature files
- Skips existing files
- Useful for initial setup

## Best Practices

1. **Version Control**

   - Add `.bdd_flutter/manifest.yaml` to `.gitignore`
   - Keep `.bdd_flutter/config.yaml` in version control

2. **Feature Files**

   - Keep feature files in `test/features/`
   - Use descriptive names for scenarios
   - Follow Gherkin syntax guidelines

3. **Test Files**
   - Don't modify generated test files directly
   - Add your implementation in the provided methods
   - Use the incremental update mode to preserve changes
