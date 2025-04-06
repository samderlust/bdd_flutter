import 'package:flutter_test/flutter_test.dart';
import  'calculator_scenarios.dart';

void main() {
  group('Calculator', () {
    testWidgets('Add two numbers', (tester) async {
	await AddTwoNumbersScenario.iHaveTheNumber1(tester,);
	await AddTwoNumbersScenario.iAddThemTogether(tester,);
	await AddTwoNumbersScenario.theResultShouldBe3(tester,);
    });
    testWidgets('Subtract two numbers', (tester) async {
	await Subtract.iHaveTheNumber5(tester,);
	await Subtract.iSubtractThem(tester,);
	await Subtract.theResultShouldBe2(tester,);
    });
    testWidgets('Multiply two numbers', (tester) async {
	await MultiplyTwoNumbersScenario.iHaveTheNumber2(tester,);
	await MultiplyTwoNumbersScenario.iMultiplyThem(tester,);
	await MultiplyTwoNumbersScenario.theResultShouldBe6(tester,);
    });
    testWidgets('Divide two numbers', (tester) async {
	await DivideTwoNumbersScenario.iHaveTheNumber10(tester,);
	await DivideTwoNumbersScenario.iDivideThem(tester,);
	await DivideTwoNumbersScenario.theResultShouldBe5(tester,);
    });
  });
}
