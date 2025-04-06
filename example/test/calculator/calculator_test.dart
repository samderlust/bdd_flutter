import 'package:flutter_test/flutter_test.dart';
import 'package:bdd_flutter/bdd_flutter.dart';
import  'calculator_scenarios.dart';

void main() {
  final reporter = BDDTestReporter(featureName: 'Calculator');
  setUpAll(() {
    reporter.testStarted(); // start recording
  });
  tearDownAll(() {
    reporter.testFinished(); // stop recording
    reporter.printReport(); // print report
    //reporter.saveReportToFile(); //uncomment to save report to file
  });
  group('Calculator', () {
    testWidgets('Add two numbers', (tester) async {
			 reporter.startScenario('Add two numbers');
	await reporter.guard(() => 
    AddTwoNumbersScenario.iHaveTheNumber1(tester,), 
    'Given I have the number 1',);
	await reporter.guard(() => 
    AddTwoNumbersScenario.iAddThemTogether(tester,), 
    'When I add them together',);
	await reporter.guard(() => 
    AddTwoNumbersScenario.theResultShouldBe3(tester,), 
    'Then the result should be 3',);
    });
    testWidgets('Subtract two numbers', (tester) async {
			 reporter.startScenario('Subtract two numbers');
	await reporter.guard(() => 
    SubtractTwoNumbersScenario.iHaveTheNumber5(tester,), 
    'Given I have the number 5',);
	await reporter.guard(() => 
    SubtractTwoNumbersScenario.iSubtractThem(tester,), 
    'When I subtract them',);
	await reporter.guard(() => 
    SubtractTwoNumbersScenario.theResultShouldBe2(tester,), 
    'Then the result should be 2',);
    });
    testWidgets('Multiply two numbers', (tester) async {
			 reporter.startScenario('Multiply two numbers');
	await reporter.guard(() => 
    MultiplyTwoNumbersScenario.iHaveTheNumber2(tester,), 
    'Given I have the number 2',);
	await reporter.guard(() => 
    MultiplyTwoNumbersScenario.iMultiplyThem(tester,), 
    'When I multiply them',);
	await reporter.guard(() => 
    MultiplyTwoNumbersScenario.theResultShouldBe6(tester,), 
    'Then the result should be 6',);
    });
    testWidgets('Divide two numbers', (tester) async {
			 reporter.startScenario('Divide two numbers');
	await reporter.guard(() => 
    DivideTwoNumbersScenario.iHaveTheNumber10(tester,), 
    'Given I have the number 10',);
	await reporter.guard(() => 
    DivideTwoNumbersScenario.iDivideThem(tester,), 
    'When I divide them',);
	await reporter.guard(() => 
    DivideTwoNumbersScenario.theResultShouldBe5(tester,), 
    'Then the result should be 5',);
    });
  });
}
