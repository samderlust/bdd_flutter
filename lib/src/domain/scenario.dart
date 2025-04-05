import 'decorator_enum.dart';
import 'step.dart';

class Scenario {
  final String name;
  final List<Step> steps;
  final List<Map<String, String>>? examples;
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
