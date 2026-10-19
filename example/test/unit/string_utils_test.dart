import 'package:flutter_test/flutter_test.dart';

String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

int add(int a, int b) => a + b;

void main() {
  group('capitalize', () {
    test('capitalizes first letter', () {
      expect(capitalize('hello'), equals('Hello'));
    });

    test('returns empty string for empty input', () {
      expect(capitalize(''), equals(''));
    });

    test('handles single character', () {
      expect(capitalize('a'), equals('A'));
    });
  });

  group('add', () {
    test('adds two positive numbers', () {
      expect(add(2, 3), equals(5));
    });

    test('adds negative numbers', () {
      expect(add(-1, -2), equals(-3));
    });

    test('adds zero', () {
      expect(add(0, 5), equals(5));
    });
  });
}
