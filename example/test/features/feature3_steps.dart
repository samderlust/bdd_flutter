import 'package:flutter_test/flutter_test.dart';

import 'feature3.bdd_steps.g.dart';

/// The steps of the feature "Feature 3".
class Feature3Steps implements Feature3StepsContract {
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
