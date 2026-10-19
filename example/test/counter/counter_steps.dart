import 'package:flutter_test/flutter_test.dart';

import 'counter.bdd_steps.dart';

/// The steps of the feature "Counter".
class CounterSteps implements CounterStepsContract {
  @override
  late WidgetTester tester;

  int counter = 0;

  @override
  Future<void> iHaveACounterWithValue(num number) async {
    counter = number.toInt();
  }

  @override
  Future<void> iIncrementTheCounterBy(num value) async {
    counter += value.toInt();
  }

  @override
  Future<void> theCounterShouldHaveValue(num expectedValue) async {
    expect(counter, expectedValue);
  }

  @override
  Future<void> iDecrementTheCounterBy(num number) async {
    counter -= number.toInt();
  }
}
