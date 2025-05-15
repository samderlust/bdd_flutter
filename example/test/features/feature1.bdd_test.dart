import 'package:flutter_test/flutter_test.dart';
import 'feature1.bdd_scenarios.dart';

void main() {
  group('Feature 1', () {
    testWidgets('Scenario 1', (tester) async {
      //Scenario: Scenario 1
      // Given I have a counter with value 0
      await Scenario1Scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await Scenario1Scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await Scenario1Scenario.theCounterShouldHaveValue1(tester);
    });
  });
}
