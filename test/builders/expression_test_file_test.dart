import 'package:bdd_flutter/src/domain/background.dart';
import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:bdd_flutter/src/domain/examples_table.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/feature_files.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/domain/steps_class.dart';
import 'package:bdd_flutter/src/domain/unresolved_reason.dart';
import 'package:bdd_flutter/src/infrastructure/builders/expression_step_calls.dart';
import 'package:bdd_flutter/src/infrastructure/builders/test_file_builder.dart';
import 'package:bdd_flutter/src/infrastructure/steps/steps_file_reader.dart';
import 'package:test/test.dart';

const String _stepsPath = 'test/cart/cart_steps.dart';
const String _sharedPath = 'test/shared_steps.dart';

Feature _feature(List<Scenario> scenarios, {Background? background}) {
  return Feature(
    name: 'Shopping cart',
    path: 'test/cart/cart.feature',
    scenarios: scenarios,
    decorators: const {Decorator.unitTest},
    background: background,
  );
}

StepsClass? _read(String source, String name, {String path = _stepsPath}) {
  return const StepsFileReader().parse(source, path: path).classNamed(name);
}

ExpressionStepCalls _calls(String ownSource, {String? sharedSource}) {
  return ExpressionStepCalls(
    stepsClassName: 'ShoppingCartSteps',
    own: _read(ownSource, 'ShoppingCartSteps'),
    shared: sharedSource == null ? null : _read(sharedSource, 'SharedSteps', path: _sharedPath),
    sharedImport: '../shared_steps.dart',
  );
}

String _build(Feature feature, ExpressionStepCalls calls) {
  return const TestFileBuilder(widgetTestsByDefault: false).build(FeatureFiles(feature), calls);
}

void main() {
  group('TestFileBuilder with ExpressionStepCalls', () {
    test('calls matched methods with literal arguments', () {
      // Arrange
      final calls = _calls(r'''
class ShoppingCartSteps {
  @When('I add {int} {string} at {float} each')
  Future<void> iAdd(int quantity, String item, double price) async {}

  @Then('I have {int} cucumber(s) in my belly/stomach')
  Future<void> iHave(int count) async {}
}
''');
      final feature = _feature([
        const Scenario('Add', [
          Step('When', 'I add 2 "apple" at 1 each'),
          Step('Then', 'I have 1 cucumber in my stomach'),
          Step('And', 'I have 3 cucumbers in my belly'),
        ]),
      ]);

      // Act
      final result = _build(feature, calls);

      // Assert
      expect(result, contains("    await steps.iAdd(2, 'apple', 1.0);"));
      expect(result, contains('    await steps.iHave(1);'));
      expect(result, contains('    await steps.iHave(3);'));
      expect(calls.unresolved, isEmpty);
    });

    test('converts custom types with their parameter type method', () {
      // Arrange
      final calls = _calls(r'''
class ShoppingCartSteps {
  @ParameterType(r'shipped|pending')
  static OrderStatus status(String value) => OrderStatus.values.byName(value);

  @Given('the order is {status}')
  Future<void> theOrderIs(OrderStatus status) async {}
}
''');
      final feature = _feature([
        const Scenario('Order', [Step('Given', 'the order is shipped')]),
      ]);

      // Act
      final result = _build(feature, calls);

      // Assert
      expect(result, contains("    await steps.theOrderIs(ShoppingCartSteps.status('shipped'));"));
      expect(result, isNot(contains('shared_steps.dart')));
    });

    test('fills outline rows before matching', () {
      // Arrange
      final calls = _calls('''
class ShoppingCartSteps {
  @When('I add {int} {word}')
  Future<void> iAdd(int quantity, String item) async {}
}
''');
      final feature = _feature([
        const Scenario(
          'Add',
          [Step('When', 'I add <quantity> <item>')],
          examples: [
            ExamplesTable(
              rows: [
                {'quantity': '2', 'item': 'apple'},
                {'quantity': '5', 'item': 'pear'},
              ],
            ),
          ],
        ),
      ]);

      // Act
      final result = _build(feature, calls);

      // Assert
      expect(result, contains('    // When I add <quantity> <item>'));
      expect(result, contains("    await steps.iAdd(2, 'apple');"));
      expect(result, contains("    await steps.iAdd(5, 'pear');"));
    });

    test('passes doc strings and data tables after the expression arguments', () {
      // Arrange
      final calls = _calls('''
class ShoppingCartSteps {
  @Given('the note for {word}:')
  Future<void> theNote(String who, String note) async {}

  @Given('the prices:')
  Future<void> thePrices(List<List<String>> table) async {}
}
''');
      final feature = _feature([
        const Scenario('Data', [
          Step('Given', 'the note for ann:', docString: 'hi'),
          Step(
            'Given',
            'the prices:',
            dataTable: [
              ['apple', '1'],
            ],
          ),
        ]),
      ]);

      // Act
      final result = _build(feature, calls);

      // Assert
      expect(result, contains("    await steps.theNote('ann', 'hi');"));
      expect(result, contains("    await steps.thePrices([['apple', '1']]);"));
    });

    test('uses the shared mixin when the class mixes it in, and imports it for its types', () {
      // Arrange
      final calls = _calls(
        '''
class ShoppingCartSteps with SharedSteps {}
''',
        sharedSource: r'''
mixin SharedSteps {
  @ParameterType(r'\$\d+')
  static Money money(String value) => Money.parse(value);

  @Given('I pay {money}')
  Future<void> iPay(Money amount) async {}
}
''',
      );
      final feature = _feature([
        const Scenario('Pay', [Step('Given', r'I pay $10')]),
      ]);

      // Act
      final result = _build(feature, calls);

      // Assert
      expect(result, contains(r"    await steps.iPay(SharedSteps.money('\$10'));"));
      expect(result, contains("import 'cart_steps.dart';\nimport '../shared_steps.dart';\n"));
    });

    test("prefers the feature's own method over the shared mixin", () {
      // Arrange
      final calls = _calls(
        '''
class ShoppingCartSteps with SharedSteps {
  @Given('I am logged in')
  Future<void> ownLogin() async {}
}
''',
        sharedSource: '''
mixin SharedSteps {
  @Given('I am logged in')
  Future<void> sharedLogin() async {}
}
''',
      );

      // Act
      final result = _build(
        _feature([
          const Scenario('Login', [Step('Given', 'I am logged in')]),
        ]),
        calls,
      );

      // Assert
      expect(result, contains('    await steps.ownLogin();'));
    });

    test('runs hooks: tear-downs registered first, then before hooks, mixin before class', () {
      // Arrange
      final calls = _calls(
        '''
class ShoppingCartSteps with SharedSteps {
  @Before()
  Future<void> openCart() async {}

  @After()
  Future<void> closeCart() async {}
}
''',
        sharedSource: '''
mixin SharedSteps {
  @Before()
  Future<void> openDb() async {}

  @After()
  Future<void> closeDb() async {}
}
''',
      );

      // Act
      final result = _build(_feature([const Scenario('Empty', [])]), calls);

      // Assert
      expect(
        result,
        contains(
          '    final steps = ShoppingCartSteps();\n'
          '    addTearDown(steps.closeDb);\n'
          '    addTearDown(steps.closeCart);\n'
          '    await steps.openDb();\n'
          '    await steps.openCart();\n',
        ),
      );
    });

    test('turns undefined, ambiguous and unmixed shared steps into failures', () {
      // Arrange
      final calls = _calls(
        '''
class ShoppingCartSteps {
  @Given('I have {int} apples')
  Future<void> a(int n) async {}

  @Given('I have {} apples')
  Future<void> b(String n) async {}
}
''',
        sharedSource: '''
mixin SharedSteps {
  @Given('I am logged in')
  Future<void> iAmLoggedIn() async {}
}
''',
      );
      final feature = _feature([
        const Scenario('Broken', [
          Step('Given', 'nothing defines this'),
          Step('And', 'I have 3 apples'),
          Step('And', 'I am logged in'),
          Step('And', 'nothing defines this'),
        ]),
      ]);

      // Act
      final result = _build(feature, calls);

      // Assert
      expect(result, contains("    fail('Undefined step: Given nothing defines this');"));
      expect(
        result,
        contains("    fail('Ambiguous step: And I have 3 apples matches ShoppingCartSteps.a, ShoppingCartSteps.b');"),
      );
      expect(
        result,
        contains(
          "    fail('Step And I am logged in is defined in SharedSteps; add `with SharedSteps` to ShoppingCartSteps');",
        ),
      );
      expect(calls.unresolved.map((u) => u.reason), [
        UnresolvedReason.undefined,
        UnresolvedReason.ambiguous,
        UnresolvedReason.missingSharedMixin,
      ]);
      expect(calls.unresolved[1].candidates.map((d) => d.methodName), ['a', 'b']);
    });

    test('treats every step as undefined when the steps class does not exist yet', () {
      // Arrange
      final calls = ExpressionStepCalls(stepsClassName: 'ShoppingCartSteps', own: null);

      // Act
      final result = _build(
        _feature([
          const Scenario('New', [Step('Given', 'a new step')]),
        ]),
        calls,
      );

      // Assert
      expect(result, contains("fail('Undefined step: Given a new step');"));
      expect(calls.unresolved.single.text, 'a new step');
    });

    test('accepts optional and named parameters the call leaves out', () {
      // Arrange
      final calls = _calls('''
class ShoppingCartSteps {
  @When('I add {int}')
  Future<void> iAdd(int n, [int? m]) async {}

  @When('I remove {int}')
  Future<void> iRemove(int n, {String? note}) async {}
}
''');

      // Act
      _build(
        _feature([
          const Scenario('Add', [Step('When', 'I add 2'), Step('When', 'I remove 1')]),
        ]),
        calls,
      );

      // Assert
      expect(calls.warnings, isEmpty);
    });

    test('exposes expression problems', () {
      // Arrange & Act
      final calls = _calls('''
class ShoppingCartSteps {
  @Given('the {colour} car')
  Future<void> a(String c) async {}
}
''');

      // Assert
      expect(calls.problems.single.message, contains("Undefined parameter type 'colour'"));
    });
  });
}
