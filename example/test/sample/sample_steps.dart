import 'package:flutter_test/flutter_test.dart';

import 'sample.bdd_steps.g.dart';

/// The steps of the feature "Sample".
class SampleSteps implements SampleStepsContract {
  @override
  late WidgetTester tester;

  bool featureRan = false;
  int counter = 0;

  @override
  Future<void> iHaveASampleFeature() async {
    featureRan = false;
  }

  @override
  Future<void> iRunTheSampleFeature() async {
    featureRan = true;
  }

  @override
  Future<void> iShouldSeeTheSampleFeature() async {
    expect(featureRan, isTrue);
  }

  @override
  Future<void> iHaveACounter() async {
    counter = 0;
  }

  @override
  Future<void> iIncrementTheCounter() async {
    counter++;
  }

  @override
  Future<void> iIncrementThe(num counter) async {
    this.counter += counter.toInt();
  }

  @override
  Future<void> iIncrementTheCounter2(num counter) async {
    this.counter += counter.toInt() + 1;
  }

  @override
  Future<void> iShouldSeeTheCounterIncremented() async {
    expect(counter, greaterThan(0));
  }

  @override
  Future<void> iShouldSeeTheResult(num result) async {
    expect(counter, result);
  }
}
