import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The steps of the feature "Calculator".
class CalculatorSteps {
  late WidgetTester tester;

  final List<num> numbers = [];
  num? result;

  @Given('I have the number {num}')
  Future<void> iHaveTheNumber(num number1) async {
    numbers.add(number1);
  }

  @Given('I have {num} and {num}')
  Future<void> iHaveAnd(num number1, num number2) async {
    numbers.addAll([number1, number2]);
  }

  @When('I add them together')
  Future<void> iAddThemTogether() async {
    result = numbers.reduce((a, b) => a + b);
  }

  @When('I subtract them')
  Future<void> iSubtractThem() async {
    result = numbers.reduce((a, b) => a - b);
  }

  @When('I multiply them')
  Future<void> iMultiplyThem() async {
    result = numbers.reduce((a, b) => a * b);
  }

  @When('I divide them')
  Future<void> iDivideThem() async {
    result = numbers.reduce((a, b) => a / b);
  }

  @When('I divide them to each other')
  Future<void> iDivideThemToEachOther() async {
    await iDivideThem();
  }

  @Then('the result should be {num}')
  Future<void> theResultShouldBe(num result) async {
    expect(this.result, result);
  }
}
