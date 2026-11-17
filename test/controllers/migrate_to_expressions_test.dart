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
    Given I am logged in as "ann"

  Scenario: Add
    When I add 2 "apple" at 1.5 each
    Then the note is:
      """
      thanks
      """

  Scenario Outline: Rows
    When I add <qty> <item> (each/all)
    Then the flag is <on>

    Examples:
      | qty | item  | on   |
      | 1   | pear  | true |
''';

const String _otherFeature = '''
Feature: Other
  Scenario: Login
    Given I am logged in as "bob"
''';

void main() {
  late Directory tempDir;
  late String testDir;
  late String configFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bdd_migrate_expressions_test_');
    testDir = '${tempDir.path}/test';
    configFile = '${tempDir.path}/.bdd_flutter/config.yaml';
    File('$testDir/cart/cart.feature')
      ..createSync(recursive: true)
      ..writeAsStringSync(_cartFeature);
    File('$testDir/other/other.feature')
      ..createSync(recursive: true)
      ..writeAsStringSync(_otherFeature);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  void config(String extra) {
    File(configFile)
      ..createSync(recursive: true)
      ..writeAsStringSync('test_dir: "$testDir/"\n$extra');
  }

  String read(String relative) => File('$testDir/$relative').readAsStringSync();
  bool exists(String relative) => File('$testDir/$relative').existsSync();

  Future<void> build() {
    return BDDController(
      configParser: ConfigParser(configFile: configFile),
      formatter: const NoFormatting(),
    ).generateFeatureTestCases();
  }

  Future<int> migrate() {
    return MigrateController(
      configParser: ConfigParser(configFile: configFile),
      formatter: const NoFormatting(),
    ).migrate();
  }

  group('MigrateController 2.x to expressions', () {
    test('annotates steps files and the shared mixin, removes contracts and rebuilds the tests', () async {
      // Arrange: a 2.x project
      config('steps_mode: contract\n');
      await build();
      expect(exists('cart/cart.bdd_steps.dart'), isTrue);
      expect(exists('shared_steps.dart'), isTrue);

      // Act
      config('');
      final failed = await migrate();

      // Assert
      expect(failed, 0);
      expect(exists('cart/cart.bdd_steps.dart'), isFalse);
      expect(exists('other/other.bdd_steps.dart'), isFalse);
      final steps = read('cart/cart_steps.dart');
      expect(steps, contains("import 'package:bdd_flutter/bdd_flutter.dart';"));
      expect(steps, isNot(contains('implements')));
      expect(steps, isNot(contains('@override\n  Future')));
      expect(steps, contains('  @override\n  late WidgetTester tester;'), reason: 'the mixin declares tester');
      expect(steps, isNot(contains('bdd_steps.dart')));
      expect(steps, contains("@When('I add {num} {string} at {num} each')"));
      expect(steps, contains("@Then('the note is:')"));
      expect(steps, contains(r"@When(r'I add {num} {} \(each\/all\)')"));
      expect(steps, contains("@Then('the flag is {bool}')"));
      expect(read('shared_steps.dart'), contains("@Given('I am logged in as {string}')"));

      final test = read('cart/cart.bdd_test.dart');
      expect(test, isNot(contains('fail(')));
      expect(test, contains("await steps.iAmLoggedInAs('ann');"));
      expect(test, contains("await steps.iAddAtEach(2, 'apple', 1.5);"));
      expect(test, contains("await steps.theNoteIs('thanks');"));
      expect(test, contains("'pear'"));
      expect(test, contains('true);'));
      expect(read('other/other.bdd_test.dart'), contains("await steps.iAmLoggedInAs('bob');"));
    });

    test('keeps the contract of a steps file whose class it cannot find', () async {
      // Arrange
      config('steps_mode: contract\n');
      await build();
      final path = '$testDir/cart/cart_steps.dart';
      File(
        path,
      ).writeAsStringSync(read('cart/cart_steps.dart').replaceAll('class ShoppingCartSteps', 'class CartSteps'));

      // Act
      config('');
      await migrate();

      // Assert
      expect(exists('cart/cart.bdd_steps.dart'), isTrue);
      expect(
        read('cart/cart_steps.dart'),
        contains('class CartSteps with SharedSteps implements ShoppingCartStepsContract'),
      );
    });

    test('annotates the shared mixin only with steps shared by several features', () async {
      // Arrange
      config('steps_mode: contract\n');
      await build();
      // A mixin method named like a cart-only step.
      final shared = read(
        'shared_steps.dart',
      ).replaceFirst(RegExp(r'\n}\s*$'), '\n  Future<void> theNoteIs(String docString) async {}\n}\n');
      File('$testDir/shared_steps.dart').writeAsStringSync(shared);

      // Act
      config('');
      await migrate();

      // Assert
      final mixin = read('shared_steps.dart');
      expect(mixin, contains("@Given('I am logged in as {string}')"));
      expect(mixin, isNot(contains("'the note is:'")));
    });

    test('changes nothing a second time', () async {
      // Arrange
      config('steps_mode: contract\n');
      await build();
      config('');
      await migrate();
      final before = read('cart/cart_steps.dart');

      // Act
      await migrate();

      // Assert
      expect(read('cart/cart_steps.dart'), before);
    });

    test('stops after the 1.x step in contract mode', () async {
      // Arrange
      config('steps_mode: contract\n');
      await build();

      // Act
      await migrate();

      // Assert
      expect(exists('cart/cart.bdd_steps.dart'), isTrue);
      expect(read('cart/cart_steps.dart'), contains('implements ShoppingCartStepsContract'));
    });
  });
}
