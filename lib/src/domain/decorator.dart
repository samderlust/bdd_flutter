/// Gherkin tag decorators that control test generation behavior.
///
/// Decorators are placed above `Feature:` or `Scenario:` lines in `.feature` files:
///
/// ```gherkin
/// @unitTest
/// Feature: Calculator
///   @widgetTest
///   Scenario: Increment
/// ```
///
/// Scenario-level decorators override feature-level ones.
enum Decorator {
  /// Generate a unit test using `test()` without `WidgetTester`.
  unitTest,

  /// Generate a widget test using `testWidgets()` with `WidgetTester`.
  widgetTest,

  /// Unrecognized decorator tag.
  unknown;

  /// Parses a decorator string (e.g., `@unitTest`) into a [Decorator] value.
  static Decorator fromString(String text) {
    final trimmed = text.trim();
    return switch (trimmed) {
      '@unitTest' => Decorator.unitTest,
      '@widgetTest' => Decorator.widgetTest,
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
}
