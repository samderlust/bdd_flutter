import 'package:flutter_test/flutter_test.dart';

import 'feature2.bdd_steps.g.dart';

/// The steps of the feature "Feature 2".
class Feature2Steps implements Feature2StepsContract {
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
