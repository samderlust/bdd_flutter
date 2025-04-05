/// Decorator enum for the feature file
enum DecoratorEnum {
  unitTest('@unitTest'),
  widgetTest('@widgetTest');

  const DecoratorEnum(this.text);

  final String text;

  static DecoratorEnum fromText(String text) {
    return _enumMapper(text.trim());
  }
}

DecoratorEnum _enumMapper(String text) {
  switch (text) {
    case '@unitTest':
      return DecoratorEnum.unitTest;
    case '@widgetTest':
      return DecoratorEnum.widgetTest;
    default:
      throw Exception('Invalid decorator: $text');
  }
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
