import 'package:flutter_test/flutter_test.dart';

/// Steps used by more than one feature, written once.
///
/// Feature steps classes mix this in with `with SharedSteps`. Keep the
/// state these steps share in fields here; every test gets a fresh object.
mixin SharedSteps {
  int counter = 0;

  /// `Given I have a counter with value 0`
  Future<void> iHaveACounterWithValue(num number) async {
    counter = number.toInt();
  }

  /// `When I increment the counter by <value>`
  Future<void> iIncrementTheCounterBy(num value) async {
    counter += value.toInt();
  }

  /// `Then the counter should have value <expected_value>`
  Future<void> theCounterShouldHaveValue(num expectedValue) async {
    expect(counter, expectedValue);
  }
}
