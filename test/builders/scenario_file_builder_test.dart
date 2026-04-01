import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/domain/background.dart';
import 'package:bdd_flutter/src/infrastructure/builders/scenario_file_builder.dart';
import 'package:test/test.dart';

void main() {
  late ScenariosFileBuilder builder;

  setUp(() {
    builder = ScenariosFileBuilder();
  });

  group('ScenariosFileBuilder', () {
    test('generates instance methods (not static)', () async {
      final feature = Feature(
        name: 'Counter',
        path: 'test/counter.feature',
        scenarios: [
          Scenario('Increment', [
            Step('Given', 'I have a counter'),
            Step('When', 'I increment the counter'),
          ]),
        ],
        decorators: {},
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class IncrementScenario {'));
      expect(result, contains('  Future<void> iHaveACounter(WidgetTester tester) async {'));
      expect(result, contains('  Future<void> iIncrementTheCounter(WidgetTester tester) async {'));
      // Should NOT contain static
      expect(result, isNot(contains('static Future')));
    });

    test('generates unit test methods without WidgetTester', () async {
      final feature = Feature(
        name: 'Calculator',
        path: 'test/calculator.feature',
        scenarios: [
          Scenario('Add', [
            Step('Given', 'I have a calculator'),
          ], decorators: {Decorator.unitTest}),
        ],
        decorators: {},
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('  Future<void> iHaveACalculator() async {'));
      expect(result, isNot(contains('WidgetTester')));
    });

    test('generates methods with parameters from angle brackets', () async {
      final feature = Feature(
        name: 'Calculator',
        path: 'test/calculator.feature',
        scenarios: [
          Scenario('Add', [
            Step('When', 'I add <first_number> and <second_number>'),
          ]),
        ],
        decorators: {},
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('Future<void> iAddFirstNumberAndSecondNumber(WidgetTester tester, String firstNumber, String secondNumber) async {'));
    });

    test('generates Background class with instance methods', () async {
      final feature = Feature(
        name: 'Counter',
        path: 'test/counter.feature',
        scenarios: [
          Scenario('Increment', [
            Step('When', 'I increment'),
          ]),
        ],
        decorators: {},
        background: Background(
          description: 'Counter starts at 0',
          steps: [Step('Given', 'I have a counter with value 0')],
        ),
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class CounterBackground {'));
      expect(result, contains('  Future<void> iHaveACounterWithValue0() async {'));
      // Background should NOT have static
      expect(result, isNot(contains('static Future')));
    });

    test('generates import for flutter_test', () async {
      final feature = Feature(
        name: 'Test',
        path: 'test/test.feature',
        scenarios: [],
        decorators: {},
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains("import 'package:flutter_test/flutter_test.dart';"));
    });

    test('uses @className for custom class name', () async {
      final feature = Feature(
        name: 'Login',
        path: 'test/login.feature',
        scenarios: [
          Scenario('Test', [Step('Given', 'something')], customClassName: 'MyCustomScenario'),
        ],
        decorators: {},
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class MyCustomScenario {'));
      expect(result, isNot(contains('class TestScenario {')));
    });

    test('skips scenarios with @ignore', () async {
      final feature = Feature(
        name: 'Login',
        path: 'test/login.feature',
        scenarios: [
          Scenario('Skipped', [Step('Given', 'something')], decorators: {Decorator.ignore}),
          Scenario('Active', [Step('Given', 'something else')]),
        ],
        decorators: {},
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, isNot(contains('class SkippedScenario {')));
      expect(result, contains('class ActiveScenario {'));
    });

    test('inherits @unitTest from feature decorators', () async {
      final feature = Feature(
        name: 'Calculator',
        path: 'test/calculator.feature',
        scenarios: [
          Scenario('Add', [Step('Given', 'I have a calculator')]),
        ],
        decorators: {Decorator.unitTest},
      );

      final result = await builder.buildScenarioFile(feature);

      // Should NOT have WidgetTester since feature is @unitTest
      expect(result, isNot(contains('WidgetTester')));
    });

    test('generates multiple scenario classes', () async {
      final feature = Feature(
        name: 'Login',
        path: 'test/login.feature',
        scenarios: [
          Scenario('Successful login', [Step('Given', 'I am logged in')]),
          Scenario('Failed login', [Step('Given', 'I am not logged in')]),
        ],
        decorators: {},
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class SuccessfulLoginScenario {'));
      expect(result, contains('class FailedLoginScenario {'));
    });
  });
}
