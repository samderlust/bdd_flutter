import 'package:flutter_test/flutter_test.dart';
import 'package:bdd_flutter/bdd_flutter.dart';
import  'counter_scenarios.dart';

void main() {
  final reporter = BDDTestReporter(featureName: 'Counter');
  setUpAll(() {
    reporter.testStarted(); // start recording
  });
  tearDownAll(() {
    reporter.testFinished(); // stop recording
    reporter.printReport(); // print report
    //reporter.saveReportToFile(); //uncomment to save report to file
  });
  group('Counter', () {
    testWidgets('Increment', (tester) async {
			 reporter.startScenario('Increment');
      // Example with values: 1, 1
	await reporter.guard(() => 
    IncrementScenario.iHaveACounterWithValue0(tester,), 
    'Given I have a counter with value 0',);
	await reporter.guard(() => 
    IncrementScenario.iIncrementTheCounterBy(tester,'1'), 
    'When I increment the counter by <value>',);
	await reporter.guard(() => 
    IncrementScenario.theCounterShouldHaveValue(tester,'1'), 
    'Then the counter should have value <expected_value>',);
      // Example with values: 2, 2
	await reporter.guard(() => 
    IncrementScenario.iHaveACounterWithValue0(tester,), 
    'Given I have a counter with value 0',);
	await reporter.guard(() => 
    IncrementScenario.iIncrementTheCounterBy(tester,'2'), 
    'When I increment the counter by <value>',);
	await reporter.guard(() => 
    IncrementScenario.theCounterShouldHaveValue(tester,'2'), 
    'Then the counter should have value <expected_value>',);
      // Example with values: 3, 3
	await reporter.guard(() => 
    IncrementScenario.iHaveACounterWithValue0(tester,), 
    'Given I have a counter with value 0',);
	await reporter.guard(() => 
    IncrementScenario.iIncrementTheCounterBy(tester,'3'), 
    'When I increment the counter by <value>',);
	await reporter.guard(() => 
    IncrementScenario.theCounterShouldHaveValue(tester,'3'), 
    'Then the counter should have value <expected_value>',);
    });
  });
}
