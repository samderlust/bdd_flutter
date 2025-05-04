class BDDOptions {
  final bool generateWidgetTests;
  final bool enableReporter;
  final List<String> ignoreFeatures;

  BDDOptions({
    this.generateWidgetTests = true,
    this.enableReporter = false,
    this.ignoreFeatures = const [],
  });
}
