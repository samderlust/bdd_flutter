import '../../domain/feature.dart';
import '../../domain/step.dart';
import '../../domain/step_method.dart';
import '../../domain/step_pattern.dart';
import '../../domain/value_type.dart';
import '../../extensions/string_x.dart';
import 'column_types.dart';
import 'step_pattern_parser.dart';

/// The methods of one feature's steps class: one per distinct step pattern,
/// across backgrounds, scenarios and rules.
class StepsCatalog {
  final StepPatternParser _parser;
  final Map<String, StepMethod> _methodsByKey;

  StepsCatalog._(this._parser, this._methodsByKey);

  /// Collects every step of [feature] and names its methods.
  factory StepsCatalog.of(Feature feature, {StepPatternParser parser = const StepPatternParser()}) {
    final occurrences = <String, List<(Step, StepPattern)>>{};
    for (final (step, columns) in _stepsWithColumns(feature)) {
      final pattern = parser.parse(step, columns: columns);
      occurrences.putIfAbsent(pattern.key, () => []).add((step, pattern));
    }
    return StepsCatalog._(parser, _nameMethods(occurrences));
  }

  /// The methods in order of first use.
  List<StepMethod> get methods => _methodsByKey.values.toList();

  /// The pattern of [step] inside a scenario with Examples [columns].
  StepPattern patternOf(Step step, {Map<String, ValueType> columns = const {}}) {
    return _parser.parse(step, columns: columns);
  }

  /// The method that [pattern] calls.
  StepMethod methodOf(StepPattern pattern) => _methodsByKey[pattern.key]!;

  static Iterable<(Step, Map<String, ValueType>)> _stepsWithColumns(Feature feature) sync* {
    for (final step in feature.background?.steps ?? const <Step>[]) {
      yield (step, const {});
    }
    for (final scenario in feature.scenarios) {
      final columns = columnTypes(scenario.examples);
      for (final step in scenario.steps) {
        yield (step, columns);
      }
    }
    for (final rule in feature.rules) {
      for (final step in rule.background?.steps ?? const <Step>[]) {
        yield (step, const {});
      }
      for (final scenario in rule.scenarios) {
        final columns = columnTypes(scenario.examples);
        for (final step in scenario.steps) {
          yield (step, columns);
        }
      }
    }
  }

  static Map<String, StepMethod> _nameMethods(Map<String, List<(Step, StepPattern)>> occurrences) {
    final usedNames = <String>{};
    return occurrences.map((key, steps) {
      final pattern = steps.first.$2;
      final baseName = pattern.nameText.toCamelIdentifier() ?? 'step${key.shortHash}';
      final name = _unique(baseName, usedNames);
      final method = StepMethod(
        name: name,
        parameters: _parameters(steps.map((s) => s.$2).toList()),
        stepMessages: steps.map((s) => s.$1.message).toSet().toList(),
      );
      return MapEntry(key, method);
    });
  }

  /// Parameter names come from the first placeholder seen in each slot
  /// position, else from the type: `text`, `number`, `flag`.
  static List<StepParameter> _parameters(List<StepPattern> patterns) {
    final first = patterns.first;
    final usedNames = <String>{if (first.hasDocString) 'docString', if (first.hasDataTable) 'dataTable'};
    return [
      for (var i = 0; i < first.slots.length; i++)
        StepParameter(first.slots[i].type.dartType, _unique(_slotName(patterns, i), usedNames)),
      if (first.hasDocString) const StepParameter('String', 'docString'),
      if (first.hasDataTable) const StepParameter('List<List<String>>', 'dataTable'),
    ];
  }

  static String _slotName(List<StepPattern> patterns, int index) {
    for (final pattern in patterns) {
      final name = pattern.slots[index].placeholder?.toCamelIdentifier(prefix: 'value');
      if (name != null) return name;
    }
    return switch (patterns.first.slots[index].type) {
      ValueType.string => 'text',
      ValueType.number => 'number',
      ValueType.boolean => 'flag',
    };
  }

  static String _unique(String name, Set<String> used) {
    var candidate = name;
    for (var i = 2; !used.add(candidate); i++) {
      candidate = '$name$i';
    }
    return candidate;
  }
}
