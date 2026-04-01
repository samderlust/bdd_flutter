import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/domain/background.dart';
import 'package:bdd_flutter/src/infrastructure/builders/test_file_builder.dart';
import 'package:test/test.dart';

void main() {
  late TestFileBuilder builder;

  setUp(() {
    builder = TestFileBuilder();
  });

  group('TestFileBuilder', () {
    test('generates testWidgets by default', () async {
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

      final result = await builder.buildTestFile(feature);

      expect(result, contains("testWidgets('Increment', (tester) async {"));
    });

    test('instantiates scenario class', () async {
      final feature = Feature(
        name: 'Counter',
        path: 'test/counter.feature',
        scenarios: [
          Scenario('Increment', [
            Step('Given', 'I have a counter'),
          ]),
        ],
        decorators: {},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains('final scenario = IncrementScenario();'));
    });

    test('calls instance methods on scenario', () async {
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

      final result = await builder.buildTestFile(feature);

      expect(result, contains('await scenario.iHaveACounter(tester)'));
      expect(result, contains('await scenario.iIncrementTheCounter(tester)'));
      // Should NOT contain static class calls
      expect(result, isNot(contains('IncrementScenario.iHaveACounter')));
    });

    test('generates test() for unit tests', () async {
      final feature = Feature(
        name: 'Calculator',
        path: 'test/calculator.feature',
        scenarios: [
          Scenario('Add', [
            Step('Given', 'I have a calculator'),
          ], decorators: {
            Decorator.unitTest
          }),
        ],
        decorators: {},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("test('Add', () async {"));
      expect(result, isNot(contains('tester')));
    });

    test('generates examples loop', () async {
      final feature = Feature(
        name: 'Calculator',
        path: 'test/calculator.feature',
        scenarios: [
          Scenario('Add', [
            Step('When', 'I add <a> and <b>'),
            Step('Then', 'the result is <result>'),
          ], examples: [
            {'a': '1', 'b': '2', 'result': '3'},
            {'a': '5', 'b': '3', 'result': '8'},
          ]),
        ],
        decorators: {},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains('final examples = ['));
      expect(result, contains('for (var example in examples)'));
    });

    test('instantiates background and calls its methods', () async {
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

      final result = await builder.buildTestFile(feature);

      expect(result, contains('final background = CounterBackground();'));
      expect(result, contains('await background.iHaveACounterWithValue0();'));
    });

    test('generates imports', () async {
      final feature = Feature(
        name: 'Counter',
        path: 'test/counter.feature',
        scenarios: [],
        decorators: {},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("import 'package:flutter_test/flutter_test.dart';"));
      expect(result, contains("import 'counter.bdd_scenarios.dart';"));
    });

    test('wraps group with feature name', () async {
      final feature = Feature(
        name: 'My Feature',
        path: 'test/my_feature.feature',
        scenarios: [
          Scenario('Test', [Step('Given', 'something')]),
        ],
        decorators: {},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("group('My Feature', () {"));
    });
  });
}
