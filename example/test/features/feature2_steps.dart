import 'package:flutter_test/flutter_test.dart';

import '../shared_steps.dart';
import 'feature2.bdd_steps.dart';

/// The steps of the feature "Feature 2". All of them are shared.
class Feature2Steps with SharedSteps implements Feature2StepsContract {
  @override
  late WidgetTester tester;
}
