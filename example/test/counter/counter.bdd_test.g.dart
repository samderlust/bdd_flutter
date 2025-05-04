import 'package:flutter_test/flutter_test.dart';
import 'counter.bdd_scenarios.g.dart';

void main() {
  group('Counter', () {
    //Background: I have a counter with value 0
    CounterBackground.iHaveACounterWithValue0();
    testWidgets('Increment', (tester) async {
      //Scenario: Increment
      final examples = [
        {'value': '1','expectedvalue': '1',},
        {'value': '2','expectedvalue': '2',},
        {'value': '3','expectedvalue': '3',},
      ];
      for (var example in examples) {
      // When I increment the counter by <value>
      await IncrementScenario.iIncrementTheCounterBy(tester, example['value']!);
      // Then the counter should have value <expected_value>
      await IncrementScenario.theCounterShouldHaveValue(tester, example['expected_value']!);
      }
    });
  });
}
