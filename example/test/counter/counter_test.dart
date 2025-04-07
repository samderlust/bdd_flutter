import 'package:flutter_test/flutter_test.dart';
import 'package:bdd_flutter/bdd_flutter.dart';
import 'counter_scenarios.dart';

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
      final examples = [
        {'value': '1', 'expectedvalue': '1'},
        {'value': '2', 'expectedvalue': '2'},
        {'value': '3', 'expectedvalue': '3'},
      ];
      for (var example in examples) {
        await reporter.guard(
          () => IncrementScenario.iHaveACounterWithValue0(tester),
          'Given I have a counter with value 0',
        );
        await reporter.guard(
          () => IncrementScenario.iIncrementTheCounterBy(
            tester,
            example['value']!,
          ),
          'When I increment the counter by <value>',
        );
        await reporter.guard(
          () => IncrementScenario.theCounterShouldHaveValue(
            tester,
            example['expected_value']!,
          ),
          'Then the counter should have value <expected_value>',
        );
      }
    });
  });
}
