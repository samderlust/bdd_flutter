/// Configuration loaded from `.bdd_flutter/config.yaml`.
///
/// Controls how the generator finds feature files, generates test code,
/// and names scenario classes.
class BDDConfig {
  /// Directory to scan for `.feature` files.
  final String testDir;

  /// When true, generates `testWidgets` with `WidgetTester`.
  /// When false, generates `test` without `WidgetTester`.
  final bool generateWidgetTests;

  /// Feature file paths to skip during generation.
  final List<String> ignoreFeatures;

  /// Import statements added to every generated `.bdd_scenarios.dart` file.
  ///
  /// Useful for shared test helpers, mock packages, etc.
  final List<String> additionalImports;

  /// Suffix appended to scenario class names.
  ///
  /// Default is `Scenario` (e.g., `IncrementScenario`).
  /// Set to `Steps` for `IncrementSteps`.
  final String scenarioSuffix;

  const BDDConfig({
    this.testDir = 'test/',
    this.generateWidgetTests = true,
    this.ignoreFeatures = const [],
    this.additionalImports = const [],
    this.scenarioSuffix = 'Scenario',
  });
}
