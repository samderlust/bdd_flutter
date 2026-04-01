import 'package:bdd_flutter/src/extensions/string_x.dart';
import 'package:test/test.dart';

void main() {
  group('StringX.name (PascalCase)', () {
    test('converts simple words', () {
      expect('successful login'.name, equals('SuccessfulLogin'));
    });

    test('handles single word', () {
      expect('login'.name, equals('Login'));
    });

    test('prefixes with X when starting with digit', () {
      expect('123 login'.name, equals('X123Login'));
    });

    test('prefixes with X when all digits', () {
      expect('123'.name, equals('X123'));
    });

    test('strips special characters', () {
      expect('hello-world'.name, equals('HelloWorld'));
    });

    test('strips exclamation and other punctuation', () {
      expect('with special!chars'.name, equals('WithSpecialChars'));
    });

    test('returns Unnamed for empty string', () {
      expect(''.name, equals('Unnamed'));
    });

    test('returns Unnamed for whitespace only', () {
      expect('   '.name, equals('Unnamed'));
    });

    test('handles mixed digits and words', () {
      expect('step 2 verify'.name, equals('Step2Verify'));
    });

    test('handles leading spaces', () {
      expect('  login page'.name, equals('LoginPage'));
    });

    test('handles multiple spaces between words', () {
      expect('login   page'.name, equals('LoginPage'));
    });
  });

  group('StringX.toClassName', () {
    test('appends suffix', () {
      expect('Increment'.toClassName('Scenario'), equals('IncrementScenario'));
    });

    test('appends custom suffix', () {
      expect('Increment'.toClassName('Steps'), equals('IncrementSteps'));
    });

    test('handles name starting with digit', () {
      expect('123 test'.toClassName('Scenario'), equals('X123TestScenario'));
    });
  });

  group('StringX.snakeCaseToCamelCase', () {
    test('converts simple snake_case', () {
      expect('first_name'.snakeCaseToCamelCase, equals('firstName'));
    });

    test('handles single word', () {
      expect('name'.snakeCaseToCamelCase, equals('name'));
    });

    test('handles leading underscore', () {
      expect('_value'.snakeCaseToCamelCase, equals('value'));
    });

    test('handles trailing underscore', () {
      expect('value_'.snakeCaseToCamelCase, equals('value'));
    });

    test('handles multiple underscores', () {
      expect('a__b'.snakeCaseToCamelCase, equals('aB'));
    });

    test('handles all underscores', () {
      expect('___'.snakeCaseToCamelCase, equals('___'));
    });

    test('handles empty string', () {
      expect(''.snakeCaseToCamelCase, equals(''));
    });

    test('converts multi-segment snake_case', () {
      expect('my_long_variable_name'.snakeCaseToCamelCase,
          equals('myLongVariableName'));
    });
  });

  group('StringX.toSnakeCase', () {
    test('converts space-separated to snake_case', () {
      expect('Hello World'.toSnakeCase, equals('hello_world'));
    });

    test('handles single word', () {
      expect('Hello'.toSnakeCase, equals('hello'));
    });
  });
}
