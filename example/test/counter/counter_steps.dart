import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shared_steps.dart';

/// The steps of the feature "Counter". The counter steps it shares with
/// other features come from [SharedSteps].
class CounterSteps with SharedSteps {
  late WidgetTester tester;

  @When('I decrement the counter by {num}')
  Future<void> iDecrementTheCounterBy(num number) async {
    counter -= number.toInt();
  }
}
