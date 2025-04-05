import 'package:bdd_flutter/src/domain/decorator_enum.dart';

import 'scenario.dart';

/// A feature is a collection of scenarios
class Feature {
  /// The name of the feature
  final String name;

  /// The scenarios of the feature
  final List<Scenario> scenarios;

  /// The decorators of the feature
  final Set<DecoratorEnum> decorators;

  Feature(this.name, this.scenarios, {this.decorators = const {}});
}
