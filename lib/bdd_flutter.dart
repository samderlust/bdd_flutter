/// A Flutter package for Behavior-Driven Development (BDD) testing.
///
/// BDD Flutter generates Dart test files from Gherkin `.feature` files.
/// Write scenarios in plain English using Given/When/Then syntax, then run:
///
/// ```bash
/// dart run bdd_flutter build
/// ```
///
/// This generates `.bdd_scenarios.dart` (step stubs) and `.bdd_test.dart`
/// (test orchestration) files alongside each `.feature` file.
///
/// ## Quick Start
///
/// 1. Create a `.feature` file in your test folder
/// 2. Run `dart run bdd_flutter build` to generate test files
/// 3. Implement the step methods in the generated scenario classes
/// 4. Run `dart run bdd_flutter test` for a BDD-formatted test report
///
/// ## Configuration
///
/// Configure via `.bdd_flutter/config.yaml`:
///
/// ```yaml
/// test_dir: "test/"
/// generate_widget_tests: true
/// ignore_features:
///   - test/features/login.feature
/// additional_imports:
///   - "package:mocktail/mocktail.dart"
/// scenario_suffix: "Scenario"
/// ```
library bdd_flutter;
