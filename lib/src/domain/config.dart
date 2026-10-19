/// Configuration loaded from `.bdd_flutter/config.yaml`.
///
/// Controls how the generator finds feature files, generates test code,
/// and names steps classes.
class BDDConfig {
  /// Directory to scan for `.feature` files.
  final String testDir;

  /// For scenarios without `@unitTest` or `@widgetTest`: when true,
  /// generates `testWidgets`; when false, generates `test`.
  final bool generateWidgetTests;

  /// Feature file paths to skip during generation.
  final List<String> ignoreFeatures;

  /// Imports added to each new `_steps.dart` file when it is created.
  ///
  /// Useful for shared test helpers, mock packages, etc.
  final List<String> additionalImports;

  /// Suffix appended to the steps class name.
  ///
  /// Default is `Steps` (e.g. `CounterSteps`, implementing
  /// `CounterStepsContract`).
  final String stepsSuffix;

  /// The 1.x `scenario_suffix`, read only by `migrate` to find 1.x classes.
  final String legacyScenarioSuffix;

  const BDDConfig({
    this.testDir = 'test/',
    this.generateWidgetTests = true,
    this.ignoreFeatures = const [],
    this.additionalImports = const [],
    this.stepsSuffix = 'Steps',
    this.legacyScenarioSuffix = 'Scenario',
  });
}
