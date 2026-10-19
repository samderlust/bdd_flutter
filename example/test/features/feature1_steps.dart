import 'package:flutter_test/flutter_test.dart';

import '../shared_steps.dart';
import 'feature1.bdd_steps.dart';

/// The steps of the feature "Feature 1". All of them are shared.
class Feature1Steps with SharedSteps implements Feature1StepsContract {
  @override
  late WidgetTester tester;
}
