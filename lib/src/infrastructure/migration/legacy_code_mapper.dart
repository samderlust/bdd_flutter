import '../../domain/feature.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';
import '../../domain/step_method.dart';
import '../../domain/value_type.dart';
import '../builders/steps_stub_builder.dart';
import '../steps/column_types.dart';
import '../steps/steps_catalog.dart';
import 'legacy_names.dart';
import 'legacy_scenarios_file.dart';

/// A 1.x method body that maps to a 2.0 step method.
class _Source {
  final String className;
  final LegacyMethod method;

  const _Source(this.className, this.method);
}

/// The outcome of mapping one 1.x file.
class LegacyMapping {
  /// What goes into the new steps file.
  final StepsStubContent content;

  /// Methods whose 1.x body was copied as working code.
  final int copied;

  /// Methods whose 1.x code was copied as comments to adapt by hand.
  final int toReview;

  const LegacyMapping(this.content, {required this.copied, required this.toReview});
}

/// Maps the user's code in a 1.x `.bdd_scenarios.dart` file onto the 2.0
/// steps methods of the same feature.
///
/// A 1.x body is copied as working code only when the 2.0 method takes no
/// values from the step text and every 1.x body for it is the same. All
/// other bodies are copied as comments above a `throw`, because 2.0 passes
/// values the 1.x code had written in.
class LegacyCodeMapper {
  /// The `scenario_suffix` the 1.x files were generated with.
  final String scenarioSuffix;

  const LegacyCodeMapper({this.scenarioSuffix = 'Scenario'});

  /// Maps [legacy] onto [catalog]'s methods for [feature].
  LegacyMapping map(Feature feature, StepsCatalog catalog, LegacyScenariosFile legacy) {
    final sources = <String, List<_Source>>{};
    for (final (className, steps, columns) in _legacyClasses(feature)) {
      final legacyClass = legacy.classes[className];
      if (legacyClass == null) continue;
      for (final step in steps) {
        final method = legacyClass.methods[LegacyNames.methodName(step.text)];
        if (method == null || !method.hasCode) continue;
        final target = catalog.methodOf(catalog.patternOf(step, columns: columns));
        sources.putIfAbsent(target.name, () => []).add(_Source(className, method));
      }
    }
    return _mapping(catalog, legacy, sources);
  }

  LegacyMapping _mapping(StepsCatalog catalog, LegacyScenariosFile legacy, Map<String, List<_Source>> sources) {
    final bodies = <String, String>{};
    var copied = 0;
    for (final method in catalog.methods) {
      final found = sources[method.name];
      if (found == null) continue;
      final live = _liveBody(method, found);
      bodies[method.name] = live ?? _commentedBody(found);
      if (live != null) copied++;
    }
    final content = StepsStubContent(
      imports: legacy.imports,
      topLevel: legacy.topLevel,
      fields: {for (final c in legacy.classes.values) ...c.otherMembers}.toList(),
      bodies: bodies,
    );
    return LegacyMapping(content, copied: copied, toReview: bodies.length - copied);
  }

  /// The 1.x classes of [feature] with the steps they had and their
  /// Examples column types.
  Iterable<(String, List<Step>, Map<String, ValueType>)> _legacyClasses(Feature feature) sync* {
    yield ('${LegacyNames.className(feature.name)}Background', feature.background?.steps ?? const [], const {});
    for (final scenario in feature.scenarios) {
      yield _scenarioClass(scenario, const []);
    }
    for (final rule in feature.rules) {
      for (final scenario in rule.scenarios) {
        yield _scenarioClass(scenario, rule.background?.steps ?? const []);
      }
    }
  }

  (String, List<Step>, Map<String, ValueType>) _scenarioClass(Scenario scenario, List<Step> ruleBackground) {
    final className = '${LegacyNames.className(scenario.name)}$scenarioSuffix';
    return (className, [...ruleBackground, ...scenario.steps], columnTypes(scenario.examples));
  }

  String? _liveBody(StepMethod method, List<_Source> sources) {
    final takesValues = method.parameters.any((p) => p.name != 'docString' && p.name != 'dataTable');
    final distinct = sources.map((s) => _normalize(s.method.body)).toSet();
    if (takesValues || distinct.length != 1) return null;
    return sources.first.method.body.trimRight();
  }

  String _commentedBody(List<_Source> sources) {
    final buffer = StringBuffer(
      '    // Code from bdd_flutter 1.x. Adapt it to the parameters above, then remove the throw.\n',
    );
    final seen = <String>{};
    for (final source in sources) {
      if (!seen.add(_normalize(source.method.body))) continue;
      buffer.writeln('    // ${source.className}.${source.method.name}(${source.method.parameters}):');
      for (final line in source.method.body.trim().split('\n')) {
        buffer.writeln('    //   ${line.trim()}');
      }
    }
    buffer.write('    throw UnimplementedError(\'Adapt the 1.x code above.\');');
    return buffer.toString();
  }

  String _normalize(String body) => body.replaceAll(RegExp(r'\s+'), ' ').trim();
}
