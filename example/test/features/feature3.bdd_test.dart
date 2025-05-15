import 'package:flutter_test/flutter_test.dart';
import 'feature3.bdd_scenarios.dart';

void main() {
  group('Feature 3', () {
    testWidgets('Scenario 3', (tester) async {
      //Scenario: Scenario 3
      // Given I have a counter with value 0
      await Scenario3Scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await Scenario3Scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await Scenario3Scenario.theCounterShouldHaveValue1(tester);
    });
  });
}
