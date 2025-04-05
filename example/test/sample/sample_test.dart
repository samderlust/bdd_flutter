import 'package:flutter_test/flutter_test.dart';
import  'sample_scenarios.dart';

void main() {
  group('Sample', () {
    testWidgets('Sample', (tester) async {
      await SampleScenario.iHaveASampleFeature(tester);
      await SampleScenario.iRunTheSampleFeature(tester);
      await SampleScenario.iShouldSeeTheSampleFeature(tester);
    });
    testWidgets('Counter', (tester) async {
      await CounterScenario.iHaveACounter(tester);
      await CounterScenario.iIncrementTheCounter(tester);
      await CounterScenario.iShouldSeeTheCounterIncremented(tester);
    });
    test('Counter with examples', () async {
      await CounterWithExamplesScenario.iHaveACounter();
      // Example with values: 1
      await CounterWithExamplesScenario.iIncrementThe('1');
      await CounterWithExamplesScenario.iShouldSeeTheCounterIncremented();
      // Example with values: 2
      await CounterWithExamplesScenario.iIncrementThe('2');
      await CounterWithExamplesScenario.iShouldSeeTheCounterIncremented();
      // Example with values: 3
      await CounterWithExamplesScenario.iIncrementThe('3');
      await CounterWithExamplesScenario.iShouldSeeTheCounterIncremented();
    });
    test('Counter with parameters', () async {
      await CounterWithParametersScenario.iHaveACounter();
      // Example with values: 1, 2
      await CounterWithParametersScenario.iIncrementTheCounter('1');
      await CounterWithParametersScenario.iShouldSeeTheResult('2');
      // Example with values: 2, 3
      await CounterWithParametersScenario.iIncrementTheCounter('2');
      await CounterWithParametersScenario.iShouldSeeTheResult('3');
      // Example with values: 3, 4
      await CounterWithParametersScenario.iIncrementTheCounter('3');
      await CounterWithParametersScenario.iShouldSeeTheResult('4');
    });
  });
}
