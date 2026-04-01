import 'package:flutter_test/flutter_test.dart';
import 'counter.bdd_scenarios.dart';

void main() {
  group('Counter', () {
    testWidgets('Increment', (tester) async {
      final scenario = IncrementScenario();
      final background = CounterBackground();
      //Background: I have a counter with value 0
      await background.iHaveACounterWithValue0();
      //Scenario: Increment
      final examples = [
        {'value': '1','expectedValue': '1',},
        {'value': '2','expectedValue': '2',},
        {'value': '3','expectedValue': '3',},
      ];
      for (var example in examples) {
      // When I increment the counter by <value>
      await scenario.iIncrementTheCounterByValue(tester, example['value']!);
      // Then the counter should have value <expected_value>
      await scenario.theCounterShouldHaveValueExpectedValue(tester, example['expectedValue']!);
      }
    });
    testWidgets('Decrement', (tester) async {
      final scenario = DecrementScenario();
      final background = CounterBackground();
      //Background: I have a counter with value 0
      await background.iHaveACounterWithValue0();
      //Scenario: Decrement
      // When I decrement the counter by 1
      await scenario.iDecrementTheCounterBy1(tester);
      // Then the counter should have value -1
      await scenario.theCounterShouldHaveValue1(tester);
    });
  });
}
