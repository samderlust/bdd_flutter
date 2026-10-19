import 'decorator.dart';
import 'examples_table.dart';
import 'step.dart';

/// Represents a Gherkin scenario with its steps, examples and tags.
///
/// A scenario with [examples] is a Scenario Outline: it becomes one test
/// per example row.
class Scenario {
  /// The scenario name (text after `Scenario:`).
  final String name;

  /// The steps in this scenario, without any Background steps.
  final List<Step> steps;

  /// The `Examples:` blocks, empty for a plain scenario.
  final List<ExamplesTable> examples;

  /// Decorators written on this scenario (e.g. `@unitTest`).
  final Set<Decorator> decorators;

  /// Other tags written on this scenario, without the leading `@`.
  final Set<String> tags;

  const Scenario(this.name, this.steps, {this.examples = const [], this.decorators = const {}, this.tags = const {}});

  @override
  String toString() {
    return 'Scenario(name: $name, steps: $steps, examples: $examples, decorators: $decorators, tags: $tags)';
  }
}

/// Extension methods for [Scenario].
extension ScenarioX on Scenario {
  /// Whether this scenario has example rows.
  bool get isOutline => examples.any((table) => table.rows.isNotEmpty);
}
