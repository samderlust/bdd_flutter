import 'package:flutter_test/flutter_test.dart';

import 'calculator.bdd_steps.g.dart';

/// The steps of the feature "Calculator".
class CalculatorSteps implements CalculatorStepsContract {
  @override
  late WidgetTester tester;

  final List<num> numbers = [];
  num? result;

  @override
  Future<void> iHaveTheNumber(num number1) async {
    numbers.add(number1);
  }

  @override
  Future<void> iHaveAnd(num number1, num number2) async {
    numbers.addAll([number1, number2]);
  }

  @override
  Future<void> iAddThemTogether() async {
    result = numbers.reduce((a, b) => a + b);
  }

  @override
  Future<void> iSubtractThem() async {
    result = numbers.reduce((a, b) => a - b);
  }

  @override
  Future<void> iMultiplyThem() async {
    result = numbers.reduce((a, b) => a * b);
  }

  @override
  Future<void> iDivideThem() async {
    result = numbers.reduce((a, b) => a / b);
  }

  @override
  Future<void> iDivideThemToEachOther() async {
    await iDivideThem();
  }

  @override
  Future<void> theResultShouldBe(num result) async {
    expect(this.result, result);
  }
}
