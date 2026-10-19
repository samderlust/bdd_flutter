import 'package:cucumber_messages/cucumber_messages.dart' as cm;

import '../../domain/background.dart';
import '../../domain/decorator.dart';
import '../../domain/examples_table.dart';
import '../../domain/feature.dart';
import '../../domain/rule.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';
import '../../domain/step_keyword_type.dart';
import 'feature_parse_exception.dart';

/// Converts the output of the Cucumber parser into bdd_flutter's [Feature].
///
/// This is the only place that knows about `cucumber_messages` types, so
/// upstream changes stay contained here.
class GherkinMapper {
  const GherkinMapper();

  /// Maps the [envelopes] that `generateMessages` produced for the file at
  /// [path] to a [Feature].
  ///
  /// Throws [FeatureParseException] when the envelopes hold parse errors or
  /// no Gherkin document.
  Feature fromEnvelopes(List<cm.Envelope> envelopes, String path) {
    final errors = envelopes.map((e) => e.parseError).whereType<cm.ParseError>().toList();
    if (errors.isNotEmpty) {
      throw FeatureParseException(path, errors.map((e) => e.message).toList());
    }
    final document = envelopes.map((e) => e.gherkinDocument).whereType<cm.GherkinDocument>().firstOrNull;
    if (document == null) {
      throw FeatureParseException(path, const ['No Gherkin document produced']);
    }
    return toFeature(document, path);
  }

  /// Maps [document] parsed from the file at [path] to a [Feature].
  Feature toFeature(cm.GherkinDocument document, String path) {
    final feature = document.feature;
    if (feature == null) {
      return Feature(name: 'Unnamed Feature', path: path, scenarios: const [], decorators: const {});
    }

    return Feature(
      name: feature.name,
      path: path,
      scenarios: feature.children.map((c) => c.scenario).whereType<cm.Scenario>().map(_scenario).toList(),
      rules: feature.children.map((c) => c.rule).whereType<cm.Rule>().map(_rule).toList(),
      background: _firstBackground(feature.children.map((c) => c.background)),
      decorators: _decorators(feature.tags),
      tags: _tags(feature.tags),
    );
  }

  Rule _rule(cm.Rule rule) {
    return Rule(
      name: rule.name,
      background: _firstBackground(rule.children.map((c) => c.background)),
      scenarios: rule.children.map((c) => c.scenario).whereType<cm.Scenario>().map(_scenario).toList(),
      decorators: _decorators(rule.tags),
      tags: _tags(rule.tags),
    );
  }

  Background? _firstBackground(Iterable<cm.Background?> backgrounds) {
    final background = backgrounds.whereType<cm.Background>().firstOrNull;
    if (background == null) return null;
    return Background(description: background.name, steps: background.steps.map(_step).toList());
  }

  Scenario _scenario(cm.Scenario scenario) {
    return Scenario(
      scenario.name,
      scenario.steps.map(_step).toList(),
      examples: scenario.examples.map(_examples).where((t) => t.rows.isNotEmpty).toList(),
      decorators: _decorators(scenario.tags),
      tags: _tags(scenario.tags),
    );
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

  /// One `Examples:` block as header-to-value maps.
  ExamplesTable _examples(cm.Examples block) {
    final header = block.tableHeader;
    final keys = header?.cells.map((c) => c.value).toList() ?? const <String>[];
    return ExamplesTable(
      name: block.name,
      rows: [for (final row in block.tableBody) Map.fromIterables(keys, row.cells.map((c) => c.value))],
      decorators: _decorators(block.tags),
      tags: _tags(block.tags),
    );
  }

  /// The tags that bdd_flutter acts on, e.g. `@unitTest`.
  Set<Decorator> _decorators(List<cm.Tag> tags) {
    return tags.map((t) => Decorator.fromString(t.name)).where((d) => d != Decorator.unknown).toSet();
  }

  /// Every other tag, without the leading `@`.
  Set<String> _tags(List<cm.Tag> tags) {
    return tags.where((t) => Decorator.fromString(t.name) == Decorator.unknown).map((t) => t.name.substring(1)).toSet();
  }
}
