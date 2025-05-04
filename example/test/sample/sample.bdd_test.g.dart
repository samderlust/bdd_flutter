import 'package:flutter_test/flutter_test.dart';
import 'sample.bdd_scenarios.g.dart';

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
      await CounterScenario.iHaveACounter(tester);
      // When I increment the counter
      await CounterScenario.iIncrementTheCounter(tester);
      // Then I should see the counter incremented
      await CounterScenario.iShouldSeeTheCounterIncremented(tester);
    });
    testWidgets('Counter with examples', (tester) async {
      //Scenario: Counter with examples
      final examples = [
        {'counter': '1'},
        {'counter': '2'},
        {'counter': '3'},
      ];
      for (var example in examples) {
        // Given I have a counter
        await CounterWithExamplesScenario.iHaveACounter(tester);
        // When I increment the <counter>
        await CounterWithExamplesScenario.iIncrementThe(tester, example['counter']!);
        // Then I should see the counter incremented
        await CounterWithExamplesScenario.iShouldSeeTheCounterIncremented(tester);
      }
    });
    testWidgets('Counter with parameters', (tester) async {
      //Scenario: Counter with parameters
      final examples = [
        {'counter': '1', 'result': '2'},
        {'counter': '2', 'result': '3'},
        {'counter': '3', 'result': '4'},
      ];
      for (var example in examples) {
        // Given I have a counter
        await CounterWithParametersScenario.iHaveACounter(tester);
        // When I increment the counter <counter>
        await CounterWithParametersScenario.iIncrementTheCounter(tester, example['counter']!);
        // Then I should see the result <result>
        await CounterWithParametersScenario.iShouldSeeTheResult(tester, example['result']!);
      }
    });
  });
}
