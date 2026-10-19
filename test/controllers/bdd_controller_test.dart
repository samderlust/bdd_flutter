import 'dart:io';

import 'package:bdd_flutter/src/infrastructure/formatting/code_formatter.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/config_parser.dart';
import 'package:bdd_flutter/src/presentation/controllers/bdd_controller.dart';
import 'package:bdd_flutter/src/presentation/controllers/migrate_controller.dart';
import 'package:test/test.dart';

const String _cartFeature = '''
@unitTest
Feature: Shopping cart
  Background:
    Given an empty cart

  Scenario: Add
    When I add 2 "apple"
    Then the cart has 2 items

  Scenario: Remove
    When I remove "apple"
''';

const String _legacyCartScenarios = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:example/cart.dart';

/// Shared between classes.
late Cart cart;

class ShoppingCartBackground {
  Future<void> anEmptyCart() async {
    // Braces in strings and comments must not confuse the reader: '}' "{"
    cart = Cart(label: '\${'}'}');
  }
}

class AddScenario {
  int added = 0;

  AddScenario();

  Future<void> iAdd2Apple() async {
    cart.add('apple', 2);
  }

  Future<void> theCartHas2Items() async {
    // TODO: Implement Then the cart has 2 items
  }
}

class RemoveScenario {
  Future<void> iRemoveApple() async {
    cart.remove('apple');
  }
}
''';

void main() {
  late Directory tempDir;
  late String testDir;
  late String configFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bdd_controller_test_');
    testDir = '${tempDir.path}/test';
    configFile = '${tempDir.path}/.bdd_flutter/config.yaml';
    Directory(testDir).createSync(recursive: true);
    File(configFile)
      ..createSync(recursive: true)
      ..writeAsStringSync('test_dir: "$testDir/"');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  BDDController buildController() {
    return BDDController(
      configParser: ConfigParser(configFile: configFile),
      formatter: const NoFormatting(),
    );
  }

  String read(String name) => File('$testDir/$name').readAsStringSync();

  group('BDDController.generateFeatureTestCases', () {
    test('creates the contract, the test file and the user steps file', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);

      final failed = await buildController().generateFeatureTestCases();

      expect(failed, 0);
      expect(read('cart.bdd_steps.dart'), contains('abstract interface class ShoppingCartStepsContract'));
      expect(read('cart.bdd_test.dart'), contains("await steps.iAdd(2, 'apple');"));
      expect(read('cart_steps.dart'), contains('class ShoppingCartSteps implements ShoppingCartStepsContract'));
    });

    test('never overwrites the user steps file, but rewrites generated files', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      await buildController().generateFeatureTestCases();
      File('$testDir/cart_steps.dart').writeAsStringSync('// my code');

      File('$testDir/cart.feature').writeAsStringSync('$_cartFeature\n  Scenario: Clear\n    When I clear the cart\n');
      await buildController().generateFeatureTestCases();

      expect(read('cart_steps.dart'), '// my code');
      expect(read('cart.bdd_steps.dart'), contains('Future<void> iClearTheCart();'));
      expect(read('cart.bdd_test.dart'), contains("test('Clear', () async {"));
    });

    test('skips a feature that still has a 1.x scenarios file', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      File('$testDir/cart.bdd_scenarios.dart').writeAsStringSync(_legacyCartScenarios);

      await buildController().generateFeatureTestCases();

      expect(File('$testDir/cart_steps.dart').existsSync(), isFalse);
      expect(File('$testDir/cart.bdd_test.dart').existsSync(), isFalse);
    });

    test('counts features that fail to parse and builds the others', () async {
      File('$testDir/broken.feature').writeAsStringSync('Feature: Broken\n  Scenario: A\n    Given b\n  not Gherkin\n');
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);

      final failed = await buildController().generateFeatureTestCases();

      expect(failed, 1);
      expect(File('$testDir/cart.bdd_test.dart').existsSync(), isTrue);
    });

    test('skips features listed in ignore_features', () async {
      File(configFile).writeAsStringSync('test_dir: "$testDir/"\nignore_features:\n  - cart.feature\n');
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);

      await buildController().generateFeatureTestCases();

      expect(File('$testDir/cart.bdd_test.dart').existsSync(), isFalse);
    });
  });

  group('BDDController shared steps', () {
    const login = """
@unitTest
Feature: Login
  Scenario: Log in
    Given an empty cart
    When I log in
""";

    test('creates a shared mixin the first time steps are shared, and new classes use it', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      File('$testDir/login.feature').writeAsStringSync(login);

      await buildController().generateFeatureTestCases();

      expect(read('shared_steps.dart'), contains('mixin SharedSteps {'));
      expect(read('shared_steps.dart'), contains('Future<void> anEmptyCart() async {'));
      expect(File('$testDir/shared.bdd_steps.dart').existsSync(), isFalse);
      expect(
        read('cart_steps.dart'),
        contains('class ShoppingCartSteps with SharedSteps implements ShoppingCartStepsContract {'),
      );
      expect(read('cart_steps.dart'), contains("import 'shared_steps.dart';"));
      expect(read('cart_steps.dart'), isNot(contains('anEmptyCart')));
      expect(read('cart.bdd_steps.dart'), contains('Future<void> anEmptyCart();'));
      expect(read('cart.bdd_test.dart'), contains('await steps.anEmptyCart();'));
    });

    test('leaves existing steps files alone when a step becomes shared', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      await buildController().generateFeatureTestCases();
      final cartSteps = read('cart_steps.dart');

      File('$testDir/login.feature').writeAsStringSync(login);
      await buildController().generateFeatureTestCases();

      expect(read('cart_steps.dart'), cartSteps);
      expect(read('login_steps.dart'), contains('with SharedSteps'));
    });

    test('never changes the mixin; later shared steps stay in the new class', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      File('$testDir/login.feature').writeAsStringSync(login);
      await buildController().generateFeatureTestCases();
      final mixin = read('shared_steps.dart');

      File('$testDir/checkout.feature').writeAsStringSync(
        '@unitTest\nFeature: Checkout\n  Scenario: Pay\n    Given an empty cart\n    When I remove "apple"\n',
      );
      await buildController().generateFeatureTestCases();

      expect(read('shared_steps.dart'), mixin);
      expect(read('checkout_steps.dart'), contains('with SharedSteps'));
      expect(read('checkout_steps.dart'), isNot(contains('anEmptyCart')));
      expect(read('checkout_steps.dart'), contains('Future<void> iRemove(String text) async {'));
    });

    test('gives unit-test classes a tester when the mixin declares one', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      File('$testDir/login.feature').writeAsStringSync(login.replaceFirst('@unitTest\n', ''));

      await buildController().generateFeatureTestCases();

      expect(read('shared_steps.dart'), contains('WidgetTester get tester;'));
      expect(read('cart_steps.dart'), contains('late WidgetTester tester;'));
      expect(read('cart.bdd_steps.dart'), isNot(contains('WidgetTester')));
    });

    test('does not mix in the shared steps when one has other parameter types', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      File('$testDir/login.feature').writeAsStringSync(login);
      await buildController().generateFeatureTestCases();
      File('$testDir/shared_steps.dart').writeAsStringSync(
        'mixin SharedSteps {\n  Future<void> anEmptyCart() async {}\n  Future<void> iRemove(num number) async {}\n}\n',
      );

      File('$testDir/checkout.feature').writeAsStringSync(
        '@unitTest\nFeature: Checkout\n  Scenario: Pay\n    Given an empty cart\n    When I remove "apple"\n',
      );
      await buildController().generateFeatureTestCases();

      expect(read('checkout_steps.dart'), isNot(contains('SharedSteps')));
      expect(read('checkout_steps.dart'), contains('Future<void> anEmptyCart() async {'));
      expect(read('checkout_steps.dart'), contains('Future<void> iRemove(String text) async {'));
    });

    test('creates no shared mixin when no step is shared', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);

      await buildController().generateFeatureTestCases();

      expect(File('$testDir/shared_steps.dart').existsSync(), isFalse);
      expect(read('cart_steps.dart'), isNot(contains('SharedSteps')));
    });
  });

  group('MigrateController.migrate', () {
    MigrateController migrateController() {
      return MigrateController(
        configParser: ConfigParser(configFile: configFile),
        formatter: const NoFormatting(),
      );
    }

    test('carries 1.x code into the new steps file and keeps the old file as .bak', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      File('$testDir/cart.bdd_scenarios.dart').writeAsStringSync(_legacyCartScenarios);

      final failed = await migrateController().migrate();
      final steps = read('cart_steps.dart');

      expect(failed, 0);
      expect(File('$testDir/cart.bdd_scenarios.dart').existsSync(), isFalse);
      expect(File('$testDir/cart.bdd_scenarios.dart.bak').existsSync(), isTrue);
      expect(steps, contains("import 'package:example/cart.dart';"));
      expect(steps, contains('late Cart cart;'));
      expect(steps, contains('int added = 0;'));
      expect(steps, isNot(contains('AddScenario()')));
      expect(steps, contains("    cart = Cart(label: '\${'}'}');"));
      expect(steps, contains("    //   cart.add('apple', 2);"));
      expect(steps, contains("    //   cart.remove('apple');"));
      expect(steps, contains("throw UnimplementedError('Then the cart has 2 items');"));
      expect(read('cart.bdd_test.dart'), contains("await steps.iAdd(2, 'apple');"));
    });

    test('leaves features that already have a steps file alone', () async {
      File('$testDir/cart.feature').writeAsStringSync(_cartFeature);
      File('$testDir/cart.bdd_scenarios.dart').writeAsStringSync(_legacyCartScenarios);
      File('$testDir/cart_steps.dart').writeAsStringSync('// my code');

      await migrateController().migrate();

      expect(read('cart_steps.dart'), '// my code');
      expect(File('$testDir/cart.bdd_scenarios.dart').existsSync(), isTrue);
    });
  });
}
