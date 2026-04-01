import 'package:flutter_test/flutter_test.dart';
import 'sample.bdd_scenarios.dart';

void main() {
  group('Sample', () {
    testWidgets('Sample', (tester) async {
      final scenario = SampleScenario();
      //Scenario: Sample
      // Given I have a sample feature
      await scenario.iHaveASampleFeature(tester);
      // When I run the sample feature
      await scenario.iRunTheSampleFeature(tester);
      // Then I should see the sample feature
      await scenario.iShouldSeeTheSampleFeature(tester);
    });
    testWidgets('Counter', (tester) async {
      final scenario = CounterCustomName();
      //Scenario: Counter
      // Given I have a counter
      await scenario.iHaveACounter(tester);
      // When I increment the counter
      await scenario.iIncrementTheCounter(tester);
      // Then I should see the counter incremented
      await scenario.iShouldSeeTheCounterIncremented(tester);
    });
    test('Counter with examples', () async {
      final scenario = CounterWithExamplesScenario();
      //Scenario: Counter with examples
      final examples = [
        {'counter': '1',},
        {'counter': '2',},
        {'counter': '3',},
      ];
      for (var example in examples) {
      // Given I have a counter
      await scenario.iHaveACounter();
      // When I increment the <counter>
      await scenario.iIncrementTheCounter( example['counter']!);
      // Then I should see the counter incremented
      await scenario.iShouldSeeTheCounterIncremented();
      }
    });
    test('Counter with parameters', () async {
      final scenario = CounterWithParametersScenario();
      //Scenario: Counter with parameters
      final examples = [
        {'counter': '1','result': '2',},
        {'counter': '2','result': '3',},
        {'counter': '3','result': '4',},
      ];
      for (var example in examples) {
      // Given I have a counter
      await scenario.iHaveACounter();
      // When I increment the counter <counter>
      await scenario.iIncrementTheCounterCounter( example['counter']!);
      // Then I should see the result <result>
      await scenario.iShouldSeeTheResultResult( example['result']!);
      }
    });
    testWidgets('Counter with widget test', (tester) async {
      final scenario = CounterWithWidgetTestScenario();
      //Scenario: Counter with widget test
      // Given I have a counter
      await scenario.iHaveACounter(tester);
      // When I increment the counter
      await scenario.iIncrementTheCounter(tester);
      // Then I should see the counter incremented
      await scenario.iShouldSeeTheCounterIncremented(tester);
    });
  });
}
