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
      final examples = [
        {'counter': '1',},
        {'counter': '2',},
        {'counter': '3',},
      ];
      for (var example in examples) {
        await reporter.guard(() => 
    CounterWithExamplesScenario.iHaveACounter(), 
    'Given I have a counter',);
        await reporter.guard(() => 
    CounterWithExamplesScenario.iIncrementThe(example['counter']!), 
    'When I increment the <counter>',);
        await reporter.guard(() => 
    CounterWithExamplesScenario.iShouldSeeTheCounterIncremented(), 
    'Then I should see the counter incremented',);
      }
    });
    test('Counter with parameters', () async {
			 reporter.startScenario('Counter with parameters');
      final examples = [
        {'counter': '1','result': '2',},
        {'counter': '2','result': '3',},
        {'counter': '3','result': '4',},
      ];
      for (var example in examples) {
        await reporter.guard(() => 
    CounterWithParametersScenario.iHaveACounter(), 
    'Given I have a counter',);
        await reporter.guard(() => 
    CounterWithParametersScenario.iIncrementTheCounter(example['counter']!), 
    'When I increment the counter <counter>',);
        await reporter.guard(() => 
    CounterWithParametersScenario.iShouldSeeTheResult(example['result']!), 
    'Then I should see the result <result>',);
      }
    });
  });
}
