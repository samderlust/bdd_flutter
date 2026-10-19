import 'package:flutter_test/flutter_test.dart';

import 'feature1.bdd_steps.dart';

/// The steps of the feature "Feature 1".
class Feature1Steps implements Feature1StepsContract {
  @override
  late WidgetTester tester;

  int counter = 0;

  @override
  Future<void> iHaveACounterWithValue(num number) async {
    counter = number.toInt();
  }

  @override
  Future<void> iIncrementTheCounterBy(num number) async {
    counter += number.toInt();
  }

  @override
  Future<void> theCounterShouldHaveValue(num number) async {
    expect(counter, number);
  }
}
