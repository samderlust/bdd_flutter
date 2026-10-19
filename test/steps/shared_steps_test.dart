import 'package:bdd_flutter/src/domain/examples_table.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/feature_files.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/shared_files.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/infrastructure/builders/shared_steps_builder.dart';
import 'package:bdd_flutter/src/infrastructure/builders/steps_contract_builder.dart';
import 'package:bdd_flutter/src/infrastructure/builders/steps_stub_builder.dart';
import 'package:bdd_flutter/src/infrastructure/steps/steps_catalog.dart';
import 'package:bdd_flutter/src/presentation/controllers/shared_mixin.dart';
import 'package:bdd_flutter/src/presentation/controllers/steps_file_check.dart';
import 'package:test/test.dart';

Feature _feature(String name, String path, List<Step> steps) {
  return Feature(name: name, path: path, scenarios: [Scenario('A', steps)], decorators: const {});
}

final Feature _cart = _feature('Cart', 'test/cart/cart.feature', const [
  Step('Given', 'I am logged in as "admin"'),
  Step('When', 'I add 2 "apple"'),
]);

final Feature _login = _feature('Login', 'test/login/login.feature', const [
  Step('Given', 'I am logged in as "bob"'),
  Step('When', 'I log out'),
]);

void main() {
  final catalog = StepsCatalog.of([_cart, _login]);

  group('StepsCatalog across features', () {
    test('marks steps used by two or more features as shared', () {
      expect(catalog.sharedMethods.map((m) => m.name), ['iAmLoggedInAs']);
      expect(catalog.featuresUsing(catalog.sharedMethods.single), [
        'test/cart/cart.feature',
        'test/login/login.feature',
      ]);
    });

    test('lists each feature its own methods, shared ones included', () {
      expect(catalog.methodsFor(_cart).map((m) => m.name), ['iAmLoggedInAs', 'iAdd']);
      expect(catalog.methodsFor(_login).map((m) => m.name), ['iAmLoggedInAs', 'iLogOut']);
    });

    test('does not share steps whose values have different types', () {
      const outline = Feature(
        name: 'Totals',
        path: 'test/totals/totals.feature',
        scenarios: [
          Scenario(
            'A',
            [Step('Then', 'the code is <code>')],
            examples: [
              ExamplesTable(
                rows: [
                  {'code': '007'},
                ],
              ),
            ],
          ),
        ],
        decorators: {},
      );
      final numbers = _feature('Numbers', 'test/numbers/numbers.feature', const [Step('Then', 'the code is 7')]);

      final catalog = StepsCatalog.of([outline, numbers]);

      expect(catalog.sharedMethods, isEmpty);
      expect(catalog.methodsFor(numbers).single.signature, 'Future<void> theCodeIs(num number)');
      expect(catalog.methodsFor(outline).single.signature, 'Future<void> theCodeIs(String code)');
    });

    test('records a name collision between different steps', () {
      final catalog = StepsCatalog.of([
        _feature('A', 'test/a.feature', const [Step('Then', 'the cart has 1 item'), Step('Then', 'the cart has item')]),
      ]);

      expect(catalog.nameCollisions.single.toString(), contains('`Then the cart has item` is named theCartHasItem2'));
      expect(catalog.nameCollisions.single.otherStep, 'Then the cart has 1 item');
    });

    test('never renames a feature\'s methods when another feature is added', () {
      final early = _feature('Early', 'test/aaa/aaa.feature', const [Step('Then', 'I add')]);

      final before = StepsCatalog.of([_cart]).methodsFor(_cart).map((m) => m.name);
      final after = StepsCatalog.of([early, _cart]).methodsFor(_cart).map((m) => m.name);

      expect(after, before);
      expect(after, ['iAmLoggedInAs', 'iAdd']);
    });

    test('names methods the same whatever order the features come in', () {
      final reversed = StepsCatalog.of([_login, _cart]);

      expect(reversed.methods.map((m) => m.name), catalog.methods.map((m) => m.name));
    });
  });

  group('SharedFiles', () {
    test('puts the shared files at the root of the test directory', () {
      const files = SharedFiles('test/');

      expect(files.stepsPath, 'test/shared_steps.dart');
      expect(files.mixinName, 'SharedSteps');
    });

    test('follows steps_suffix and a nested test directory', () {
      const files = SharedFiles('test/features/', stepsSuffix: 'Definitions');

      expect(files.stepsPath, 'test/features/shared_steps.dart');
      expect(files.mixinName, 'SharedDefinitions');
    });

    test('builds relative imports from a feature folder', () {
      expect(SharedFiles.relativeImport('test/cart/cart_steps.dart', 'test/shared_steps.dart'), '../shared_steps.dart');
      expect(SharedFiles.relativeImport('test/a/b/x_steps.dart', 'test/shared_steps.dart'), '../../shared_steps.dart');
      expect(SharedFiles.relativeImport('test/x_steps.dart', 'test/shared_steps.dart'), 'shared_steps.dart');
    });

    test('keeps a feature named Shared apart from the shared mixin', () {
      final files = FeatureFiles(_feature('Shared', 'test/shared/shared.feature', const []));

      expect(files.stepsClass, 'SharedFeatureSteps');
    });
  });

  group('SharedStepsBuilder', () {
    const files = SharedFiles('test/');

    test('creates a plain mixin with every shared step throwing until written', () {
      final result = const SharedStepsBuilder().buildMixin(files, catalog.sharedMethods, needsTester: false);

      expect(result, contains('mixin SharedSteps {'));
      expect(result, isNot(contains('implements')));
      expect(result, isNot(contains('@override')));
      expect(result, contains('  /// `Given I am logged in as "admin"`'));
      expect(result, contains("throw UnimplementedError('Given I am logged in as \"admin\"');"));
      expect(result, isNot(contains('tester')));
    });

    test('declares tester when a widget feature uses a shared step', () {
      final result = const SharedStepsBuilder().buildMixin(files, catalog.sharedMethods, needsTester: true);

      expect(result, contains('  WidgetTester get tester;'));
    });
  });

  group('Feature files with shared steps', () {
    final files = FeatureFiles(_cart);

    test('the feature contract still declares the shared step and who else uses it', () {
      final result = const StepsContractBuilder().build(files, catalog, needsTester: false);

      expect(result, contains('Future<void> iAmLoggedInAs(String text);'));
      expect(result, contains('/// Also used by login.feature.'));
      expect(result, isNot(contains('iLogOut')));
    });

    test('a new steps class mixes in the shared steps and leaves them out', () {
      final result = const StepsStubBuilder().build(
        files,
        catalog,
        needsTester: false,
        shared: const SharedStepsUse(
          mixinName: 'SharedSteps',
          importPath: '../shared_steps.dart',
          methodNames: {'iAmLoggedInAs'},
        ),
      );

      expect(result, contains("import '../shared_steps.dart';"));
      expect(result, contains('class CartSteps with SharedSteps implements CartStepsContract {'));
      expect(result, isNot(contains('iAmLoggedInAs')));
      expect(result, contains('Future<void> iAdd(num number, String text) async {'));
    });
  });

  group('SharedMixin', () {
    const source = '''
mixin SharedSteps {
  WidgetTester get tester;
  Future<void> iAmLoggedInAs(String text) async {}
  Future<void> iAdd(
    num quantity,
    final String item,
  ) async {}
  Future<void> theProducts(List<List<String>> dataTable) async {}
  Future<void> iLogOut(String reason) async {}
}
''';
    final mixin = SharedMixin(const SharedFiles('test/'), signatures: definedSignatures(source), declaresTester: true);

    test('reads parameter types, including generics and multi-line lists', () {
      expect(definedSignatures(source), {
        'iAmLoggedInAs': ['String'],
        'iAdd': ['num', 'String'],
        'theProducts': ['List<List<String>>'],
        'iLogOut': ['String'],
      });
    });

    test('provides a step only with the same name and parameter types', () {
      final [loggedIn, add] = catalog.methodsFor(_cart);
      final logOut = catalog.methodsFor(_login).last;

      expect(mixin.provides(loggedIn), isTrue);
      expect(mixin.provides(add), isTrue);
      expect(mixin.provides(logOut), isFalse);
      expect(mixin.clashesWith(logOut), isTrue);
      expect(mixin.clashesWith(add), isFalse);
    });
  });

  group('checkStepsFile', () {
    const source = '''
class CartSteps with SharedSteps implements CartStepsContract {
  @override
  Future<void> iAdd(num number, String text) async {}
  @override
  Future<void> iCheckout() async {}
}
''';

    test('does not ask for steps the mixin provides', () {
      final warnings = checkStepsFile(source, 'cart_steps.dart', needed: {'iAdd'}, provided: {'iAmLoggedInAs'});

      expect(warnings, ['cart_steps.dart has steps no longer in any feature: iCheckout.']);
    });

    test('reports needed steps that are missing', () {
      final warnings = checkStepsFile(source, 'cart_steps.dart', needed: {'iAdd', 'iPay', 'iCheckout'});

      expect(warnings, ['cart_steps.dart is missing iPay.']);
    });
  });
}
