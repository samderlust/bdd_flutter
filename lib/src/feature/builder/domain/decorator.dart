class BDDDecorator {
  final DecoratorType type;
  final String? value;

  BDDDecorator(this.type, this.value);
  factory BDDDecorator.unitTest() => BDDDecorator(DecoratorType.unitTest, null);
  factory BDDDecorator.widgetTest() => BDDDecorator(DecoratorType.widgetTest, null);
  factory BDDDecorator.enableReporter() => BDDDecorator(DecoratorType.enableReporter, null);
  factory BDDDecorator.disableReporter() => BDDDecorator(DecoratorType.disableReporter, null);
  factory BDDDecorator.className(String name) => BDDDecorator(DecoratorType.className, name);
  static BDDDecorator fromString(String text) {
    return switch (text) {
      '@unitTest' => BDDDecorator(DecoratorType.unitTest, null),
      '@widgetTest' => BDDDecorator(DecoratorType.widgetTest, null),
      '@enableReporter' => BDDDecorator(DecoratorType.enableReporter, null),
      '@disableReporter' => BDDDecorator(DecoratorType.disableReporter, null),
      var t when t.contains("@className") => BDDDecorator(DecoratorType.className, _extractClassNameValue(t)),
      _ => BDDDecorator(DecoratorType.unknown, null)
    };
  }

  @override
  String toString() {
    return '@$type${value != null ? '("$value")' : ''}';
  }

  @override
  bool operator ==(Object other) {
    if (other is BDDDecorator) {
      return type == other.type && value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(type, value);
}

enum DecoratorType {
  unitTest,
  widgetTest,
  className,
  enableReporter,
  disableReporter,
  unknown,
}

extension BDDDecoratorX on BDDDecorator {
  bool get isUnitTest => type == DecoratorType.unitTest;
  bool get isWidgetTest => type == DecoratorType.widgetTest;
  bool get isClassName => type == DecoratorType.className;
  bool get isEnableReporter => type == DecoratorType.enableReporter;
  bool get isDisableReporter => type == DecoratorType.disableReporter;
}

extension BDDDecoratorSetX on Set<BDDDecorator> {
  bool get hasUnitTest => any((e) => e.isUnitTest);
  bool get hasWidgetTest => any((e) => e.isWidgetTest);
  bool get hasClassName => any((e) => e.isClassName);
  bool get hasEnableReporter => any((e) => e.isEnableReporter);
  bool get hasDisableReporter => any((e) => e.isDisableReporter);
}

String? _extractClassNameValue(String text) {
  final regex = RegExp(r'@className\("([^"]+)"\)');
  final match = regex.firstMatch(text);
  return match?.group(1);
}
