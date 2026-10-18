import 'package:cucumber_messages/cucumber_messages.dart' as cm;

import '../../domain/background.dart';
import '../../domain/decorator.dart';
import '../../domain/feature.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';
import '../../domain/step_keyword_type.dart';

/// Converts a Cucumber [cm.GherkinDocument] into bdd_flutter's [Feature].
///
/// This is the only place that knows about `cucumber_messages` types, so
/// upstream changes stay contained here.
class GherkinMapper {
  const GherkinMapper();

  /// Maps [document] parsed from the file at [path] to a [Feature].
  Feature toFeature(cm.GherkinDocument document, String path) {
    final feature = document.feature;
    if (feature == null) {
      return Feature(name: 'Unnamed Feature', path: path, scenarios: const [], decorators: const {});
    }

    final background = feature.children.map((c) => c.background).whereType<cm.Background>().firstOrNull;

    return Feature(
      name: feature.name,
      path: path,
      scenarios: _scenarios(feature),
      decorators: _decorators(feature.tags),
      background: background == null ? null : _background(background),
    );
  }

  /// Collects scenarios at feature level and inside every `Rule:`.
  List<Scenario> _scenarios(cm.Feature feature) {
    final scenarios = <Scenario>[];
    for (final child in feature.children) {
      final scenario = child.scenario;
      final rule = child.rule;
      if (scenario != null) scenarios.add(_scenario(scenario));
      if (rule != null) scenarios.addAll(_ruleScenarios(rule));
    }
    return scenarios;
  }

  /// Maps a rule's scenarios, prepending the rule's own background steps.
  ///
  /// bdd_flutter generates one background per feature, so a rule background
  /// runs as the first steps of each scenario in that rule.
  List<Scenario> _ruleScenarios(cm.Rule rule) {
    final ruleBackground = rule.children.map((c) => c.background).whereType<cm.Background>().firstOrNull;
    final backgroundSteps = ruleBackground?.steps ?? const <cm.Step>[];
    final ruleDecorators = _decorators(rule.tags);

    return rule.children
        .map((c) => c.scenario)
        .whereType<cm.Scenario>()
        .map((s) => _scenario(s, leadingSteps: backgroundSteps, inheritedDecorators: ruleDecorators))
        .toList();
  }

  Scenario _scenario(
    cm.Scenario scenario, {
    List<cm.Step> leadingSteps = const [],
    Set<Decorator> inheritedDecorators = const {},
  }) {
    return Scenario(
      scenario.name,
      [...leadingSteps, ...scenario.steps].map(_step).toList(),
      examples: _examples(scenario.examples),
      decorators: {...inheritedDecorators, ..._decorators(scenario.tags)},
    );
  }

  Background _background(cm.Background background) {
    return Background(description: background.name, steps: background.steps.map(_step).toList());
  }

  Step _step(cm.Step step) {
    return Step(
      step.keyword.trim(),
      step.text.trim(),
      keywordType: _keywordType(step.keywordType),
      docString: step.docString?.content,
      dataTable: step.dataTable?.rows.map((r) => r.cells.map((c) => c.value).toList()).toList(),
    );
  }

  StepKeywordType _keywordType(cm.StepKeywordType? type) {
    return switch (type) {
      cm.StepKeywordType.context => StepKeywordType.context,
      cm.StepKeywordType.action => StepKeywordType.action,
      cm.StepKeywordType.outcome => StepKeywordType.outcome,
      cm.StepKeywordType.conjunction => StepKeywordType.conjunction,
      cm.StepKeywordType.unknown || null => StepKeywordType.unknown,
    };
  }

  /// Flattens every `Examples:` block into header-to-value maps.
  ///
  /// Returns `null` when the scenario has no example rows, matching scenarios
  /// without an Examples table.
  List<Map<String, String>>? _examples(List<cm.Examples> examples) {
    final rows = <Map<String, String>>[];
    for (final block in examples) {
      final header = block.tableHeader;
      if (header == null) continue;
      final keys = header.cells.map((c) => c.value).toList();
      for (final row in block.tableBody) {
        rows.add(Map.fromIterables(keys, row.cells.map((c) => c.value)));
      }
    }
    return rows.isEmpty ? null : rows;
  }

  Set<Decorator> _decorators(List<cm.Tag> tags) {
    return tags.map((t) => Decorator.fromString(t.name)).toSet();
  }
}
