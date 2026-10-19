/// Gherkin tags that control test generation.
///
/// Decorators are placed above `Feature:`, `Rule:` or `Scenario:` lines:
///
/// ```gherkin
/// @unitTest
/// Feature: Calculator
///   @widgetTest
///   Scenario: Increment
/// ```
///
/// The closest decorator wins: scenario over rule over feature. Every other
/// tag is passed to the generated test as a `dart test` tag.
enum Decorator {
  /// Generate a unit test using `test()` without `WidgetTester`.
  unitTest,

  /// Generate a widget test using `testWidgets()` with `WidgetTester`.
  widgetTest,

  /// Generate the test with `skip: true`.
  skip,

  /// Any other tag.
  unknown;

  /// Parses a tag (e.g. `@unitTest`) into a [Decorator].
  static Decorator fromString(String text) {
    return switch (text.trim()) {
      '@unitTest' => Decorator.unitTest,
      '@widgetTest' => Decorator.widgetTest,
      '@skip' => Decorator.skip,
      _ => Decorator.unknown,
    };
  }
}

/// Convenience getters for a single [Decorator].
extension DecoratorX on Decorator {
  bool get isUnitTest => this == Decorator.unitTest;
  bool get isWidgetTest => this == Decorator.widgetTest;
}

/// Convenience getters for a set of [Decorator]s.
extension DecoratorSetX on Set<Decorator> {
  bool get hasUnitTest => any((e) => e.isUnitTest);
  bool get hasWidgetTest => any((e) => e.isWidgetTest);
  bool get hasSkip => contains(Decorator.skip);

  /// Whether these decorators pick a test kind: `true` for a unit test,
  /// `false` for a widget test, `null` when they say nothing.
  bool? get unitTestChoice {
    if (hasUnitTest) return true;
    if (hasWidgetTest) return false;
    return null;
  }
}
