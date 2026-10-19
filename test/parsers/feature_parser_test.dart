import 'dart:io';

import 'package:bdd_flutter/src/domain/decorator.dart';
import 'package:bdd_flutter/src/domain/step_keyword_type.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/feature_parse_exception.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/feature_parser.dart';
import 'package:test/test.dart';

void main() {
  late FeatureParser parser;
  late Directory tempDir;

  setUp(() {
    parser = const FeatureParser();
    tempDir = Directory.systemTemp.createTempSync('bdd_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  File createFeatureFile(String content) {
    final file = File('${tempDir.path}/test.feature');
    file.writeAsStringSync(content);
    return file;
  }

  group('FeatureParser', () {
    test('parses feature name', () async {
      final file = createFeatureFile('''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.name, equals('Login'));
    });

    test('parses scenario name', () async {
      final file = createFeatureFile('''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.scenarios.length, equals(1));
      expect(feature.scenarios.first.name, equals('Successful login'));
    });

    test('parses Given/When/Then steps', () async {
      final file = createFeatureFile('''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the home page
''');
      final feature = await parser.parseFeature(file.path);
      final steps = feature.scenarios.first.steps;
      expect(steps.length, equals(3));
      expect(steps[0].keyword, equals('Given'));
      expect(steps[0].text, equals('I am on the login page'));
      expect(steps[1].keyword, equals('When'));
      expect(steps[1].text, equals('I enter valid credentials'));
      expect(steps[2].keyword, equals('Then'));
      expect(steps[2].text, equals('I should see the home page'));
    });

    test('parses And steps', () async {
      final file = createFeatureFile('''
Feature: Login
  Scenario: Successful login
    Given I am on the login page
    And I have a valid account
    When I enter valid credentials
    Then I should see the home page
''');
      final feature = await parser.parseFeature(file.path);
      final steps = feature.scenarios.first.steps;
      expect(steps.length, equals(4));
      expect(steps[1].keyword, equals('And'));
      expect(steps[1].text, equals('I have a valid account'));
    });

    test('parses multiple scenarios', () async {
      final file = createFeatureFile('''
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
      final feature = await parser.parseFeature(file.path);
      expect(feature.scenarios.length, equals(2));
      expect(feature.scenarios[0].name, equals('Successful login'));
      expect(feature.scenarios[1].name, equals('Failed login'));
    });

    test('parses Background', () async {
      final file = createFeatureFile('''
Feature: Counter
  Background: Counter starts at 0
    Given I have a counter with value 0
  Scenario: Increment
    When I increment the counter
    Then the counter should have value 1
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.background, isNotNull);
      expect(feature.background!.description, equals('Counter starts at 0'));
      expect(feature.background!.steps.length, equals(1));
      expect(feature.background!.steps.first.text, equals('I have a counter with value 0'));
    });

    test('parses Examples table', () async {
      final file = createFeatureFile('''
Feature: Calculator
  Scenario: Add two numbers
    Given I have a calculator
    When I add <a> and <b>
    Then the result should be <result>
    Examples:
      | a | b | result |
      | 1 | 2 | 3      |
      | 5 | 3 | 8      |
''');
      final feature = await parser.parseFeature(file.path);
      final scenario = feature.scenarios.first;
      final rows = scenario.examples.single.rows;
      expect(rows, hasLength(2));
      expect(rows[0], equals({'a': '1', 'b': '2', 'result': '3'}));
      expect(rows[1], equals({'a': '5', 'b': '3', 'result': '8'}));
    });

    test('parses @unitTest decorator on scenario', () async {
      final file = createFeatureFile('''
Feature: Calculator
  @unitTest
  Scenario: Add two numbers
    Given I have a calculator
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.scenarios.first.decorators.hasUnitTest, isTrue);
    });

    test('parses @widgetTest decorator on scenario', () async {
      final file = createFeatureFile('''
Feature: Counter
  @widgetTest
  Scenario: Increment
    Given I have a counter
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.scenarios.first.decorators.hasWidgetTest, isTrue);
    });

    test('parses feature with no scenarios returns empty list', () async {
      final file = createFeatureFile('''
Feature: Empty
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.name, equals('Empty'));
      expect(feature.scenarios, isEmpty);
    });

    test('parses @unitTest on feature applies to scenarios', () async {
      final file = createFeatureFile('''
@unitTest
Feature: Calculator
  Scenario: Add
    Given I have a calculator
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.decorators.hasUnitTest, isTrue);
      expect(feature.scenarios.first.decorators, isEmpty);
    });

    test('keeps feature and scenario decorators apart', () async {
      final file = createFeatureFile('''
@unitTest
Feature: Calculator
  @widgetTest
  Scenario: Widget scenario
    Given something
  Scenario: Unit scenario
    Given something else
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.decorators, equals({Decorator.unitTest}));
      expect(feature.scenarios[0].decorators, equals({Decorator.widgetTest}));
      expect(feature.scenarios[1].decorators, isEmpty);
    });

    test('parses multiple scenarios with Examples', () async {
      final file = createFeatureFile('''
Feature: Calculator
  Scenario: Add
    When I add <a> and <b>
    Then the result is <result>
    Examples:
      | a | b | result |
      | 1 | 2 | 3      |
  Scenario: Subtract
    When I subtract <b> from <a>
    Then the result is <result>
    Examples:
      | a | b | result |
      | 5 | 3 | 2      |
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.scenarios.length, equals(2));
      expect(feature.scenarios[0].examples.single.rows, hasLength(1));
      expect(feature.scenarios[1].examples.single.rows, hasLength(1));
    });
  });

  group('FeatureParser full Gherkin support', () {
    test('parses But and * steps', () async {
      final file = createFeatureFile('''
Feature: Cart
  Scenario: Checkout
    Given I have items
    But I am not logged in
    * I open the cart
''');
      final steps = (await parser.parseFeature(file.path)).scenarios.first.steps;
      expect(steps.map((s) => s.keyword), equals(['Given', 'But', '*']));
      expect(steps[1].text, equals('I am not logged in'));
    });

    test('maps keyword types', () async {
      final file = createFeatureFile('''
Feature: Login
  Scenario: Login
    Given a user
    And a password
    When I log in
    Then I see home
''');
      final steps = (await parser.parseFeature(file.path)).scenarios.first.steps;
      expect(
        steps.map((s) => s.keywordType),
        equals([StepKeywordType.context, StepKeywordType.conjunction, StepKeywordType.action, StepKeywordType.outcome]),
      );
    });

    test('parses several tags on one line', () async {
      final file = createFeatureFile('''
Feature: Calculator
  @smoke @unitTest
  Scenario: Add
    Given a calculator
''');
      final scenario = (await parser.parseFeature(file.path)).scenarios.first;
      expect(scenario.decorators, equals({Decorator.unitTest}));
      expect(scenario.tags, equals({'smoke'}));
    });

    test('maps @skip to a decorator and keeps tags on feature, rule and Examples', () async {
      final file = createFeatureFile('''
@cart
Feature: Cart
  @skip
  Scenario Outline: Add
    When I add <a>
    @eu
    Examples: Europe
      | a |
      | 1 |
  @slow
  Rule: Closed
    Scenario: Close
      Given a cart
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.tags, equals({'cart'}));
      expect(feature.scenarios.single.decorators, equals({Decorator.skip}));
      expect(feature.scenarios.single.examples.single.tags, equals({'eu'}));
      expect(feature.rules.single.tags, equals({'slow'}));
    });

    test('parses Scenario Outline', () async {
      final file = createFeatureFile('''
Feature: Calculator
  Scenario Outline: Add
    When I add <a> and <b>
    Examples:
      | a | b |
      | 1 | 2 |
''');
      final scenario = (await parser.parseFeature(file.path)).scenarios.single;
      expect(scenario.name, equals('Add'));
      expect(
        scenario.examples.single.rows,
        equals([
          {'a': '1', 'b': '2'},
        ]),
      );
    });

    test('keeps each Examples block with its name', () async {
      final file = createFeatureFile('''
Feature: Calculator
  Scenario Outline: Add
    When I add <a> and <b>
    Examples: small
      | a | b |
      | 1 | 2 |
    Examples: large
      | a   | b   |
      | 100 | 200 |
''');
      final scenario = (await parser.parseFeature(file.path)).scenarios.single;
      expect(scenario.examples.map((t) => t.name), equals(['small', 'large']));
      expect(scenario.examples[1].rows.single, equals({'a': '100', 'b': '200'}));
    });

    test('keeps pipes escaped inside example cells', () async {
      final file = createFeatureFile(r"""
Feature: Strings
  Scenario: Split
    When I split <input>
    Examples:
      | input  |
      | a\|b   |
""");
      final scenario = (await parser.parseFeature(file.path)).scenarios.single;
      expect(scenario.examples.single.rows.single, equals({'input': 'a|b'}));
    });

    test('ignores comments', () async {
      final file = createFeatureFile('''
# Owner: payments team
Feature: Pay
  # Happy path
  Scenario: Pay
    Given a card
''');
      final feature = await parser.parseFeature(file.path);
      expect(feature.scenarios.single.steps.single.text, equals('a card'));
    });

    test('maps Rule with its own background and scenarios', () async {
      final file = createFeatureFile('''
Feature: Accounts
  Scenario: Open
    Given nothing
  @unitTest
  Rule: Closed accounts
    Background:
      Given a closed account
    Scenario: Deposit
      When I deposit 5
''');
      final feature = await parser.parseFeature(file.path);
      final rule = feature.rules.single;
      expect(feature.scenarios.map((s) => s.name), equals(['Open']));
      expect(rule.name, equals('Closed accounts'));
      expect(rule.background!.steps.single.text, equals('a closed account'));
      expect(rule.scenarios.single.steps.map((s) => s.text), equals(['I deposit 5']));
      expect(rule.decorators, equals({Decorator.unitTest}));
    });

    test('parses non-English keywords', () async {
      final file = createFeatureFile('''
# language: fr
Fonctionnalité: Compteur
  Scénario: Incrémenter
    Soit un compteur à 0
    Quand j'incrémente
    Alors le compteur vaut 1
''');
      final feature = await parser.parseFeature(file.path);
      final steps = feature.scenarios.single.steps;
      expect(feature.name, equals('Compteur'));
      expect(steps.first.keyword, equals('Soit'));
      expect(steps.first.keywordType, equals(StepKeywordType.context));
    });

    test('throws FeatureParseException with line and column', () async {
      final file = createFeatureFile('''
Feature: Broken
  Scenario: A
    Given b
  this line is not Gherkin
''');
      expect(
        () => parser.parseFeature(file.path),
        throwsA(isA<FeatureParseException>().having((e) => e.errors.single, 'error', startsWith('(4:3)'))),
      );
    });

    test('empty file returns unnamed feature', () async {
      final file = createFeatureFile('');
      final feature = await parser.parseFeature(file.path);
      expect(feature.name, equals('Unnamed Feature'));
      expect(feature.scenarios, isEmpty);
    });
  });

  group('FeatureParser doc strings and data tables', () {
    test('maps doc string content and data table rows', () async {
      final file = createFeatureFile('''
Feature: Orders
  Scenario: Post
    Given the products:
      | name  | price |
      | apple | 1.5   |
    When I post:
      """json
      {"item": "apple"}
      """
''');
      final steps = (await parser.parseFeature(file.path)).scenarios.single.steps;
      expect(
        steps[0].dataTable,
        equals([
          ['name', 'price'],
          ['apple', '1.5'],
        ]),
      );
      expect(steps[0].docString, isNull);
      expect(steps[1].docString, equals('{"item": "apple"}'));
    });
  });
}
