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
      expect(read('cart.bdd_steps.g.dart'), contains('abstract interface class ShoppingCartStepsContract'));
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
      expect(read('cart.bdd_steps.g.dart'), contains('Future<void> iClearTheCart();'));
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
