import 'package:bdd_flutter/src/domain/step.dart';
import 'package:test/test.dart';

void main() {
  group('Step.methodName', () {
    test('converts simple step to camelCase', () {
      const step = Step('Given', 'I have a counter');
      expect(step.methodName, equals('iHaveACounter'));
    });

    test('strips leading digits', () {
      const step = Step('Given', '123 items in cart');
      expect(step.methodName, equals('itemsInCart'));
    });

    test('returns step when text is all digits', () {
      const step = Step('Given', '100');
      expect(step.methodName, equals('step'));
    });

    test('handles parameters in angle brackets', () {
      const step = Step('When', 'I add <first_number> and <second_number>');
      expect(step.methodName, equals('iAddFirstNumberAndSecondNumber'));
    });

    test('handles special characters in text', () {
      const step = Step('Then', 'the result is 100%');
      expect(step.methodName, equals('theResultIs100'));
    });

    test('handles hyphenated words', () {
      const step = Step('Given', 'a well-known user');
      expect(step.methodName, equals('aWellKnownUser'));
    });

    test('handles text with only special characters', () {
      const step = Step('Given', '!!!');
      expect(step.methodName, equals('unnamed'));
    });

    test('returns unnamed for empty text', () {
      const step = Step('Given', '');
      expect(step.methodName, equals('unnamed'));
    });

    test('handles single word', () {
      const step = Step('Given', 'something');
      expect(step.methodName, equals('something'));
    });

    test('handles text starting with digit then letters', () {
      const step = Step('Given', '3 users exist');
      expect(step.methodName, equals('usersExist'));
    });

    test('handles parentheses in text', () {
      const step = Step('Then', 'I see (error) message');
      expect(step.methodName, equals('iSeeErrorMessage'));
    });

    test('handles quoted strings in text', () {
      const step = Step('When', 'I enter "hello"');
      expect(step.methodName, equals('iEnterHello'));
    });
  });

  group('Step.message', () {
    test('returns keyword and text', () {
      const step = Step('Given', 'I have a counter');
      expect(step.message, equals('Given I have a counter'));
    });
  });

  group('Step.toString', () {
    test('returns keyword and text', () {
      const step = Step('When', 'I click the button');
      expect(step.toString(), equals('When I click the button'));
    });
  });
}
