import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_feature_builder.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:bdd_flutter/src/feature/builder/domain/decorator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BDDFeatureBuilder featureBuilder;

  setUp(() {
    featureBuilder = BDDFeatureBuilder(options: BDDOptions.defaultOptions());
  });

  group('parseFeature', () {
    test('should parse basic feature with single scenario', () {
      const featureContent = '''
Feature: Login functionality
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should be logged in successfully
''';

      final feature = featureBuilder.parseFeature(featureContent);

      expect(feature.name, equals('Login functionality'));
      expect(feature.scenarios.length, equals(1));
      expect(feature.scenarios[0].name, equals('Successful login'));
      expect(feature.scenarios[0].steps.length, equals(3));
      expect(feature.scenarios[0].steps[0].keyword, equals('Given'));
      expect(feature.scenarios[0].steps[0].text, equals('I am on the login page'));
    });

    test('should parse feature with decorators', () {
      const featureContent = '''
@enableReporter
Feature: User registration
  @unitTest
  Scenario: Register with valid data
    Given I am on the registration page
    When I fill in valid registration data
    Then I should be registered successfully
''';

      final feature = featureBuilder.parseFeature(featureContent);

      expect(feature.name, equals('User registration'));
      expect(feature.decorators.length, equals(1));
      expect(feature.decorators.contains(BDDDecorator.enableReporter()), isTrue);
      expect(feature.scenarios[0].decorators.contains(BDDDecorator.unitTest()), isTrue);
    });

    test('should parse feature with examples', () {
      const featureContent = '''
Feature: Calculator
  Scenario: Add two numbers
    Given I have entered <number1> into the calculator
    And I have entered <number2> into the calculator
    When I press add
    Then the result should be <result>

    Examples:
      | number1 | number2 | result |
      | 1       | 2       | 3      |
      | 5       | 5       | 10     |
''';

      final feature = featureBuilder.parseFeature(featureContent);

      expect(feature.name, equals('Calculator'));
      expect(feature.scenarios.length, equals(1));
      expect(feature.scenarios[0].examples, isNotNull);
      expect(feature.scenarios[0].examples!.length, equals(2));
      expect(feature.scenarios[0].examples![0]['number1'], equals('1'));
      expect(feature.scenarios[0].examples![0]['result'], equals('3'));
    });

    test('should parse feature with multiple scenarios', () {
      const featureContent = '''
Feature: Search functionality
  Scenario: Search with valid keyword
    Given I am on the search page
    When I enter a valid search term
    Then I should see relevant results

  Scenario: Search with empty keyword
    Given I am on the search page
    When I enter an empty search term
    Then I should see an error message
''';

      final feature = featureBuilder.parseFeature(featureContent);

      expect(feature.name, equals('Search functionality'));
      expect(feature.scenarios.length, equals(2));
      expect(feature.scenarios[0].name, equals('Search with valid keyword'));
      expect(feature.scenarios[1].name, equals('Search with empty keyword'));
    });

    test('should throw exception when no feature is defined', () {
      const featureContent = '''
Scenario: Invalid feature file
  Given some precondition
  When some action
  Then some result
''';

      expect(
        () => featureBuilder.parseFeature(featureContent),
        throwsException,
      );
    });

    test('should handle @ignore decorator', () {
      const featureContent = '''
@ignore
Feature: Ignored feature
  Scenario: This should be ignored
    Given some precondition
    When some action
    Then some result
''';

      final feature = featureBuilder.parseFeature(featureContent);
      expect(feature.name, isEmpty);
      expect(feature.scenarios, isEmpty);
    });

    test('should handle empty feature content', () {
      const featureContent = '';

      expect(
        () => featureBuilder.parseFeature(featureContent),
        throwsException,
      );
    });

    test('should handle feature with only whitespace', () {
      const featureContent = '   \n  \t  ';

      expect(
        () => featureBuilder.parseFeature(featureContent),
        throwsException,
      );
    });

    test('should handle scenario with And/But steps', () {
      const featureContent = '''
Feature: Complex steps
  Scenario: Using And/But steps
    Given I am on the page
    And I am logged in
    When I click the button
    But I wait for 2 seconds
    Then I should see the result
    And the result should be correct
''';

      final feature = featureBuilder.parseFeature(featureContent);
      expect(feature.scenarios[0].steps.length, equals(6));
      expect(feature.scenarios[0].steps[1].keyword, equals('And'));
      expect(feature.scenarios[0].steps[3].keyword, equals('But'));
    });

    test('should handle scenario with empty steps', () {
      const featureContent = '''
Feature: Empty steps
  Scenario: Empty step scenario
    Given 
    When 
    Then 
''';

      final feature = featureBuilder.parseFeature(featureContent);
      expect(feature.scenarios[0].steps.length, equals(3));
      expect(feature.scenarios[0].steps[0].text, isEmpty);
    });

    test('should handle feature with special characters in names', () {
      const featureContent = '''
Feature: Special @#\$%^&*() characters
  Scenario: Test with special chars !@#\$%^&*()
    Given I have special chars
    When I process them
    Then they should be handled correctly
''';

      final feature = featureBuilder.parseFeature(featureContent);
      expect(feature.name, equals('Special @#\$%^&*() characters'));
      expect(feature.scenarios[0].name, equals('Test with special chars !@#\$%^&*()'));
    });
  });
}
