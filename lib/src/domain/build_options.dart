class BuildOptions {
  final bool widgetTest;
  final bool reporter;
  final bool force;
  final bool newOnly;

  const BuildOptions({
    this.widgetTest = true,
    this.reporter = false,
    this.force = false,
    this.newOnly = false,
  });
}
