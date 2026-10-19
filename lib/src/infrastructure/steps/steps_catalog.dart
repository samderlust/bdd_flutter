import '../../domain/feature.dart';
import '../../domain/step.dart';
import '../../domain/step_method.dart';
import '../../domain/step_pattern.dart';
import '../../domain/value_type.dart';
import '../../extensions/string_x.dart';
import 'column_types.dart';
import 'step_pattern_parser.dart';

/// The step methods of a set of features: one per distinct step pattern
/// in each feature, across backgrounds, scenarios and rules.
///
/// Names are worked out per feature, so a feature's method names depend
/// only on its own steps: adding or changing another feature never renames
/// them. The same step gets the same name in every feature, because the
/// name comes from its text, so it can be written once in the shared steps
/// mixin.
class StepsCatalog {
  final StepPatternParser _parser;
  final Map<String, Map<String, StepMethod>> _methodsByFeature;
  final Map<String, List<String>> _featuresByKey;

  /// Steps that map to the same method name as another step in the same
  /// feature, and so got a numbered name, e.g. `theCartHasItem2`.
  final List<NameCollision> nameCollisions;

  StepsCatalog._(this._parser, this._methodsByFeature, this._featuresByKey, this.nameCollisions);

  /// Collects the steps of [features] and names their methods.
  factory StepsCatalog.of(List<Feature> features, {StepPatternParser parser = const StepPatternParser()}) {
    final sorted = [...features]..sort((a, b) => a.path.compareTo(b.path));
    final methodsByFeature = <String, Map<String, StepMethod>>{};
    final featuresByKey = <String, List<String>>{};
    final collisions = <NameCollision>[];
    for (final feature in sorted) {
      final occurrences = <String, List<(Step, StepPattern)>>{};
      for (final (step, columns) in _stepsWithColumns(feature)) {
        final pattern = parser.parse(step, columns: columns);
        occurrences.putIfAbsent(pattern.key, () => []).add((step, pattern));
      }
      methodsByFeature[feature.path] = _nameMethods(occurrences, collisions, feature.fileName);
      for (final key in occurrences.keys) {
        featuresByKey.putIfAbsent(key, () => []).add(feature.path);
      }
    }
    return StepsCatalog._(parser, methodsByFeature, featuresByKey, collisions);
  }

  /// One method per distinct step across all features (the first feature's,
  /// in path order), in order of first use.
  List<StepMethod> get methods {
    final byKey = <String, StepMethod>{};
    for (final methods in _methodsByFeature.values) {
      for (final MapEntry(:key, :value) in methods.entries) {
        byKey.putIfAbsent(key, () => value);
      }
    }
    return byKey.values.toList();
  }

  /// The methods [feature] uses, in order of first use in that feature.
  List<StepMethod> methodsFor(Feature feature) => (_methodsByFeature[feature.path] ?? const {}).values.toList();

  /// The steps used by two or more features, in order of first use:
  /// candidates for the shared steps mixin.
  List<StepMethod> get sharedMethods {
    return [
      for (final method in methods)
        if (_featuresByKey[_keyOf(method)]!.length > 1) method,
    ];
  }

  /// The `.feature` paths that use [method]'s step, in path order.
  List<String> featuresUsing(StepMethod method) => _featuresByKey[_keyOf(method)]!;

  /// The pattern of [step] inside a scenario with Examples [columns].
  StepPattern patternOf(Step step, {Map<String, ValueType> columns = const {}}) {
    return _parser.parse(step, columns: columns);
  }

  /// The method of [feature] that [pattern] calls.
  StepMethod methodOf(Feature feature, StepPattern pattern) => _methodsByFeature[feature.path]![pattern.key]!;

  String _keyOf(StepMethod method) {
    for (final methods in _methodsByFeature.values) {
      for (final MapEntry(:key, :value) in methods.entries) {
        if (identical(value, method)) return key;
      }
    }
    throw ArgumentError.value(method.name, 'method', 'not in this catalog');
  }

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

  static Map<String, StepMethod> _nameMethods(
    Map<String, List<(Step, StepPattern)>> occurrences,
    List<NameCollision> collisions,
    String featureName,
  ) {
    final usedNames = <String>{};
    final firstStepByName = <String, String>{};
    return occurrences.map((key, steps) {
      final pattern = steps.first.$2;
      final baseName = pattern.nameText.toCamelIdentifier() ?? 'step${key.shortHash}';
      final name = _unique(baseName, usedNames);
      final message = steps.first.$1.message;
      firstStepByName.putIfAbsent(baseName, () => message);
      if (name != baseName) {
        collisions.add(NameCollision(name, message, baseName, firstStepByName[baseName]!, '$featureName.feature'));
      }
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

/// A step whose method name clashed with a different step's.
class NameCollision {
  /// The numbered name the step got, e.g. `theCartHasItem2`.
  final String name;

  /// The step that got [name].
  final String step;

  /// The name both steps map to, e.g. `theCartHasItem`.
  final String baseName;

  /// The step that kept [baseName].
  final String otherStep;

  /// The `.feature` file both steps are in.
  final String feature;

  const NameCollision(this.name, this.step, this.baseName, this.otherStep, this.feature);

  @override
  String toString() =>
      '$feature: `$step` is named $name because `$otherStep` already uses $baseName. '
      'Reword one of the steps to give each a clear name.';
}
