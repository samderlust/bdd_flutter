/// A Flutter package for Behavior-Driven Development (BDD) testing.
///
/// BDD Flutter generates Dart test files from Gherkin `.feature` files.
/// Write scenarios in plain English using Given/When/Then syntax, then run:
///
/// ```bash
/// dart run bdd_flutter build
/// ```
///
/// For each `.feature` file this generates, next to it:
/// - `<name>.bdd_steps.g.dart`: an interface with one method per step,
///   rewritten on every build;
/// - `<name>_steps.dart`: your implementation, created once;
/// - `<name>.bdd_test.dart`: the tests, rewritten on every build.
///
/// ## Quick Start
///
/// 1. Create a `.feature` file in your test folder
/// 2. Run `dart run bdd_flutter build` to generate test files
/// 3. Implement the step methods in the `_steps.dart` file
/// 4. Run `flutter test`, or `dart run bdd_flutter test` for a BDD report
///
/// Upgrading from 1.x: run `dart run bdd_flutter migrate`.
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
/// steps_suffix: "Steps"
/// ```
library bdd_flutter;
