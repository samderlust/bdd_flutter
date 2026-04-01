enum Decorator {
  unitTest,
  widgetTest,
  unknown;

  static Decorator fromString(String text) {
    final trimmed = text.trim();
    return switch (trimmed) {
      '@unitTest' => Decorator.unitTest,
      '@widgetTest' => Decorator.widgetTest,
      _ => Decorator.unknown,
    };
  }
}

extension DecoratorX on Decorator {
  bool get isUnitTest => this == Decorator.unitTest;
  bool get isWidgetTest => this == Decorator.widgetTest;
}

extension DecoratorSetX on Set<Decorator> {
  bool get hasUnitTest => any((e) => e.isUnitTest);
  bool get hasWidgetTest => any((e) => e.isWidgetTest);
}
