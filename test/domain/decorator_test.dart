import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:test/test.dart';

void main() {
  group('Decorator.fromString', () {
    test('parses @unitTest', () {
      expect(Decorator.fromString('@unitTest'), equals(Decorator.unitTest));
    });

    test('parses @widgetTest', () {
      expect(Decorator.fromString('@widgetTest'), equals(Decorator.widgetTest));
    });

    test('returns unknown for unrecognized tag', () {
      expect(Decorator.fromString('@skip'), equals(Decorator.unknown));
    });

    test('trims whitespace', () {
      expect(Decorator.fromString('  @unitTest  '), equals(Decorator.unitTest));
    });
  });

  group('DecoratorSetX', () {
    test('hasUnitTest returns true when present', () {
      expect({Decorator.unitTest}.hasUnitTest, isTrue);
    });

    test('hasUnitTest returns false when absent', () {
      expect({Decorator.widgetTest}.hasUnitTest, isFalse);
    });

    test('hasWidgetTest returns true when present', () {
      expect({Decorator.widgetTest}.hasWidgetTest, isTrue);
    });

    test('empty set returns false for both', () {
      expect(<Decorator>{}.hasUnitTest, isFalse);
      expect(<Decorator>{}.hasWidgetTest, isFalse);
    });
  });
}
