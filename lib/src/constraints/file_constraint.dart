/// File extension constants used by the generator.
class FileConstraint {
  /// Extension for Gherkin feature files.
  static const String feature = '.feature';

  /// Extension for generated test files, rewritten on every build.
  static const String generatedTest = '.bdd_test.dart';

  /// Extension for the generated steps contract, rewritten on every build.
  static const String generatedSteps = '.bdd_steps.dart';

  /// Suffix for the steps file the user owns, created once.
  static const String userSteps = '_steps.dart';

  /// Extension of the 1.x scenarios file, replaced by [userSteps] in 2.0.
  static const String legacyScenarios = '.bdd_scenarios.dart';
}
