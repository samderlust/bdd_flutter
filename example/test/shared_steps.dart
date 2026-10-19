import 'package:flutter_test/flutter_test.dart';

import 'shared.bdd_steps.dart';

/// Steps used by more than one feature. Feature steps classes mix this
/// in with `with SharedSteps`; keep the state these steps share here.
mixin SharedSteps implements SharedStepsContract {
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
}
