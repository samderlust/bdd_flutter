import 'package:flutter_test/flutter_test.dart';
import 'feature2.bdd_scenarios.dart';

void main() {
  group('Feature 2', () {
    testWidgets('Scenario 2', (tester) async {
      //Scenario: Scenario 2
      // Given I have a counter with value 0
      await Scenario2Scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await Scenario2Scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await Scenario2Scenario.theCounterShouldHaveValue1(tester);
    });
  });
}
