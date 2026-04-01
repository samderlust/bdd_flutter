enum Decorator {
  unitTest,
  widgetTest,
  enableReporter,
  disableReporter,
  ignore,
  unknown;

  static Decorator fromString(String text) {
    // Strip the text to handle just the decorator name
    final trimmed = text.trim();
    return switch (trimmed) {
      '@unitTest' => Decorator.unitTest,
      '@widgetTest' => Decorator.widgetTest,
      '@enableReporter' => Decorator.enableReporter,
      '@disableReporter' => Decorator.disableReporter,
      '@ignore' => Decorator.ignore,
      _ => Decorator.unknown,
    };
  }

  /// Check if text is a @className("...") decorator and extract the name
  static String? parseClassName(String text) {
    final regex = RegExp(r'^@className\("(.+)"\)$');
    final match = regex.firstMatch(text.trim());
    return match?.group(1);
  }
}

extension DecoratorX on Decorator {
  bool get isUnitTest => this == Decorator.unitTest;
  bool get isWidgetTest => this == Decorator.widgetTest;
  bool get isEnableReporter => this == Decorator.enableReporter;
  bool get isDisableReporter => this == Decorator.disableReporter;
  bool get isIgnore => this == Decorator.ignore;
}

extension DecoratorSetX on Set<Decorator> {
  bool get hasUnitTest => any((e) => e.isUnitTest);
  bool get hasWidgetTest => any((e) => e.isWidgetTest);
  bool get hasEnableReporter => any((e) => e.isEnableReporter);
  bool get hasDisableReporter => any((e) => e.isDisableReporter);
  bool get hasIgnore => any((e) => e.isIgnore);
}
