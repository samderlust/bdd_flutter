import 'package:flutter_test/flutter_test.dart';
import  'counter_scenarios.dart';

void main() {
  group('Counter', () {
    testWidgets('Increment', (tester) async {
      await IncrementScenario.iHaveACounterWithValue0(tester);
      // Example with values: 1, 1
      await IncrementScenario.iIncrementTheCounterBy(tester, '1');
      await IncrementScenario.theCounterShouldHaveValue(tester, '1');
      // Example with values: 2, 2
      await IncrementScenario.iIncrementTheCounterBy(tester, '2');
      await IncrementScenario.theCounterShouldHaveValue(tester, '2');
      // Example with values: 3, 3
      await IncrementScenario.iIncrementTheCounterBy(tester, '3');
      await IncrementScenario.theCounterShouldHaveValue(tester, '3');
    });
  });
}
