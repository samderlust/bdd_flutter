import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The steps of the feature "Sample".
class SampleSteps {
  late WidgetTester tester;

  bool featureRan = false;
  int counter = 0;

  @Given('I have a sample feature')
  Future<void> iHaveASampleFeature() async {
    featureRan = false;
  }

  @When('I run the sample feature')
  Future<void> iRunTheSampleFeature() async {
    featureRan = true;
  }

  @Then('I should see the sample feature')
  Future<void> iShouldSeeTheSampleFeature() async {
    expect(featureRan, isTrue);
  }

  @Given('I have a counter')
  Future<void> iHaveACounter() async {
    counter = 0;
  }

  @When('I increment the counter')
  Future<void> iIncrementTheCounter() async {
    counter++;
  }

  @When('I increment the {num}')
  Future<void> iIncrementThe(num counter) async {
    this.counter += counter.toInt();
  }

  @When('I increment the counter {num}')
  Future<void> iIncrementTheCounter2(num counter) async {
    this.counter += counter.toInt() + 1;
  }

  @Then('I should see the counter incremented')
  Future<void> iShouldSeeTheCounterIncremented() async {
    expect(counter, greaterThan(0));
  }

  @Then('I should see the result {num}')
  Future<void> iShouldSeeTheResult(num result) async {
    expect(counter, result);
  }
}
