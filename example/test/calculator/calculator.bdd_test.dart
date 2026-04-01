import 'package:flutter_test/flutter_test.dart';
import 'calculator.bdd_scenarios.dart';

void main() {
  group('Calculator', () {
    testWidgets('Add two numbers', (tester) async {
      final scenario = AddTwoNumbersScenario();
      //Scenario: Add two numbers
      // Given I have the number 1
      await scenario.iHaveTheNumber1(tester);
      // And I have the number 2
      await scenario.iHaveTheNumber2(tester);
      // When I add them together
      await scenario.iAddThemTogether(tester);
      // Then the result should be 3
      await scenario.theResultShouldBe3(tester);
    });
    testWidgets('Subtract two numbers', (tester) async {
      final scenario = SubtractTwoNumbersScenario();
      //Scenario: Subtract two numbers
      // Given I have the number 5
      await scenario.iHaveTheNumber5(tester);
      // And I have the number 3
      await scenario.iHaveTheNumber3(tester);
      // When I subtract them
      await scenario.iSubtractThem(tester);
      // Then the result should be 2
      await scenario.theResultShouldBe2(tester);
    });
    testWidgets('Subtract two numbers2', (tester) async {
      final scenario = SubtractTwoNumbers2Scenario();
      //Scenario: Subtract two numbers2
      // Given I have the number 6
      await scenario.iHaveTheNumber6(tester);
      // And I have the number 8
      await scenario.iHaveTheNumber8(tester);
      // When I subtract them
      await scenario.iSubtractThem(tester);
      // Then the result should be -2
      await scenario.theResultShouldBe2(tester);
    });
    testWidgets('Multiply two numbers', (tester) async {
      final scenario = MultiplyTwoNumbersScenario();
      //Scenario: Multiply two numbers
      // Given I have the number 2
      await scenario.iHaveTheNumber2(tester);
      // And I have the number 3
      await scenario.iHaveTheNumber3(tester);
      // When I multiply them
      await scenario.iMultiplyThem(tester);
      // Then the result should be 6
      await scenario.theResultShouldBe6(tester);
    });
    testWidgets('Divide two numbers', (tester) async {
      final scenario = DivideTwoNumbersScenario();
      //Scenario: Divide two numbers
      final examples = [
        {'number1': '10','number2': '2','result': '5',},
        {'number1': '10','number2': '1','result': '10',},
        {'number1': '10','number2': '10','result': '1',},
      ];
      for (var example in examples) {
      // Given I have the number <number1>
      await scenario.iHaveTheNumberNumber1(tester, example['number1']!);
      // And I have the number <number2>
      await scenario.iHaveTheNumberNumber2(tester, example['number2']!);
      // When I divide them
      await scenario.iDivideThem(tester);
      // Then the result should be <result>
      await scenario.theResultShouldBeResult(tester, example['result']!);
      }
    });
    testWidgets('Divide two numbers2', (tester) async {
      final scenario = DivideTwoNumbers2Scenario();
      //Scenario: Divide two numbers2
      final examples = [
        {'number1': '10','number2': '2','result': '5',},
        {'number1': '10','number2': '1','result': '10',},
        {'number1': '10','number2': '10','result': '1',},
      ];
      for (var example in examples) {
      // Given I have <number1> and <number2>
      await scenario.iHaveNumber1AndNumber2(tester, example['number1']!, example['number2']!);
      // When I divide them to each other
      await scenario.iDivideThemToEachOther(tester);
      // Then the result should be <result>
      await scenario.theResultShouldBeResult(tester, example['result']!);
      }
    });
  });
}
