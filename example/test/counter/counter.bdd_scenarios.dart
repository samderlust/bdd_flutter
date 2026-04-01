import 'package:flutter_test/flutter_test.dart';

class CounterBackground {
  Future<void> iHaveACounterWithValue0() async {
    // TODO: Implement Given I have a counter with value 0
  }
}

class IncrementScenario {
  Future<void> iIncrementTheCounterByValue(WidgetTester tester, String value) async {
    // TODO: Implement When I increment the counter by <value>
  }

  Future<void> theCounterShouldHaveValueExpectedValue(WidgetTester tester, String expectedValue) async {
    // TODO: Implement Then the counter should have value <expected_value>
  }
}

class DecrementScenario {
  Future<void> iDecrementTheCounterBy1(WidgetTester tester) async {
    // TODO: Implement When I decrement the counter by 1
  }

  Future<void> theCounterShouldHaveValue1(WidgetTester tester) async {
    // TODO: Implement Then the counter should have value -1
  }
}
