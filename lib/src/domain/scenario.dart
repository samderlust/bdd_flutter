import 'decorator_enum.dart';
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
  final Set<DecoratorEnum> decorators;

  Scenario(this.name, this.steps, {this.examples, this.decorators = const {}});

  @override
  String toString() {
    return 'Scenario(name: $name, steps: $steps, examples: $examples, decorators: $decorators)';
  }
}

extension ScenarioX on Scenario {
  bool get isUnitTest => decorators.hasUnitTest;
  bool get isWidgetTest => decorators.hasWidgetTest;
}
