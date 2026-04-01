class BDDConfig {
  final bool generateWidgetTests;
  final List<String> ignoreFeatures;

  const BDDConfig({
    this.generateWidgetTests = true,
    this.ignoreFeatures = const [],
  });
}
