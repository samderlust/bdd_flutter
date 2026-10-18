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
      const feature = Feature(
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
      const feature = Feature(
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
      const feature = Feature(
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
      const feature = Feature(
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
      const feature = Feature(
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
      const feature = Feature(
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
      const feature = Feature(
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
      const feature = Feature(
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

  group('TestFileBuilder example arguments', () {
    test('passes example values in step text order, not column order', () async {
      const feature = Feature(
        name: 'Cart',
        path: 'test/cart.feature',
        scenarios: [
          Scenario('Add', [
            Step('When', 'I add <quantity> "<item>"'),
          ], examples: [
            {'item': 'apple', 'quantity': '2'},
          ]),
        ],
        decorators: {},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("scenario.iAddQuantityItem(tester, example['quantity']!, example['item']!)"));
    });

    test('fills columns missing from an Examples block with the placeholder text', () async {
      const feature = Feature(
        name: 'Cart',
        path: 'test/cart.feature',
        scenarios: [
          Scenario('Add', [
            Step('When', 'I add <item>'),
          ], examples: [
            {'item': 'apple'},
            {'other': 'z'},
          ]),
        ],
        decorators: {},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("{'item': 'apple','other': '<other>',},"));
      expect(result, contains("{'item': '<item>','other': 'z',},"));
    });

    test('passes placeholder text when a step has no matching example column', () async {
      const feature = Feature(
        name: 'Cart',
        path: 'test/cart.feature',
        scenarios: [
          Scenario('Plain', [Step('Given', 'I have <count> items')]),
          Scenario('Outline', [
            Step('When', 'I add <item> to <list>'),
          ], examples: [
            {'item': 'apple'},
          ]),
        ],
        decorators: {},
        background: Background(description: '', steps: [Step('Given', 'user <name>')]),
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("await scenario.iHaveCountItems(tester, '<count>');"));
      expect(result, contains("await scenario.iAddItemToList(tester, example['item']!, '<list>');"));
      expect(result, contains("await background.userName('<name>');"));
    });
  });

  group('TestFileBuilder doc strings and data tables', () {
    test('passes doc string and data table as escaped literals', () async {
      const feature = Feature(
        name: 'Orders',
        path: 'test/orders.feature',
        scenarios: [
          Scenario('Post', [
            Step('When', 'I post', docString: '{"price": "\$5"}\nit\'s'),
            Step('Given', 'products', dataTable: [['name'], ['apple']]),
          ]),
        ],
        decorators: {Decorator.unitTest},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains(r"""await scenario.iPost('{"price": "\$5"}\nit\'s');"""));
      expect(result, contains("await scenario.products([['name'], ['apple']]);"));
    });

    test('replaces example placeholders inside doc strings and tables', () async {
      const feature = Feature(
        name: 'Orders',
        path: 'test/orders.feature',
        scenarios: [
          Scenario('Post', [
            Step('When', 'I post', docString: 'qty: <qty>'),
            Step('Then', 'I see', dataTable: [['<item>', 'fixed']]),
          ], examples: [
            {'qty': '2', 'item': 'apple'},
          ]),
        ],
        decorators: {Decorator.unitTest},
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("await scenario.iPost('qty: <qty>'.replaceAll('<qty>', example['qty']!));"));
      expect(result, contains("await scenario.iSee([['<item>'.replaceAll('<item>', example['item']!), 'fixed']]);"));
    });

    test('passes doc string to background steps', () async {
      const feature = Feature(
        name: 'Orders',
        path: 'test/orders.feature',
        scenarios: [Scenario('Post', [Step('When', 'I post')])],
        decorators: {Decorator.unitTest},
        background: Background(description: '', steps: [Step('Given', 'the config', docString: 'a: 1')]),
      );

      final result = await builder.buildTestFile(feature);

      expect(result, contains("await background.theConfig('a: 1');"));
    });
  });
}
