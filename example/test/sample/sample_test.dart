import 'package:flutter_test/flutter_test.dart';
import 'package:bdd_flutter/bdd_flutter.dart';
import  'sample_scenarios.dart';

void main() {
  final reporter = BDDTestReporter(featureName: 'Sample');
  setUpAll(() {
    reporter.testStarted(); // start recording
  });
  tearDownAll(() {
    reporter.testFinished(); // stop recording
    reporter.printReport(); // print report
    //reporter.saveReportToFile(); //uncomment to save report to file
  });
  group('Sample', () {
    testWidgets('Sample', (tester) async {
			 reporter.startScenario('Sample');
	await reporter.guard(() => 
    SampleScenario.iHaveASampleFeature(tester,), 
    'Given I have a sample feature',);
	await reporter.guard(() => 
    SampleScenario.iRunTheSampleFeature(tester,), 
    'When I run the sample feature',);
	await reporter.guard(() => 
    SampleScenario.iShouldSeeTheSampleFeature(tester,), 
    'Then I should see the sample feature',);
    });
    testWidgets('Counter', (tester) async {
			 reporter.startScenario('Counter');
	await reporter.guard(() => 
    CounterCustomName.iHaveACounter(tester,), 
    'Given I have a counter',);
	await reporter.guard(() => 
    CounterCustomName.iIncrementTheCounter(tester,), 
    'When I increment the counter',);
	await reporter.guard(() => 
    CounterCustomName.iShouldSeeTheCounterIncremented(tester,), 
    'Then I should see the counter incremented',);
    });
    test('Counter with examples', () async {
			 reporter.startScenario('Counter with examples');
      // Example with values: 1
	await reporter.guard(() => 
    CounterWithExamplesScenario.iHaveACounter(), 
    'Given I have a counter',);
	await reporter.guard(() => 
    CounterWithExamplesScenario.iIncrementThe('1'), 
    'When I increment the <counter>',);
	await reporter.guard(() => 
    CounterWithExamplesScenario.iShouldSeeTheCounterIncremented(), 
    'Then I should see the counter incremented',);
      // Example with values: 2
	await reporter.guard(() => 
    CounterWithExamplesScenario.iHaveACounter(), 
    'Given I have a counter',);
	await reporter.guard(() => 
    CounterWithExamplesScenario.iIncrementThe('2'), 
    'When I increment the <counter>',);
	await reporter.guard(() => 
    CounterWithExamplesScenario.iShouldSeeTheCounterIncremented(), 
    'Then I should see the counter incremented',);
      // Example with values: 3
	await reporter.guard(() => 
    CounterWithExamplesScenario.iHaveACounter(), 
    'Given I have a counter',);
	await reporter.guard(() => 
    CounterWithExamplesScenario.iIncrementThe('3'), 
    'When I increment the <counter>',);
	await reporter.guard(() => 
    CounterWithExamplesScenario.iShouldSeeTheCounterIncremented(), 
    'Then I should see the counter incremented',);
    });
    test('Counter with parameters', () async {
			 reporter.startScenario('Counter with parameters');
      // Example with values: 1, 2
	await reporter.guard(() => 
    CounterWithParametersScenario.iHaveACounter(), 
    'Given I have a counter',);
	await reporter.guard(() => 
    CounterWithParametersScenario.iIncrementTheCounter('1'), 
    'When I increment the counter <counter>',);
	await reporter.guard(() => 
    CounterWithParametersScenario.iShouldSeeTheResult('2'), 
    'Then I should see the result <result>',);
      // Example with values: 2, 3
	await reporter.guard(() => 
    CounterWithParametersScenario.iHaveACounter(), 
    'Given I have a counter',);
	await reporter.guard(() => 
    CounterWithParametersScenario.iIncrementTheCounter('2'), 
    'When I increment the counter <counter>',);
	await reporter.guard(() => 
    CounterWithParametersScenario.iShouldSeeTheResult('3'), 
    'Then I should see the result <result>',);
      // Example with values: 3, 4
	await reporter.guard(() => 
    CounterWithParametersScenario.iHaveACounter(), 
    'Given I have a counter',);
	await reporter.guard(() => 
    CounterWithParametersScenario.iIncrementTheCounter('3'), 
    'When I increment the counter <counter>',);
	await reporter.guard(() => 
    CounterWithParametersScenario.iShouldSeeTheResult('4'), 
    'Then I should see the result <result>',);
    });
  });
}
