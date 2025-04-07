import 'package:flutter_test/flutter_test.dart';
import 'calculator_scenarios.dart';

void main() {
  group('Calculator', () {
    testWidgets('Add two numbers', (tester) async {
      //Scenario: Add two numbers
      // Given I have the number 1
      await AddTwoNumbersScenario.iHaveTheNumber1(tester);
      // When I add them together
      await AddTwoNumbersScenario.iAddThemTogether(tester);
      // Then the result should be 3
      await AddTwoNumbersScenario.theResultShouldBe3(tester);
    });
    testWidgets('Subtract two numbers', (tester) async {
      //Scenario: Subtract two numbers
      // Given I have the number 5
      await Subtract.iHaveTheNumber5(tester);
      // When I subtract them
      await Subtract.iSubtractThem(tester);
      // Then the result should be 2
      await Subtract.theResultShouldBe2(tester);
    });
    testWidgets('Multiply two numbers', (tester) async {
      //Scenario: Multiply two numbers
      // Given I have the number 2
      await MultiplyTwoNumbersScenario.iHaveTheNumber2(tester);
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
      await DivideTwoNumbersScenario.iHaveTheNumber(tester, example['number1']!);
      // When I divide them
      await DivideTwoNumbersScenario.iDivideThem(tester);
      // Then the result should be <result>
      await DivideTwoNumbersScenario.theResultShouldBe(tester, example['result']!);
      }
    });
  });
}
