import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_feature_builder.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:bdd_flutter/src/feature/builder/domain/decorator.dart';
import 'package:bdd_flutter/src/feature/builder/domain/scenario.dart';
import 'package:test/test.dart';

void main() {
  final featureBuilder = BDDFeatureBuilder(
    options: BDDOptions(generateWidgetTests: true),
  );
  group('Parse feature file with default options', () {
    test('widget test by default', () {
      const featureContent = '''
Feature: Comms Permissions
    Scenario: Create a direct channel with permission
        Given a user <has_permission> "comms:channel:direct:create" permission
        When user attempts to create a direct channel
        Then <expected_result>
        Examples:
            | has_permission | expected_result                     |
            | true           | shows the create new DM chat button |
            | false          | hides the create new DM chat button |
    ''';
      final feature = featureBuilder.parseFeature(featureContent);
      expect(feature.name, equals('Comms Permissions'));
      expect(feature.scenarios.length, equals(1));
      final scenario = feature.scenarios.first;
      expect(scenario.isWidgetTest, isTrue);

      expect(scenario.steps.length, equals(3));
      expect(scenario.examples?.length, equals(2));
    });

    test('feature decorator override default', () {
      const featureContent = '''
@unitTest
Feature: Comms Permissions
    Scenario: Create a direct channel with permission
        Given a user <has_permission> "comms:channel:direct:create" permission
        When user attempts to create a direct channel
        Then <expected_result>
    ''';
      final feature = featureBuilder.parseFeature(featureContent);
      expect(feature.name, equals('Comms Permissions'));
      expect(feature.scenarios.length, equals(1));
      expect(feature.decorators, contains(BDDDecorator.unitTest()));
      expect(feature.scenarios[0].decorators, contains(BDDDecorator.unitTest()));
    });
    test('scenario decorator override feature decorator', () {
      const featureContent = '''
@unitTest
Feature: Comms Permissions
    @widgetTest
    Scenario: Create a direct channel with permission
        Given a user <has_permission> "comms:channel:direct:create" permission
        When user attempts to create a direct channel
        Then <expected_result>
    ''';
      final feature = featureBuilder.parseFeature(featureContent);
      expect(feature.name, equals('Comms Permissions'));
      expect(feature.scenarios.length, equals(1));
      expect(feature.decorators, contains(BDDDecorator.unitTest()));
      expect(
        feature.scenarios.first.decorators,
        contains(BDDDecorator.widgetTest()),
      );
    });
  });
}
