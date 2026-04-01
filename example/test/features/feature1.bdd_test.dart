import 'package:flutter_test/flutter_test.dart';
import 'feature1.bdd_scenarios.dart';

void main() {
  group('Feature 1', () {
    testWidgets('Scenario 1', (tester) async {
      final scenario = Scenario1Scenario();
      //Scenario: Scenario 1
      // Given I have a counter with value 0
      await scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await scenario.theCounterShouldHaveValue1(tester);
    });
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
    testWidgets('Scenario 4', (tester) async {
      final scenario = Scenario4Scenario();
      //Scenario: Scenario 4
      // Given I have a counter with value 0
      await scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await scenario.theCounterShouldHaveValue1(tester);
    });
    testWidgets('Scenario 5', (tester) async {
      final scenario = Scenario5Scenario();
      //Scenario: Scenario 5
      // Given I have a counter with value 0
      await scenario.iHaveACounterWithValue0(tester);
      // When I increment the counter by 1
      await scenario.iIncrementTheCounterBy1(tester);
      // Then the counter should have value 1
      await scenario.theCounterShouldHaveValue1(tester);
    });
  });
}
