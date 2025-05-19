import 'package:flutter_test/flutter_test.dart';
import 'calculator.bdd_scenarios.dart';

void main() {
  group('Calculator', () {
    testWidgets('Add two numbers', (tester) async {
      //Scenario: Add two numbers
      // Given I have the number 1
      await AddTwoNumbersScenario.iHaveTheNumber1(tester);
      // And I have the number 2
      await AddTwoNumbersScenario.iHaveTheNumber2(tester);
      // When I add them together
      await AddTwoNumbersScenario.iAddThemTogether(tester);
      // Then the result should be 3
      await AddTwoNumbersScenario.theResultShouldBe3(tester);
    });
    testWidgets('Subtract two numbers', (tester) async {
      //Scenario: Subtract two numbers
      // Given I have the number 5
      await Subtract.iHaveTheNumber5(tester);
      // And I have the number 3
      await Subtract.iHaveTheNumber3(tester);
      // When I subtract them
      await Subtract.iSubtractThem(tester);
      // Then the result should be 2
      await Subtract.theResultShouldBe2(tester);
    });
    testWidgets('Subtract two numbers2', (tester) async {
      //Scenario: Subtract two numbers2
      // Given I have the number 6
      await SubtractTwoNumbers2Scenario.iHaveTheNumber6(tester);
      // And I have the number 8
      await SubtractTwoNumbers2Scenario.iHaveTheNumber8(tester);
      // When I subtract them
      await SubtractTwoNumbers2Scenario.iSubtractThem(tester);
      // Then the result should be -2
      await SubtractTwoNumbers2Scenario.theResultShouldBe2(tester);
    });
    testWidgets('Multiply two numbers', (tester) async {
      //Scenario: Multiply two numbers
      // Given I have the number 2
      await MultiplyTwoNumbersScenario.iHaveTheNumber2(tester);
      // And I have the number 3
      await MultiplyTwoNumbersScenario.iHaveTheNumber3(tester);
      // When I multiply them
      await MultiplyTwoNumbersScenario.iMultiplyThem(tester);
      // Then the result should be 6
      await MultiplyTwoNumbersScenario.theResultShouldBe6(tester);
    });
    testWidgets('Divide two numbers', (tester) async {
      //Scenario: Divide two numbers
      final examples = [
        {'number1': '10','number2': '2','result': '5',},
        {'number1': '10','number2': '1','result': '10',},
        {'number1': '10','number2': '10','result': '1',},
      ];
      for (var example in examples) {
      // Given I have the number <number1>
      await DivideTwoNumbersScenario.iHaveTheNumberNumber1(tester, example['number1']!);
      // And I have the number <number2>
      await DivideTwoNumbersScenario.iHaveTheNumberNumber2(tester, example['number2']!);
      // When I divide them
      await DivideTwoNumbersScenario.iDivideThem(tester);
      // Then the result should be <result>
      await DivideTwoNumbersScenario.theResultShouldBeResult(tester, example['result']!);
      }
    });
    testWidgets('Divide two numbers2', (tester) async {
      //Scenario: Divide two numbers2
      final examples = [
        {'number1': '10','number2': '2','result': '5',},
        {'number1': '10','number2': '1','result': '10',},
        {'number1': '10','number2': '10','result': '1',},
      ];
      for (var example in examples) {
      // Given I have <number1> and <number2>
      await DivideTwoNumbers2Scenario.iHaveNumber1AndNumber2(tester, example['number1']!, example['number2']!);
      // When I divide them to each other
      await DivideTwoNumbers2Scenario.iDivideThemToEachOther(tester);
      // Then the result should be <result>
      await DivideTwoNumbers2Scenario.theResultShouldBeResult(tester, example['result']!);
      }
    });
  });
}
