class BDDConfig {
  final bool generateWidgetTests;
  final bool enableReporter;
  final List<String> ignoreFeatures;

  const BDDConfig({
    this.generateWidgetTests = true,
    this.enableReporter = false,
    this.ignoreFeatures = const [],
  });
}
