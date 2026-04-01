import 'dart:io';

import 'package:bdd_flutter/src/domain/build_options.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/config_parser.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/manifest_parser.dart';
import 'package:bdd_flutter/src/presentation/controllers/bdd_controller.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String testDir;
  late String configDir;
  late String configFile;
  late String manifestFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bdd_controller_test_');
    testDir = '${tempDir.path}/test';
    configDir = '${tempDir.path}/.bdd_flutter';
    configFile = '$configDir/config.yaml';
    manifestFile = '$configDir/manifest.yaml';

    Directory(testDir).createSync(recursive: true);
    Directory(configDir).createSync(recursive: true);

    File(configFile).writeAsStringSync('test_dir: "$testDir/"');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  BDDController createController() {
    return BDDController(
      configParser: ConfigParser(configFile: configFile),
      manifestParser: ManifestParser(
        manifestDir: configDir,
        manifestFile: manifestFile,
      ),
    );
  }

  void writeFeatureFile(String name, String content) {
    File('$testDir/$name').writeAsStringSync(content);
  }

  group('BDDController incremental build', () {
    test('first build generates scenario and test files', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      expect(File('$testDir/login.bdd_scenarios.dart').existsSync(), isTrue);
      expect(File('$testDir/login.bdd_test.dart').existsSync(), isTrue);
    });

    test('unchanged feature is skipped on second build', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      final scenarioModified =
          File('$testDir/login.bdd_scenarios.dart').lastModifiedSync();

      // Small delay to detect timestamp change
      await Future.delayed(Duration(milliseconds: 50));
      await controller.generateFeatureTestCases();

      final scenarioModifiedAfter =
          File('$testDir/login.bdd_scenarios.dart').lastModifiedSync();
      expect(scenarioModifiedAfter, equals(scenarioModified));
    });

    test('adding a new scenario appends to scenario file', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      final originalContent =
          File('$testDir/login.bdd_scenarios.dart').readAsStringSync();
      expect(originalContent, contains('SuccessfulLoginScenario'));

      // Add a new scenario
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
  Scenario: Failed login
    Given I am on the login page
    When I enter invalid credentials
    Then I should see an error message
''');

      await controller.generateFeatureTestCases();

      final updatedContent =
          File('$testDir/login.bdd_scenarios.dart').readAsStringSync();
      expect(updatedContent, contains('SuccessfulLoginScenario'));
      expect(updatedContent, contains('FailedLoginScenario'));
    });

    test('renaming a scenario regenerates both files', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      // Rename scenario
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Valid login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      await controller.generateFeatureTestCases();

      final scenarioContent =
          File('$testDir/login.bdd_scenarios.dart').readAsStringSync();
      final testContent =
          File('$testDir/login.bdd_test.dart').readAsStringSync();

      // Old class should be gone, new class should be present
      expect(scenarioContent, isNot(contains('SuccessfulLoginScenario')));
      expect(scenarioContent, contains('ValidLoginScenario'));

      // Test file should reference the new class
      expect(testContent, contains('ValidLoginScenario'));
      expect(testContent, isNot(contains('SuccessfulLoginScenario')));
    });

    test('removing a scenario regenerates both files', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
  Scenario: Failed login
    Given I am on the login page
    When I enter invalid credentials
    Then I should see an error message
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      final originalContent =
          File('$testDir/login.bdd_scenarios.dart').readAsStringSync();
      expect(originalContent, contains('SuccessfulLoginScenario'));
      expect(originalContent, contains('FailedLoginScenario'));

      // Remove second scenario
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      await controller.generateFeatureTestCases();

      final updatedContent =
          File('$testDir/login.bdd_scenarios.dart').readAsStringSync();
      expect(updatedContent, contains('SuccessfulLoginScenario'));
      expect(updatedContent, isNot(contains('FailedLoginScenario')));
    });

    test('modifying a step regenerates both files', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      // Modify a step
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the dashboard
''');

      await controller.generateFeatureTestCases();

      final scenarioContent =
          File('$testDir/login.bdd_scenarios.dart').readAsStringSync();
      expect(scenarioContent, contains('iShouldSeeTheDashboard'));
      expect(scenarioContent, isNot(contains('iShouldSeeTheHomePage')));
    });

    test('deleted generated files are regenerated', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      // Delete generated files
      File('$testDir/login.bdd_scenarios.dart').deleteSync();
      File('$testDir/login.bdd_test.dart').deleteSync();

      await controller.generateFeatureTestCases();

      expect(File('$testDir/login.bdd_scenarios.dart').existsSync(), isTrue);
      expect(File('$testDir/login.bdd_test.dart').existsSync(), isTrue);
    });

    test('force regenerates even when unchanged', () async {
      writeFeatureFile('login.feature', '''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');

      final controller = createController();
      await controller.generateFeatureTestCases();

      // Corrupt the file to prove force overwrites it
      File('$testDir/login.bdd_scenarios.dart')
          .writeAsStringSync('corrupted');

      await controller.generateFeatureTestCases(
        options: const BuildOptions(force: true),
      );

      final content =
          File('$testDir/login.bdd_scenarios.dart').readAsStringSync();
      expect(content, contains('SuccessfulLoginScenario'));
      expect(content, isNot(contains('corrupted')));
    });
  });
}
