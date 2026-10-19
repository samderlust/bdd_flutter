import 'package:bdd_flutter/src/domain/value_type.dart';
import 'package:test/test.dart';

void main() {
  group('ValueType.of', () {
    test('reads numbers Dart prints back unchanged', () {
      expect(ValueType.of('2'), ValueType.number);
      expect(ValueType.of('-1'), ValueType.number);
      expect(ValueType.of('0.25'), ValueType.number);
    });

    test('keeps numbers that would lose characters as text', () {
      expect(ValueType.of('02134'), ValueType.string);
      expect(ValueType.of('1.50'), ValueType.string);
      expect(ValueType.of('1e3'), ValueType.string);
      expect(ValueType.of('-0'), ValueType.string);
    });

    test('reads true and false as booleans', () {
      expect(ValueType.of('true'), ValueType.boolean);
      expect(ValueType.of('false'), ValueType.boolean);
      expect(ValueType.of('True'), ValueType.string);
    });
  });

  group('ValueType.ofAll', () {
    test('returns the shared type', () {
      expect(ValueType.ofAll(['1', '2', '3.5']), ValueType.number);
    });

    test('falls back to string when types differ', () {
      expect(ValueType.ofAll(['1', 'apple']), ValueType.string);
      expect(ValueType.ofAll(['1.5', '1.50']), ValueType.string);
    });
  });
}
