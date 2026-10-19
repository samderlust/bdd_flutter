import 'package:flutter_test/flutter_test.dart';

import '../shared_steps.dart';
import 'counter.bdd_steps.dart';

/// The steps of the feature "Counter". The counter steps it shares with
/// other features come from [SharedSteps].
class CounterSteps with SharedSteps implements CounterStepsContract {
  @override
  late WidgetTester tester;

  @override
  Future<void> iDecrementTheCounterBy(num number) async {
    counter -= number.toInt();
  }
}
