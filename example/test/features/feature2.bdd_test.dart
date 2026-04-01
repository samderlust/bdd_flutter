import 'package:flutter_test/flutter_test.dart';
import 'feature2.bdd_scenarios.dart';

void main() {
  group('Feature 2', () {
    testWidgets('Scenario 2', (tester) async {
      final scenario = Scenario2Scenario();
      //Scenario: Scenario 2
      // Given I have a counter with value 0
      await scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await scenario.theCounterShouldHaveValue1(tester);
    });
    testWidgets('Scenario 3', (tester) async {
      final scenario = Scenario3Scenario();
      //Scenario: Scenario 3
      // Given I have a counter with value 0
      await scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await scenario.theCounterShouldHaveValue1(tester);
    });
  });
}
