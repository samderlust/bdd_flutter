import 'package:flutter_test/flutter_test.dart';

import '../shared_steps.dart';
import 'feature3.bdd_steps.dart';

/// The steps of the feature "Feature 3". All of them are shared.
class Feature3Steps with SharedSteps implements Feature3StepsContract {
  @override
  late WidgetTester tester;
}
