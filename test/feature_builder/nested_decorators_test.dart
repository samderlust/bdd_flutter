import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_feature_builder.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:bdd_flutter/src/feature/builder/domain/decorator.dart';
import 'package:test/test.dart';

void main() {
  test('Builder disabled reporter', () {
    final feature1Text = '''
Feature: Feature 1
  Scenario: Scenario 1
    Given I have a feature 1
    When I do something
    Then I should see a feature 1
  Scenario: Scenario 2
    Given I have a feature 2
    When I do something
    Then I should see a feature 2
''';

    final feature2Text = '''
@enableReporter
Feature: Feature 2
  Scenario: Scenario 2
    Given I have a feature 2
    When I do something
    Then I should see a feature 2
  Scenario: Scenario 3
    Given I have a feature 3
    When I do something
    Then I should see a feature 3
''';
    final featureBuilder = BDDFeatureBuilder(
      options: BDDOptions(generateWidgetTests: true),
    );
    final feature1 = featureBuilder.parseFeature(feature1Text)!;
    final feature2 = featureBuilder.parseFeature(feature2Text)!;
    expect(feature1.name, 'Feature 1');
    expect(feature1.scenarios.length, 2);
    expect(feature1.decorators.hasEnableReporter, false);

    expect(feature2.name, 'Feature 2');
    expect(feature2.decorators.hasEnableReporter, true);
    expect(feature2.scenarios.length, 2);
  });
  test('Builder enabled reporter', () {
    final feature1Text = '''
Feature: Feature 1
  Scenario: Scenario 1
    Given I have a feature 1
    When I do something
    Then I should see a feature 1
  Scenario: Scenario 2
    Given I have a feature 2
    When I do something
    Then I should see a feature 2
''';

    final feature2Text = '''
@disableReporter
Feature: Feature 2
  Scenario: Scenario 2
    Given I have a feature 2
    When I do something
    Then I should see a feature 2
  Scenario: Scenario 3
    Given I have a feature 3
    When I do something
    Then I should see a feature 3
''';
    final featureBuilder = BDDFeatureBuilder(
      options: BDDOptions(
        generateWidgetTests: true,
        enableReporter: true,
      ),
    );
    final feature1 = featureBuilder.parseFeature(feature1Text)!;
    final feature2 = featureBuilder.parseFeature(feature2Text)!;
    expect(feature1.name, 'Feature 1');
    expect(feature1.scenarios.length, 2);
    expect(feature1.decorators.hasEnableReporter, true);

    expect(feature2.name, 'Feature 2');
    expect(feature2.decorators.hasEnableReporter, false);
    expect(feature2.scenarios.length, 2);
  });
}
