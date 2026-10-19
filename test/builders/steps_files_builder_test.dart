import 'package:bdd_flutter/src/domain/examples_table.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/domain/feature_files.dart';
import 'package:bdd_flutter/src/domain/scenario.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/infrastructure/builders/steps_contract_builder.dart';
import 'package:bdd_flutter/src/infrastructure/builders/steps_stub_builder.dart';
import 'package:bdd_flutter/src/infrastructure/steps/steps_catalog.dart';
import 'package:test/test.dart';

const Feature _feature = Feature(
  name: 'Shopping cart',
  path: 'test/cart/cart.feature',
  scenarios: [
    Scenario(
      'A',
      [Step('Given', 'an empty cart'), Step('When', 'I add <n> "<item>"')],
      examples: [
        ExamplesTable(
          rows: [
            {'n': '1', 'item': 'apple'},
          ],
        ),
      ],
    ),
    Scenario('B', [Step('When', 'I add 2 "pear"')]),
  ],
  decorators: {},
);

void main() {
  const files = FeatureFiles(_feature);
  final catalog = StepsCatalog.of([_feature]);

  group('FeatureFiles', () {
    test('names files next to the feature and classes after its name', () {
      expect(files.contractPath, 'test/cart/cart.bdd_steps.dart');
      expect(files.stepsPath, 'test/cart/cart_steps.dart');
      expect(files.testPath, 'test/cart/cart.bdd_test.dart');
      expect(files.legacyScenariosPath, 'test/cart/cart.bdd_scenarios.dart');
      expect(files.stepsClass, 'ShoppingCartSteps');
      expect(files.contractClass, 'ShoppingCartStepsContract');
    });

    test('uses the configured suffix', () {
      expect(const FeatureFiles(_feature, stepsSuffix: 'Definitions').contractClass, 'ShoppingCartDefinitionsContract');
    });
  });

  group('StepsContractBuilder', () {
    test('declares an interface with one documented method per step pattern', () {
      final result = const StepsContractBuilder().build(files, catalog, needsTester: false);

      expect(result, startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND.'));
      expect(result, contains('abstract interface class ShoppingCartStepsContract {'));
      expect(result, contains('  /// `When I add <n> "<item>"`\n  /// `When I add 2 "pear"`\n'));
      expect(result, contains('  Future<void> iAdd(num n, String item);'));
      expect(result, isNot(contains('WidgetTester')));
    });

    test('declares a tester field for widget tests', () {
      final result = const StepsContractBuilder().build(files, catalog, needsTester: true);

      expect(result, contains("import 'package:flutter_test/flutter_test.dart';"));
      expect(result, contains('  abstract WidgetTester tester;'));
    });
  });

  group('StepsStubBuilder', () {
    test('implements the contract with methods that throw until written', () {
      final result = const StepsStubBuilder().build(
        files,
        catalog,
        needsTester: true,
        additionalImports: ['package:mocktail/mocktail.dart'],
      );

      expect(result, contains("import 'package:mocktail/mocktail.dart';"));
      expect(result, contains("import 'cart.bdd_steps.dart';"));
      expect(result, contains('class ShoppingCartSteps implements ShoppingCartStepsContract {'));
      expect(result, contains('  @override\n  late WidgetTester tester;'));
      expect(result, contains("    throw UnimplementedError('Given an empty cart');"));
    });

    test('carries migrated imports, declarations, fields and bodies', () {
      final result = const StepsStubBuilder().build(
        files,
        catalog,
        needsTester: false,
        content: const StepsStubContent(
          imports: ["import 'package:example/cart.dart';"],
          topLevel: ['late Cart cart;'],
          fields: ['int count = 0;'],
          bodies: {'anEmptyCart': '    cart = Cart();'},
        ),
      );

      expect(result, contains("import 'package:example/cart.dart';"));
      expect(result, contains('late Cart cart;'));
      expect(result, contains('  int count = 0;'));
      expect(result, contains('  Future<void> anEmptyCart() async {\n    cart = Cart();\n  }'));
    });
  });
}
