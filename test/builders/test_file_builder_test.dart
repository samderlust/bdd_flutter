import 'package:bdd_flutter/src/domain/background.dart';
import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:bdd_flutter/src/domain/examples_table.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/feature_files.dart';
import 'package:bdd_flutter/src/domain/rule.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/infrastructure/builders/test_file_builder.dart';
import 'package:bdd_flutter/src/infrastructure/steps/steps_catalog.dart';
import 'package:test/test.dart';

String _build(Feature feature, {bool widgetTestsByDefault = true}) {
  final builder = TestFileBuilder(widgetTestsByDefault: widgetTestsByDefault);
  return builder.build(FeatureFiles(feature), StepsCatalog.of([feature]));
}

Feature _feature(
  List<Scenario> scenarios, {
  Set<Decorator> decorators = const {},
  Set<String> tags = const {},
  Background? background,
  List<Rule> rules = const [],
}) {
  return Feature(
    name: 'Shopping cart',
    path: 'test/cart/cart.feature',
    scenarios: scenarios,
    decorators: decorators,
    tags: tags,
    background: background,
    rules: rules,
  );
}

void main() {
  group('TestFileBuilder', () {
    test('imports the user steps file and groups by feature', () {
      final result = _build(_feature([]));

      expect(result, startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND.'));
      expect(result, contains("import 'cart_steps.dart';"));
      expect(result, contains("group('Shopping cart', () {"));
    });

    test('generates testWidgets that hands the tester to the steps object', () {
      final result = _build(
        _feature([
          const Scenario('Increment', [Step('When', 'I tap plus')]),
        ]),
      );

      expect(result, contains("testWidgets('Increment', (tester) async {"));
      expect(result, contains('final steps = ShoppingCartSteps()..tester = tester;'));
      expect(result, contains('await steps.iTapPlus();'));
    });

    test('generates test() for @unitTest and when widget tests are off', () {
      final scenarios = [
        const Scenario('Add', [Step('When', 'I add')]),
      ];

      expect(_build(_feature(scenarios, decorators: {Decorator.unitTest})), contains("test('Add', () async {"));
      expect(_build(_feature(scenarios), widgetTestsByDefault: false), contains("test('Add', () async {"));
    });

    test('passes values from the step text as typed literals', () {
      final result = _build(
        _feature(
          [
            const Scenario('Add', [Step('When', 'I add 2 "apple" at 1.5 each')]),
          ],
          decorators: {Decorator.unitTest},
        ),
      );

      expect(result, contains('    // When I add 2 "apple" at 1.5 each'));
      expect(result, contains("await steps.iAddAtEach(2, 'apple', 1.5);"));
    });

    test('runs the feature background, then the rule background, inside a rule group', () {
      final result = _build(
        _feature(
          [],
          decorators: {Decorator.unitTest},
          background: const Background(description: 'Empty cart', steps: [Step('Given', 'an empty cart')]),
          rules: [
            const Rule(
              name: 'Closed carts',
              background: Background(description: '', steps: [Step('Given', 'the cart is closed')]),
              scenarios: [
                Scenario('Add', [Step('When', 'I add "pear"')]),
              ],
            ),
          ],
        ),
      );

      expect(result, contains("group('Rule: Closed carts', () {"));
      final background = result.indexOf('await steps.anEmptyCart();');
      final ruleBackground = result.indexOf('await steps.theCartIsClosed();');
      final step = result.indexOf("await steps.iAdd('pear');");
      expect(background, lessThan(ruleBackground));
      expect(ruleBackground, lessThan(step));
      expect(result, contains('// Background: Empty cart'));
      expect(result, contains('// Rule background'));
    });

    test('generates one test per example row with its own steps object', () {
      final result = _build(
        _feature(
          [
            const Scenario(
              'Total',
              [Step('When', 'I add <quantity> "<item>"')],
              examples: [
                ExamplesTable(
                  name: 'Small orders',
                  rows: [
                    {'item': 'apple', 'quantity': '1'},
                    {'item': 'pear', 'quantity': '2'},
                  ],
                ),
                ExamplesTable(
                  rows: [
                    {'item': 'banana', 'quantity': '100'},
                  ],
                ),
              ],
            ),
          ],
          decorators: {Decorator.unitTest},
        ),
      );

      expect(result, contains("group('Total', () {"));
      expect(result, contains("test('Small orders #1 (item: apple, quantity: 1)', () async {"));
      expect(result, contains("test('Small orders #2 (item: pear, quantity: 2)', () async {"));
      expect(result, contains("test('Example #1 (item: banana, quantity: 100)', () async {"));
      expect(result, contains("await steps.iAdd(100, 'banana');"));
      expect('final steps = ShoppingCartSteps();'.allMatches(result), hasLength(3));
      expect(result, isNot(contains('for (')));
    });

    test('keeps a column as text when a value would lose characters', () {
      final result = _build(
        _feature(
          [
            const Scenario(
              'Price',
              [Step('Then', 'the price is <price>')],
              examples: [
                ExamplesTable(
                  rows: [
                    {'price': '1.50'},
                  ],
                ),
              ],
            ),
          ],
          decorators: {Decorator.unitTest},
        ),
      );

      expect(result, contains("await steps.thePriceIs('1.50');"));
    });

    test('fills placeholders in doc strings and data tables per row', () {
      final result = _build(
        _feature(
          [
            const Scenario(
              'Send',
              [
                Step(
                  'When',
                  'I send:',
                  docString: r'{"price": "$<price>"}',
                  dataTable: [
                    ['price'],
                    ['<price>'],
                  ],
                ),
              ],
              examples: [
                ExamplesTable(
                  rows: [
                    {'price': '1.50'},
                  ],
                ),
              ],
            ),
          ],
          decorators: {Decorator.unitTest},
        ),
      );

      expect(result, contains(r"""await steps.iSend('{"price": "\$1.50"}', [['price'], ['1.50']]);"""));
    });

    test('escapes quotes and dollar signs in test names', () {
      final result = _build(
        _feature(
          [
            const Scenario(r"it's $5", [Step('Given', 'a thing')]),
          ],
          decorators: {Decorator.unitTest},
        ),
      );

      expect(result, contains(r"test('it\'s \$5', () async {"));
    });

    test('passes valid tags from feature, scenario and Examples, and skip', () {
      final result = _build(
        _feature(
          [
            const Scenario(
              'Add',
              [Step('When', 'I add <n>')],
              decorators: {Decorator.skip},
              tags: {'fast', 'className("X")'},
              examples: [
                ExamplesTable(
                  rows: [
                    {'n': '1'},
                  ],
                  tags: {'eu'},
                ),
              ],
            ),
          ],
          decorators: {Decorator.unitTest},
          tags: {'cart'},
        ),
      );

      expect(result, contains("}, tags: ['cart', 'eu', 'fast'], skip: true);"));
      expect(result, isNot(contains('className')));
    });
  });

  group('TestFileBuilder.needsTester', () {
    test('is true when any scenario is a widget test', () {
      final feature = _feature([
        const Scenario('A', [], decorators: {Decorator.unitTest}),
        const Scenario('B', []),
      ]);

      expect(const TestFileBuilder().needsTester(feature), isTrue);
    });

    test('is false when every scenario is a unit test', () {
      final feature = _feature([const Scenario('A', [])], decorators: {Decorator.unitTest});

      expect(const TestFileBuilder().needsTester(feature), isFalse);
    });
  });
}
