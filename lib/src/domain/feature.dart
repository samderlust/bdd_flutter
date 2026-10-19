import '../constraints/file_constraint.dart';

import 'background.dart';
import 'decorator.dart';
import 'rule.dart';
import 'scenario.dart';

/// Represents a parsed Gherkin feature file.
///
/// A feature contains scenarios at its top level, `Rule:` blocks with
/// their own scenarios, an optional Background, decorators and tags.
class Feature {
  /// The feature name (text after `Feature:`).
  final String name;

  /// The file path of the `.feature` file.
  final String path;

  /// The scenarios written directly under the feature, outside any rule.
  final List<Scenario> scenarios;

  /// The `Rule:` blocks, in file order.
  final List<Rule> rules;

  /// Optional background steps shared by all scenarios.
  final Background? background;

  /// Decorators applied at the feature level (e.g., `@unitTest`).
  final Set<Decorator> decorators;

  /// Other tags written on the feature, without the leading `@`.
  final Set<String> tags;

  const Feature({
    required this.name,
    required this.path,
    required this.scenarios,
    required this.decorators,
    this.rules = const [],
    this.background,
    this.tags = const {},
  });
}

/// Extension methods for [Feature].
extension FeatureX on Feature {
  /// The base file name without directory path or `.feature` extension.
  String get fileName {
    final base = path.split(RegExp(r'[/\\]')).last;
    return base.endsWith(FileConstraint.feature)
        ? base.substring(0, base.length - FileConstraint.feature.length)
        : base;
  }
}
