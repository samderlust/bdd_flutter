import 'package:bdd_flutter/src/domain/background.dart';
import 'package:bdd_flutter/src/domain/examples_table.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/rule.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/infrastructure/steps/steps_catalog.dart';
import 'package:test/test.dart';

Feature _feature({List<Scenario> scenarios = const [], List<Rule> rules = const [], Background? background}) {
  return Feature(
    name: 'Cart',
    path: 'test/cart.feature',
    scenarios: scenarios,
    rules: rules,
    background: background,
    decorators: const {},
  );
}

StepsCatalog _catalog(Feature feature) => StepsCatalog.of([feature]);

void main() {
  group('StepsCatalog', () {
    test('shares one method between steps that differ only in values', () {
      final catalog = _catalog(
        _feature(
          scenarios: [
            const Scenario('A', [Step('Then', 'the cart has 1 item')]),
            const Scenario('B', [Step('And', 'the cart has 0 item')]),
          ],
        ),
      );

      expect(catalog.methods.map((m) => m.name), ['theCartHasItem']);
      expect(catalog.methods.single.stepMessages, ['Then the cart has 1 item', 'And the cart has 0 item']);
      expect(catalog.methods.single.signature, 'Future<void> theCartHasItem(num number)');
    });

    test('collects background, rule background and rule steps in file order', () {
      final catalog = _catalog(
        _feature(
          background: const Background(description: '', steps: [Step('Given', 'an empty cart')]),
          scenarios: [
            const Scenario('A', [Step('When', 'I add "apple"')]),
          ],
          rules: [
            const Rule(
              name: 'Closed',
              background: Background(description: '', steps: [Step('Given', 'the cart is closed')]),
              scenarios: [
                Scenario('B', [Step('Then', 'I see an error')]),
              ],
            ),
          ],
        ),
      );

      expect(catalog.methods.map((m) => m.name), ['anEmptyCart', 'iAdd', 'theCartIsClosed', 'iSeeAnError']);
    });

    test('names parameters after placeholders, else after their type', () {
      final catalog = _catalog(
        _feature(
          scenarios: [
            const Scenario('A', [Step('When', 'I add 2 "apple"')]),
            const Scenario(
              'B',
              [Step('When', 'I add <quantity> "<item>"')],
              examples: [
                ExamplesTable(
                  rows: [
                    {'quantity': '1', 'item': 'pear'},
                  ],
                ),
              ],
            ),
            const Scenario('C', [Step('Then', 'I see "a" and "b"')]),
          ],
        ),
      );

      expect(catalog.methods[0].signature, 'Future<void> iAdd(num quantity, String item)');
      expect(catalog.methods[1].signature, 'Future<void> iSeeAnd(String text, String text2)');
    });

    test('suffixes names that collide', () {
      final catalog = _catalog(
        _feature(
          scenarios: [
            const Scenario('A', [Step('Then', 'the cart has 1 item'), Step('Then', 'the cart has item')]),
          ],
        ),
      );

      expect(catalog.methods.map((m) => m.name), ['theCartHasItem', 'theCartHasItem2']);
    });

    test('adds doc string and data table parameters last', () {
      final catalog = _catalog(
        _feature(
          scenarios: [
            const Scenario('A', [
              Step(
                'Given',
                'the products for "x":',
                docString: '{}',
                dataTable: [
                  ['a'],
                ],
              ),
            ]),
          ],
        ),
      );

      expect(
        catalog.methods.single.signature,
        'Future<void> theProductsFor(String text, String docString, List<List<String>> dataTable)',
      );
    });

    test('uses a hash for steps without Latin letters', () {
      final catalog = _catalog(
        _feature(
          scenarios: [
            const Scenario('A', [Step('Given', 'カウンター')]),
          ],
        ),
      );

      expect(catalog.methods.single.name, matches(RegExp(r'^step[0-9a-f]{6}$')));
    });
  });
}
