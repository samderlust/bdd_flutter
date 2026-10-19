import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/feature_files.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/shared_files.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/infrastructure/builders/shared_steps_builder.dart';
import 'package:bdd_flutter/src/infrastructure/builders/steps_contract_builder.dart';
import 'package:bdd_flutter/src/infrastructure/builders/steps_stub_builder.dart';
import 'package:bdd_flutter/src/infrastructure/steps/steps_catalog.dart';
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

    test('names methods the same whatever order the features come in', () {
      final reversed = StepsCatalog.of([_login, _cart]);

      expect(reversed.methods.map((m) => m.name), catalog.methods.map((m) => m.name));
    });
  });

  group('SharedFiles', () {
    test('puts the shared files at the root of the test directory', () {
      const files = SharedFiles('test/');

      expect(files.contractPath, 'test/shared.bdd_steps.dart');
      expect(files.stepsPath, 'test/shared_steps.dart');
      expect(files.mixinName, 'SharedSteps');
      expect(files.contractClass, 'SharedStepsContract');
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

    test('declares the shared steps with the features that use them', () {
      final result = const SharedStepsBuilder().buildContract(files, catalog, needsTester: false);

      expect(result, contains('abstract interface class SharedStepsContract {'));
      expect(
        result,
        contains('  /// Used by cart.feature, login.feature.\n  Future<void> iAmLoggedInAs(String text);'),
      );
      expect(result, isNot(contains('iAdd(')));
    });

    test('creates a mixin with every shared step throwing until written', () {
      final result = const SharedStepsBuilder().buildMixin(files, catalog);

      expect(result, contains("import 'shared.bdd_steps.dart';"));
      expect(result, contains('mixin SharedSteps implements SharedStepsContract {'));
      expect(result, contains("throw UnimplementedError('Given I am logged in as \"admin\"');"));
    });
  });

  group('Feature files with shared steps', () {
    final files = FeatureFiles(_cart);

    test('the feature contract still declares the shared step, noting who shares it', () {
      final result = const StepsContractBuilder().build(files, catalog, needsTester: false);

      expect(result, contains('Future<void> iAmLoggedInAs(String text);'));
      expect(result, contains('/// Shared with login.feature: implement it once in the shared steps mixin.'));
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
