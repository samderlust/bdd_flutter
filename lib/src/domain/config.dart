class BDDConfig {
  final String testDir;
  final bool generateWidgetTests;
  final List<String> ignoreFeatures;
  final List<String> additionalImports;
  final String scenarioSuffix;

  const BDDConfig({
    this.testDir = 'test/',
    this.generateWidgetTests = true,
    this.ignoreFeatures = const [],
    this.additionalImports = const [],
    this.scenarioSuffix = 'Scenario',
  });
}
