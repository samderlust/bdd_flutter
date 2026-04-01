class BuildOptions {
  final bool widgetTest;
  final bool force;
  final bool newOnly;

  const BuildOptions({
    this.widgetTest = true,
    this.force = false,
    this.newOnly = false,
  });
}
