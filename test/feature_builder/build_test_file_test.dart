import 'package:flutter_test/flutter_test.dart';
import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_test_file_builder.dart';
import 'package:bdd_flutter/src/feature/builder/domain/feature.dart';
import 'package:bdd_flutter/src/feature/builder/domain/scenario.dart';
import 'package:bdd_flutter/src/feature/builder/domain/step.dart';
import 'package:bdd_flutter/src/feature/builder/domain/background.dart';
import 'package:bdd_flutter/src/feature/builder/domain/decorator.dart';

void main() {
  group('BDDTestFileBuilder', () {
    late BDDTestFileBuilder builder;

    setUp(() {
      builder = BDDTestFileBuilder();
    });

    test('builds test file with basic scenario', () async {
      final feature = Feature(
        'Test',
        fileName: 'test',
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

      final result = await builder.buildTestFile(feature);

      expect(result, contains("import 'package:flutter_test/flutter_test.dart';"));
      expect(result, contains("import 'test.bdd_scenarios.dart';"));
      expect(result, contains("void main() {"));
      expect(result, contains("group('Test', () {"));
      expect(result, contains("testWidgets('Basic', (tester) async {"));
      expect(result, contains("BasicScenario.iHaveACounter(tester);"));
      expect(result, contains("BasicScenario.iIncrementTheCounter(tester);"));
      expect(result, contains("BasicScenario.iShouldSeeTheCounterIncremented(tester);"));
    });

    test('builds test file with background', () async {
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

      final result = await builder.buildTestFile(feature);

      expect(result, contains("//Background: Background steps"));
      expect(result, contains("TestBackground.iAmOnTheHomePage();"));
      expect(result, contains("TestBackground.iAmLoggedIn();"));
    });

    test('builds test file with unit test scenario', () async {
      final feature = Feature(
        'Test',
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

      final result = await builder.buildTestFile(feature);

      expect(result, contains("test('Unit Test', () async {"));
      expect(result, contains("UnitTestScenario.iHaveACounter();"));
      expect(result, contains("UnitTestScenario.iIncrementTheCounter();"));
      expect(result, contains("UnitTestScenario.iShouldSeeTheCounterIncremented();"));
    });

    test('builds test file with scenario containing examples', () async {
      final feature = Feature(
        'Test',
        [
          Scenario(
            'Parameterized',
            [
              Step('Given', 'I have a counter'),
              Step('When', 'I increment the counter by <amount>'),
              Step('Then', 'I should see the counter at <result>'),
            ],
            examples: [
              {'amount': '1', 'result': '1'},
              {'amount': '2', 'result': '2'},
            ],
          ),
        ],
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("final examples = ["));
      expect(result, contains("for (var example in examples) {"));
      expect(result, contains("ParameterizedScenario.iIncrementTheCounterBy(tester, example['amount']!);"));
      expect(result, contains("ParameterizedScenario.iShouldSeeTheCounterAt(tester, example['result']!);"));
    });

    test('builds test file with reporter enabled', () async {
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
        decorators: {BDDDecorator.enableReporter()},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("import 'package:bdd_flutter/bdd_flutter.dart';"));
      expect(result, contains("final reporter = BDDTestReporter(featureName: 'Test Feature');"));
      expect(result, contains("setUpAll(() {"));
      expect(result, contains("reporter.testStarted(); // start recording"));
      expect(result, contains("tearDownAll(() {"));
      expect(result, contains("reporter.testFinished(); // stop recording"));
      expect(result, contains("reporter.printReport(); // print report"));
      expect(result, contains("reporter.startScenario('Basic');"));
    });

    test('builds test file with multiple scenarios', () async {
      final feature = Feature(
        'Test',
        [
          Scenario(
            'First',
            [
              Step('Given', 'I have a counter'),
              Step('When', 'I increment the counter'),
              Step('Then', 'I should see the counter incremented'),
            ],
          ),
          Scenario(
            'Second',
            [
              Step('Given', 'I have a counter'),
              Step('When', 'I decrement the counter'),
              Step('Then', 'I should see the counter decremented'),
            ],
          ),
        ],
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("testWidgets('First', (tester) async {"));
      expect(result, contains("testWidgets('Second', (tester) async {"));
      expect(result, contains("FirstScenario.iHaveACounter(tester);"));
      expect(result, contains("SecondScenario.iHaveACounter(tester);"));
      expect(result, contains("SecondScenario.iDecrementTheCounter(tester);"));
      expect(result, contains("SecondScenario.iShouldSeeTheCounterDecremented(tester);"));
    });

    test('builds test file with numeric parameters', () async {
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
            examples: [
              {'number1': '10', 'number2': '2', 'result': '5'},
              {'number1': '20', 'number2': '4', 'result': '5'},
            ],
          ),
        ],
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("testWidgets('Numeric Parameters', (tester) async {"));
      expect(result, contains("final examples = ["));
      expect(result, contains("for (var example in examples) {"));
      expect(result, contains("NumericParametersScenario.iHaveTheNumberNumber1(tester, example['number1']!);"));
      expect(result, contains("NumericParametersScenario.iHaveTheNumberNumber2(tester, example['number2']!);"));
      expect(result, contains("NumericParametersScenario.iDivideThem(tester);"));
      expect(result, contains("NumericParametersScenario.theResultShouldBeResult(tester, example['result']!);"));
    });
  });
}
