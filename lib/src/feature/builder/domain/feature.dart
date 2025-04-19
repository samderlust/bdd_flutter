import 'background.dart';
import 'decorator.dart';
import 'scenario.dart';

/// A feature is a collection of scenarios
class Feature {
  /// The name of the feature
  final String name;

  /// The scenarios of the feature
  final List<Scenario> scenarios;

  /// The decorators of the feature
  final Set<BDDDecorator> decorators;

  /// The background of the feature
  final Background? background;

  Feature(
    this.name,
    this.scenarios, {
    this.decorators = const {},
    this.background,
  });
}
