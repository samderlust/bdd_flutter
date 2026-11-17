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
/// - `<name>.bdd_steps.dart`: an interface with one method per step,
///   rewritten on every build;
/// - `<name>_steps.dart`: your implementation, created once;
/// - `<name>.bdd_test.dart`: the tests, rewritten on every build.
///
/// Steps used by several features can be written once in
/// `mixin SharedSteps` (`shared_steps.dart` at the root of the test
/// directory), which steps classes mix in.
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
///
/// ## Step annotations (3.0, in progress)
///
/// Importing this library gives the annotations used in steps files:
/// [Step], [Given], [When], [Then], [ParameterType], [Before] and [After].
/// It contains no CLI code.
library bdd_flutter;

export 'src/annotations/after.dart';
export 'src/annotations/before.dart';
export 'src/annotations/given.dart';
export 'src/annotations/parameter_type.dart';
export 'src/annotations/step.dart';
export 'src/annotations/then.dart';
export 'src/annotations/when.dart';
