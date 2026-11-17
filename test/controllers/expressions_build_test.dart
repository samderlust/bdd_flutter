import 'dart:io';

import 'package:bdd_flutter/src/domain/config.dart';
import 'package:bdd_flutter/src/domain/feature.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/feature_parser.dart';
import 'package:bdd_flutter/src/presentation/controllers/build_report.dart';
import 'package:bdd_flutter/src/presentation/controllers/expressions_build.dart';
import 'package:test/test.dart';

const String _cartFeature = '''
@unitTest
Feature: Shopping cart
  Scenario: Add
    When I add 2 "apple"
    Then the cart has 2 items
''';

void main() {
  late Directory tempDir;
  late String testDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bdd_expressions_build_test_');
    testDir = '${tempDir.path}/test';
    Directory('$testDir/cart').createSync(recursive: true);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  String path(String relative) => '$testDir/$relative';

  void write(String relative, String content) {
    File(path(relative))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  String read(String relative) => File(path(relative)).readAsStringSync();

  Future<BuildReport> build({List<String> featurePaths = const ['cart/cart.feature']}) async {
    final features = <Feature>[for (final p in featurePaths) await const FeatureParser().parseFeature(path(p))];
    final report = BuildReport();
    await const ExpressionsBuild().run(features, BDDConfig(testDir: '$testDir/'), report, (
      filePath,
      content, {
      created = false,
    }) async {
      File(filePath).writeAsStringSync(content);
      report.written(filePath, created: created);
    });
    return report;
  }

  group('ExpressionsBuild', () {
    test('calls annotated methods and writes no contract', () async {
      // Arrange
      write('cart/cart.feature', _cartFeature);
      write('cart/cart_steps.dart', '''
import 'package:bdd_flutter/bdd_flutter.dart';

class ShoppingCartSteps {
  @When('I add {int} {string}')
  Future<void> iAdd(int quantity, String item) async {}

  @Then('the cart has {int} item(s)')
  Future<void> theCartHas(int count) async {}
}
''');

      // Act
      final report = await build();

      // Assert
      final test = read('cart/cart.bdd_test.dart');
      expect(test, contains("await steps.iAdd(2, 'apple');"));
      expect(test, contains('await steps.theCartHas(2);'));
      expect(File(path('cart/cart.bdd_steps.dart')).existsSync(), isFalse);
      expect(report.warnings, isEmpty);
    });

    test('creates a steps file when there is none and reports the undefined steps', () async {
      // Arrange
      write('cart/cart.feature', _cartFeature);

      // Act
      final report = await build();

      // Assert
      final steps = read('cart/cart_steps.dart');
      expect(steps, contains("import 'package:bdd_flutter/bdd_flutter.dart';"));
      expect(steps, contains('class ShoppingCartSteps {'));
      expect(steps, isNot(contains('tester')));
      expect(read('cart/cart.bdd_test.dart'), contains("fail('Undefined step: When I add 2 \"apple\"');"));
      expect(report.warnings, [
        'cart.feature: undefined step `When I add 2 "apple"`.',
        'cart.feature: undefined step `Then the cart has 2 items`.',
      ]);
    });

    test('never changes an existing steps file', () async {
      // Arrange
      write('cart/cart.feature', _cartFeature);
      const source = 'class ShoppingCartSteps {}\n';
      write('cart/cart_steps.dart', source);

      // Act
      await build();

      // Assert
      expect(read('cart/cart_steps.dart'), source);
    });

    test('gives new widget steps classes a tester, and warns when an existing one lacks it', () async {
      // Arrange
      write('cart/cart.feature', _cartFeature.replaceFirst('@unitTest\n', ''));
      write('login/login.feature', 'Feature: Login\n  Scenario: Tap\n    When I tap\n');
      write('login/login_steps.dart', 'class LoginSteps {}\n');

      // Act
      final report = await build(featurePaths: ['cart/cart.feature', 'login/login.feature']);

      // Assert
      expect(read('cart/cart_steps.dart'), contains('  late WidgetTester tester;'));
      expect(report.warnings, contains(contains('login.feature has widget tests; add `late WidgetTester tester;`')));
    });

    test('uses the shared mixin: new classes mix it in, missing mixins and unused steps are reported', () async {
      // Arrange
      write('shared_steps.dart', '''
import 'package:bdd_flutter/bdd_flutter.dart';

mixin SharedSteps {
  @When('I add {int} {string}')
  Future<void> iAdd(int quantity, String item) async {}

  @Given('nobody uses this')
  Future<void> unused() async {}
}
''');
      write('cart/cart.feature', _cartFeature);
      write('other/other.feature', '@unitTest\nFeature: Other\n  Scenario: A\n    When I add 1 "pear"\n');
      write('other/other_steps.dart', 'class OtherSteps {}\n');

      // Act
      final report = await build(featurePaths: ['cart/cart.feature', 'other/other.feature']);

      // Assert
      final steps = read('cart/cart_steps.dart');
      expect(steps, contains("import '../shared_steps.dart';"));
      expect(steps, contains('class ShoppingCartSteps with SharedSteps {'));
      expect(read('cart/cart.bdd_test.dart'), contains("await steps.iAdd(2, 'apple');"));
      expect(
        report.warnings,
        contains(
          'other.feature: step `When I add 1 "pear"` is defined in SharedSteps; mix it in with `with SharedSteps`.',
        ),
      );
      expect(report.warnings, contains('${path('shared_steps.dart')} has steps no feature uses: unused.'));
    });

    test('reports invalid expressions once, ambiguous steps, wrong arity and unused steps', () async {
      // Arrange
      write('cart/cart.feature', _cartFeature);
      write('cart/cart_steps.dart', '''
import 'package:bdd_flutter/bdd_flutter.dart';

class ShoppingCartSteps {
  @When('I add {int} {string}')
  Future<void> iAdd(int quantity) async {}

  @Then('the cart has {int} item(s)')
  Future<void> a(int count) async {}

  @Then('the cart has {} items')
  Future<void> b(String count) async {}

  @Given('the {colour} car')
  Future<void> broken(String colour) async {}

  @Given('never used')
  Future<void> neverUsed() async {}
}
''');

      // Act
      final warnings = (await build()).warnings;

      // Assert
      expect(warnings.where((w) => w.contains("Undefined parameter type 'colour'")), hasLength(1));
      expect(warnings, contains(startsWith('cart.feature: ambiguous step `Then the cart has 2 items` matches')));
      expect(warnings, contains(contains('ShoppingCartSteps.iAdd')));
      expect(warnings, contains(contains("takes 1 parameter(s) but `When I add 2 \"apple\"` passes 2")));
      expect(warnings, contains(endsWith('has steps no feature uses: neverUsed.')));
    });

    test('counts a method with several annotations as used when one is', () async {
      // Arrange
      write('cart/cart.feature', '@unitTest\nFeature: Shopping cart\n  Scenario: A\n    Given an empty cart\n');
      write('cart/cart_steps.dart', '''
class ShoppingCartSteps {
  @Given('a cart')
  @Given('an empty cart')
  Future<void> anEmptyCart() async {}
}
''');

      // Act
      final report = await build();

      // Assert
      expect(report.warnings, isEmpty);
    });

    test('skips features that still have an unmigrated 1.x scenarios file', () async {
      // Arrange
      write('cart/cart.feature', _cartFeature);
      write('cart/cart.bdd_scenarios.dart', '// 1.x\n');

      // Act
      await build();

      // Assert
      expect(File(path('cart/cart_steps.dart')).existsSync(), isFalse);
      expect(File(path('cart/cart.bdd_test.dart')).existsSync(), isFalse);
    });
  });
}
