enum Decorator {
  unitTest,
  widgetTest,
  enableReporter,
  unknown;

  static Decorator fromString(String text) {
    return switch (text) { '@unitTest' => Decorator.unitTest, '@widgetTest' => Decorator.widgetTest, '@enableReporter' => Decorator.enableReporter, _ => Decorator.unknown };
  }

  static Set<Decorator> elligibleForScenario() {
    return {
      Decorator.unitTest,
      Decorator.widgetTest,
    };
  }

  static Set<Decorator> elligibleForFeature() {
    return {
      Decorator.unitTest,
      Decorator.widgetTest,
      Decorator.enableReporter,
    };
  }
}

extension DecoratorX on Decorator {
  bool get isUnitTest => this == Decorator.unitTest;
  bool get isWidgetTest => this == Decorator.widgetTest;
  bool get isEnableReporter => this == Decorator.enableReporter;
}

extension DecoratorSetX on Set<Decorator> {
  bool get hasUnitTest => any((e) => e.isUnitTest);
  bool get hasWidgetTest => any((e) => e.isWidgetTest);
  bool get hasEnableReporter => any((e) => e.isEnableReporter);
}
