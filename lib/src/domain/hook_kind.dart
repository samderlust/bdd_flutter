/// When a scenario hook runs.
enum HookKind {
  /// `@Before`: before the Background and steps of each scenario.
  before,

  /// `@After`: after each scenario, even when a step fails.
  after,
}
