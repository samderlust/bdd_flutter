import 'package:flutter_test/flutter_test.dart';
import 'sample.bdd_scenarios.dart';

void main() {
  group('Sample', () {
    testWidgets('Sample', (tester) async {
      //Scenario: Sample
      // Given I have a sample feature
      await SampleScenario.iHaveASampleFeature(tester);
      // When I run the sample feature
      await SampleScenario.iRunTheSampleFeature(tester);
      // Then I should see the sample feature
      await SampleScenario.iShouldSeeTheSampleFeature(tester);
    });
    testWidgets('Counter', (tester) async {
      //Scenario: Counter
      // Given I have a counter
      await CounterCustomName.iHaveACounter(tester);
      // When I increment the counter
      await CounterCustomName.iIncrementTheCounter(tester);
      // Then I should see the counter incremented
      await CounterCustomName.iShouldSeeTheCounterIncremented(tester);
    });
    test('Counter with examples', () async {
      //Scenario: Counter with examples
      final examples = [
        {'counter': '1',},
        {'counter': '2',},
        {'counter': '3',},
      ];
      for (var example in examples) {
      // Given I have a counter
      await CounterWithExamplesScenario.iHaveACounter();
      // When I increment the <counter>
      await CounterWithExamplesScenario.iIncrementThe( example['counter']!);
      // Then I should see the counter incremented
      await CounterWithExamplesScenario.iShouldSeeTheCounterIncremented();
      }
    });
    test('Counter with parameters', () async {
      //Scenario: Counter with parameters
      final examples = [
        {'counter': '1','result': '2',},
        {'counter': '2','result': '3',},
        {'counter': '3','result': '4',},
      ];
      for (var example in examples) {
      // Given I have a counter
      await CounterWithParametersScenario.iHaveACounter();
      // When I increment the counter <counter>
      await CounterWithParametersScenario.iIncrementTheCounter( example['counter']!);
      // Then I should see the result <result>
      await CounterWithParametersScenario.iShouldSeeTheResult( example['result']!);
      }
    });
    testWidgets('Counter with widget test', (tester) async {
      //Scenario: Counter with widget test
      // Given I have a counter
      await CounterWithWidgetTestScenario.iHaveACounter(tester);
      // When I increment the counter
      await CounterWithWidgetTestScenario.iIncrementTheCounter(tester);
      // Then I should see the counter incremented
      await CounterWithWidgetTestScenario.iShouldSeeTheCounterIncremented(tester);
    });
  });
}
