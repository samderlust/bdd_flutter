/// Decorator enum for the feature file
enum DecoratorEnum {
  unitTest('@unitTest', 'unitTest'),
  widgetTest('@widgetTest', 'widgetTest'),
  className('@className', null);

  const DecoratorEnum(this.text, this.value);

  final String text;
  final String? value;

  static DecoratorEnum fromText(String text) {
    return _enumMapper(text.trim());
  }
}

DecoratorEnum _enumMapper(String text) {
  return switch (text) {
    '@unitTest' => DecoratorEnum.unitTest,
    '@widgetTest' => DecoratorEnum.widgetTest,
    var t when t.contains("@className") => DecoratorEnum.className,
    _ => throw Exception('Invalid decorator: $text')
  };
}

extension DecoratorSetX on Set<DecoratorEnum> {
  bool get hasUnitTest => contains(DecoratorEnum.unitTest);
  bool get hasWidgetTest => contains(DecoratorEnum.widgetTest);
  void validate() {
    if (hasUnitTest && hasWidgetTest) {
      throw Exception(
        'Cannot have both @unitTest and @widgetTest decorators at the same time',
      );
    }
  }
}
