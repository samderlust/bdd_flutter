import 'package:flutter_test/flutter_test.dart';
import 'package:bdd_flutter/src/feature/builder/bdd_builders/scenario_file_builder.dart';
import 'package:bdd_flutter/src/feature/builder/domain/feature.dart';
import 'package:bdd_flutter/src/feature/builder/domain/scenario.dart';
import 'package:bdd_flutter/src/feature/builder/domain/step.dart';
import 'package:bdd_flutter/src/feature/builder/domain/background.dart';
import 'package:bdd_flutter/src/feature/builder/domain/decorator.dart';

void main() {
  group('ScenariosFileBuilder', () {
    late ScenariosFileBuilder builder;

    setUp(() {
      builder = ScenariosFileBuilder();
    });

    test('builds scenario file with basic scenario', () async {
      final feature = Feature(
        'Test Feature',
        [
          Scenario(
            'Basic',
            [
              Step('Given', 'I have a counter'),
              Step('When', 'I increment the counter'),
              Step('Then', 'I should see the counter incremented'),
            ],
          ),
        ],
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains("import 'package:flutter_test/flutter_test.dart';"));
      expect(result, contains('class BasicScenario {'));
      expect(result, contains('static Future<void> iHaveACounter(WidgetTester tester) async {'));
      expect(result, contains('static Future<void> iIncrementTheCounter(WidgetTester tester) async {'));
      expect(result, contains('static Future<void> iShouldSeeTheCounterIncremented(WidgetTester tester) async {'));
    });

    test('builds scenario file with background', () async {
      final feature = Feature(
        'Test',
        [
          Scenario(
            'Basic',
            [
              Step('Given', 'I have a counter'),
              Step('When', 'I increment the counter'),
              Step('Then', 'I should see the counter incremented'),
            ],
          ),
        ],
        background: Background(
          description: 'Background steps',
          steps: [
            Step('Given', 'I am on the home page'),
            Step('And', 'I am logged in'),
          ],
        ),
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class TestBackground {'));
      expect(result, contains('static Future<void> iAmOnTheHomePage() async {'));
      expect(result, contains('static Future<void> iAmLoggedIn() async {'));
    });

    test('builds scenario file with unit test scenario', () async {
      final feature = Feature(
        'Test Feature',
        [
          Scenario(
            'Unit Test',
            [
              Step('Given', 'I have a counter'),
              Step('When', 'I increment the counter'),
              Step('Then', 'I should see the counter incremented'),
            ],
            decorators: {BDDDecorator.unitTest()},
          ),
        ],
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class UnitTestScenario {'));
      expect(result, contains('static Future<void> iHaveACounter() async {'));
      expect(result, contains('static Future<void> iIncrementTheCounter() async {'));
      expect(result, contains('static Future<void> iShouldSeeTheCounterIncremented() async {'));
    });

    test('builds scenario file with scenario containing parameters', () async {
      final feature = Feature(
        'Test',
        [
          Scenario(
            'Parameter',
            [
              Step('Given', 'I have a counter'),
              Step('When', 'I increment the counter by <amount>'),
              Step('Then', 'I should see the counter at <result>'),
            ],
          ),
        ],
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class ParameterScenario {'));
      expect(result, contains('static Future<void> iHaveACounter(WidgetTester tester) async {'));
      expect(result, contains('static Future<void> iIncrementTheCounterBy(WidgetTester tester, String amount) async {'));
      expect(result, contains('static Future<void> iShouldSeeTheCounterAt(WidgetTester tester, String result) async {'));
    });

    test('builds scenario file with numeric parameters', () async {
      final feature = Feature(
        'Test',
        [
          Scenario(
            'Numeric Parameters',
            [
              Step('Given', 'I have the number <number1>'),
              Step('And', 'I have the number <number2>'),
              Step('When', 'I divide them'),
              Step('Then', 'the result should be <result>'),
            ],
          ),
        ],
      );

      final result = await builder.buildScenarioFile(feature);

      expect(result, contains('class NumericParametersScenario {'));
      expect(result, contains('static Future<void> iHaveTheNumberNumber1(WidgetTester tester, String number1) async {'));
      expect(result, contains('static Future<void> iHaveTheNumberNumber2(WidgetTester tester, String number2) async {'));
      expect(result, contains('static Future<void> iDivideThem(WidgetTester tester) async {'));
      expect(result, contains('static Future<void> theResultShouldBeResult(WidgetTester tester, String result) async {'));
    });
  });
}
