import 'package:bdd_flutter/src/extensions/string_x.dart';

import 'decorator.dart';
import 'step.dart';

/// A scenario is a collection of steps
class Scenario {
  /// The name of the scenario
  final String name;

  /// The steps of the scenario
  final List<Step> steps;

  /// The examples of the scenario
  final List<Map<String, String>>? examples;

  /// The decorators of the scenario
  final Set<BDDDecorator> decorators;

  Scenario(this.name, this.steps, {this.examples, this.decorators = const {}});

  @override
  String toString() {
    return 'Scenario(name: $name, steps: $steps, examples: $examples, decorators: $decorators)';
  }
}

extension ScenarioX on Scenario {
  bool get isUnitTest => decorators.hasUnitTest;
  bool get isWidgetTest => decorators.hasWidgetTest;

  String get className {
    if (decorators.hasClassName) {
      return decorators.firstWhere((e) => e.isClassName).value!;
    }
    return name.toClassName;
  }
}
