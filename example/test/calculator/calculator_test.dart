import 'package:flutter_test/flutter_test.dart';
import 'calculator_scenarios.dart';

void main() {
  group('Calculator', () {
    testWidgets('Add two numbers', (tester) async {
      await AddTwoNumbersScenario.iHaveTheNumber1(tester);
      await AddTwoNumbersScenario.iAddThemTogether(tester);
      await AddTwoNumbersScenario.theResultShouldBe3(tester);
    });
    testWidgets('Subtract two numbers', (tester) async {
      await SubtractTwoNumbersScenario.iHaveTheNumber5(tester);
      await SubtractTwoNumbersScenario.iSubtractThem(tester);
      await SubtractTwoNumbersScenario.theResultShouldBe2(tester);
    });
    testWidgets('Multiply two numbers', (tester) async {
      await MultiplyTwoNumbersScenario.iHaveTheNumber2(tester);
      await MultiplyTwoNumbersScenario.iMultiplyThem(tester);
      await MultiplyTwoNumbersScenario.theResultShouldBe6(tester);
    });
    testWidgets('Divide two numbers', (tester) async {
      final examples = [
        {'number1': '10', 'number2': '2', 'result': '5'},
        {'number1': '10', 'number2': '1', 'result': '10'},
        {'number1': '10', 'number2': '10', 'result': '1'},
      ];
      for (var example in examples) {
        await DivideTwoNumbersScenario.iHaveTheNumber(
          tester,
          example['number1']!,
        );
        await DivideTwoNumbersScenario.iDivideThem(tester);
        await DivideTwoNumbersScenario.theResultShouldBe(
          tester,
          example['result']!,
        );
      }
    });
  });
}
