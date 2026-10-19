import 'background.dart';
import 'decorator.dart';
import 'scenario.dart';

/// A `Rule:` block: a business rule with its own scenarios.
///
/// A rule can have its own Background, which runs after the feature's
/// Background for every scenario in the rule.
class Rule {
  /// The text after `Rule:`.
  final String name;

  /// The rule's own Background, if any.
  final Background? background;

  /// The scenarios inside this rule.
  final List<Scenario> scenarios;

  /// Decorators written on this rule.
  final Set<Decorator> decorators;

  /// Other tags written on this rule, without the leading `@`.
  final Set<String> tags;

  const Rule({
    required this.name,
    required this.scenarios,
    this.background,
    this.decorators = const {},
    this.tags = const {},
  });
}
