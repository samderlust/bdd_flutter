import 'package:bdd_flutter/src/domain/decorator_enum.dart';

import 'scenario.dart';

class Feature {
  final String name;
  final List<Scenario> scenarios;
  final Set<DecoratorEnum> decorators;

  Feature(this.name, this.scenarios, {this.decorators = const {}});
}
