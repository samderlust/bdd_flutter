import '../../domain/decorator.dart';
import '../../domain/examples_table.dart';
import '../../domain/feature.dart';
import '../../domain/rule.dart';
import '../../domain/scenario.dart';

final RegExp _validTag = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_-]*$');

/// Whether `dart test` accepts [tag]: an (optionally hyphenated) Dart
/// identifier.
bool isValidTestTag(String tag) => _validTag.hasMatch(tag);

/// How one scenario's test is generated, after combining what the feature,
/// its rule and the scenario say.
class ScenarioSettings {
  /// Whether the test uses `test()` instead of `testWidgets()`.
  final bool isUnitTest;

  /// Whether the test is generated with `skip: true`.
  final bool skip;

  /// `dart test` tags from the feature, rule and scenario.
  final Set<String> tags;

  const ScenarioSettings({required this.isUnitTest, required this.skip, required this.tags});

  /// Resolves [scenario] inside [feature] and optional [rule].
  ///
  /// The closest `@unitTest`/`@widgetTest` wins; with none,
  /// [widgetTestsByDefault] decides.
  factory ScenarioSettings.of(Feature feature, Rule? rule, Scenario scenario, {bool widgetTestsByDefault = true}) {
    final unitTest =
        scenario.decorators.unitTestChoice ??
        rule?.decorators.unitTestChoice ??
        feature.decorators.unitTestChoice ??
        !widgetTestsByDefault;
    return ScenarioSettings(
      isUnitTest: unitTest,
      skip: feature.decorators.hasSkip || (rule?.decorators.hasSkip ?? false) || scenario.decorators.hasSkip,
      tags: {...feature.tags, ...?rule?.tags, ...scenario.tags},
    );
  }

  /// Whether rows of [table] are skipped.
  bool skipFor(ExamplesTable table) => skip || table.decorators.hasSkip;

  /// The valid tags for rows of [table], sorted; invalid tag names such as
  /// `className("X")` are left out because `dart test` rejects them.
  List<String> tagsFor([ExamplesTable? table]) {
    final all = {...tags, ...?table?.tags};
    return all.where(isValidTestTag).toList()..sort();
  }
}
