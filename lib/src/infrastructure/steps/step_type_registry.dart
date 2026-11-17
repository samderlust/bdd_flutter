import 'package:cucumber_expressions/cucumber_expressions.dart' as ce;

import '../../domain/parameter_type_definition.dart';
import '../../domain/steps_problem.dart';

/// The parameter types expressions can use: Cucumber's built-in types,
/// `{num}` and `{bool}` added by bdd_flutter, and the user's
/// `@ParameterType` methods.
///
/// `{num}` and `{bool}` keep the types of 2.x step methods, so migrated
/// signatures do not change.
class StepTypeRegistry {
  /// The registry handed to `ExpressionFactory`.
  final ce.ParameterTypeRegistry registry;

  /// Names of the user's types, whose values are converted by their method
  /// when the test runs.
  final Set<String> customNames;

  /// Types that could not be registered: duplicate names, invalid regexes.
  final List<StepsProblem> problems;

  StepTypeRegistry._(this.registry, this.customNames, this.problems);

  static const String _numberRegex = r'[-+]?(?:\d+(?:\.\d+)?|\.\d+)(?:[E][+-]?\d+)?';

  /// A registry with the built-in types and every type in [types].
  factory StepTypeRegistry.build(Iterable<ParameterTypeDefinition> types) {
    final registry = ce.ParameterTypeRegistry();
    _defineBuiltIns(registry);
    final customNames = <String>{};
    final problems = <StepsProblem>[];
    for (final type in types) {
      final problem = _defineCustom(registry, type);
      problem == null ? customNames.add(type.name) : problems.add(StepsProblem(type.location, problem));
    }
    return StepTypeRegistry._(registry, customNames, problems);
  }

  static void _defineBuiltIns(ce.ParameterTypeRegistry registry) {
    registry
      ..defineParameterType(
        ce.ParameterType<num>('num', _numberRegex, 'num', (g) => num.parse(g.first!), useForSnippets: false),
      )
      ..defineParameterType(
        ce.ParameterType<bool>('bool', r'true|false', 'bool', (g) => g.first == 'true', useForSnippets: false),
      );
  }

  /// Registers [type]; returns why it could not be, or null.
  static String? _defineCustom(ce.ParameterTypeRegistry registry, ParameterTypeDefinition type) {
    try {
      RegExp(type.regex);
    } on FormatException catch (e) {
      return "Invalid regex for parameter type '${type.name}': ${e.message}";
    }
    try {
      registry.defineParameterType(ce.ParameterType<Object?>(type.name, type.regex, type.dartType, (_) => null));
      return null;
    } on ce.CucumberExpressionException catch (e) {
      return "Parameter type '${type.name}': ${e.message}";
    }
  }
}
