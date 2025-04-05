import 'package:bdd_flutter/src/domain/decorator_enum.dart';
import 'package:bdd_flutter/src/parser.dart';
import 'package:test/test.dart';

void main() {
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
      final feature = parseFeatureFile(featureContent, true);
      expect(feature.name, 'Comms Permissions');
      expect(feature.scenarios.length, 1);
      final scenario = feature.scenarios.first;
      expect(scenario.decorators, contains(DecoratorEnum.widgetTest));

      expect(scenario.steps.length, 3);
      expect(scenario.examples?.length, 2);
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
      final feature = parseFeatureFile(featureContent, true);
      expect(feature.name, 'Comms Permissions');
      expect(feature.scenarios.length, 1);
      expect(feature.decorators, contains(DecoratorEnum.unitTest));
      expect(feature.scenarios[0].decorators, contains(DecoratorEnum.unitTest));
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
      final feature = parseFeatureFile(featureContent, true);
      expect(feature.name, 'Comms Permissions');
      expect(feature.scenarios.length, 1);
      expect(feature.decorators, contains(DecoratorEnum.unitTest));
      expect(
        feature.scenarios.first.decorators,
        contains(DecoratorEnum.widgetTest),
      );
    });
  });
}
