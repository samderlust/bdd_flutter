import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:test/test.dart';

void main() {
  group('Scenario.className', () {
    test('converts simple name to PascalCase with suffix', () {
      const scenario = Scenario('Successful login', []);
      expect(scenario.className, equals('SuccessfulLoginScenario'));
    });

    test('handles name starting with digit', () {
      const scenario = Scenario('2nd attempt', []);
      expect(scenario.className, equals('X2ndAttemptScenario'));
    });

    test('handles name with special characters', () {
      const scenario = Scenario('login (admin)', []);
      expect(scenario.className, equals('LoginAdminScenario'));
    });

    test('handles name with hyphens', () {
      const scenario = Scenario('end-to-end flow', []);
      expect(scenario.className, equals('EndToEndFlowScenario'));
    });

    test('uses custom suffix', () {
      const scenario = Scenario('Login', []);
      expect(scenario.classNameWithSuffix('Steps'), equals('LoginSteps'));
    });
  });

  group('Scenario.isUnitTestWithFeature', () {
    test('returns true when scenario has @unitTest', () {
      const scenario = Scenario('Test', [], decorators: {Decorator.unitTest});
      expect(scenario.isUnitTestWithFeature({}), isTrue);
    });

    test('returns false when scenario has @widgetTest', () {
      const scenario = Scenario('Test', [], decorators: {Decorator.widgetTest});
      expect(scenario.isUnitTestWithFeature({Decorator.unitTest}), isFalse);
    });

    test('falls back to feature decorator', () {
      const scenario = Scenario('Test', []);
      expect(scenario.isUnitTestWithFeature({Decorator.unitTest}), isTrue);
    });

    test('defaults to widget test', () {
      const scenario = Scenario('Test', []);
      expect(scenario.isUnitTestWithFeature({}), isFalse);
    });
  });

  group('Scenario.getHash', () {
    test('same content produces same hash', () {
      const s1 = Scenario('Test', [Step('Given', 'something')]);
      const s2 = Scenario('Test', [Step('Given', 'something')]);
      expect(s1.getHash, equals(s2.getHash));
    });

    test('different content produces different hash', () {
      const s1 = Scenario('Test', [Step('Given', 'something')]);
      const s2 = Scenario('Test', [Step('Given', 'something else')]);
      expect(s1.getHash, isNot(equals(s2.getHash)));
    });
  });
}
