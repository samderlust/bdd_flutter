import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:test/test.dart';

void main() {
  group('Scenario.className', () {
    test('converts simple name to PascalCase with suffix', () {
      final scenario = Scenario('Successful login', []);
      expect(scenario.className, equals('SuccessfulLoginScenario'));
    });

    test('handles name starting with digit', () {
      final scenario = Scenario('2nd attempt', []);
      expect(scenario.className, equals('X2ndAttemptScenario'));
    });

    test('handles name with special characters', () {
      final scenario = Scenario('login (admin)', []);
      expect(scenario.className, equals('LoginAdminScenario'));
    });

    test('handles name with hyphens', () {
      final scenario = Scenario('end-to-end flow', []);
      expect(scenario.className, equals('EndToEndFlowScenario'));
    });

    test('uses custom suffix', () {
      final scenario = Scenario('Login', []);
      expect(scenario.classNameWithSuffix('Steps'), equals('LoginSteps'));
    });
  });

  group('Scenario.isUnitTestWithFeature', () {
    test('returns true when scenario has @unitTest', () {
      final scenario = Scenario('Test', [], decorators: {Decorator.unitTest});
      expect(scenario.isUnitTestWithFeature({}), isTrue);
    });

    test('returns false when scenario has @widgetTest', () {
      final scenario = Scenario('Test', [], decorators: {Decorator.widgetTest});
      expect(scenario.isUnitTestWithFeature({Decorator.unitTest}), isFalse);
    });

    test('falls back to feature decorator', () {
      final scenario = Scenario('Test', []);
      expect(scenario.isUnitTestWithFeature({Decorator.unitTest}), isTrue);
    });

    test('defaults to widget test', () {
      final scenario = Scenario('Test', []);
      expect(scenario.isUnitTestWithFeature({}), isFalse);
    });
  });

  group('Scenario.getHash', () {
    test('same content produces same hash', () {
      final s1 = Scenario('Test', [Step('Given', 'something')]);
      final s2 = Scenario('Test', [Step('Given', 'something')]);
      expect(s1.getHash, equals(s2.getHash));
    });

    test('different content produces different hash', () {
      final s1 = Scenario('Test', [Step('Given', 'something')]);
      final s2 = Scenario('Test', [Step('Given', 'something else')]);
      expect(s1.getHash, isNot(equals(s2.getHash)));
    });
  });
}
