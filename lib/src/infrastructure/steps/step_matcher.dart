import 'package:cucumber_expressions/cucumber_expressions.dart' as ce;

import '../../domain/matched_argument.dart';
import '../../domain/step_definition.dart';
import '../../domain/step_match.dart';
import '../../domain/step_match_result.dart';
import '../../domain/steps_class.dart';
import '../../domain/steps_problem.dart';
import 'step_type_registry.dart';

/// Finds the step definitions whose Cucumber Expression matches a step's
/// text, and the values that text supplies.
///
/// The feature's own steps class is tried first; shared classes only when
/// none of its definitions matches, so a feature can override a shared step.
/// Parameter types from every class can be used in every expression.
class StepMatcher {
  final List<List<_CompiledStep>> _tiers;
  final Set<String> _customTypes;

  /// Expressions and parameter types that could not be compiled; their
  /// definitions never match.
  final List<StepsProblem> problems;

  StepMatcher._(this._tiers, this._customTypes, this.problems);

  /// A matcher over the definitions of [own] (the feature's steps class)
  /// and then [shared].
  factory StepMatcher.build({StepsClass? own, List<StepsClass> shared = const []}) {
    final classes = [?own, ...shared];
    final types = StepTypeRegistry.build(classes.expand((c) => c.parameterTypes));
    final problems = [...types.problems];
    final factory = ce.ExpressionFactory(types.registry);
    final tiers = [
      _compile(own?.steps ?? const [], factory, problems),
      _compile(shared.expand((c) => c.steps), factory, problems),
    ];
    return StepMatcher._(tiers, types.customNames, problems);
  }

  static List<_CompiledStep> _compile(
    Iterable<StepDefinition> definitions,
    ce.ExpressionFactory factory,
    List<StepsProblem> problems,
  ) {
    final compiled = <_CompiledStep>[];
    for (final definition in definitions) {
      try {
        compiled.add(_CompiledStep(definition, factory.createExpression(definition.expression)));
      } on ce.CucumberExpressionException catch (e) {
        problems.add(StepsProblem(definition.location, "Invalid expression '${definition.expression}': ${e.message}"));
      }
    }
    return compiled;
  }

  /// The definitions matching [text], a step's text without its keyword.
  ///
  /// In a Scenario Outline, [text] is the step with an Examples row's
  /// values in place of its `<column>` placeholders.
  StepMatchResult match(String text) {
    for (final tier in _tiers) {
      final matches = [
        for (final step in tier)
          if (step.expression.match(text) case final List<ce.Argument<Object?>> arguments)
            StepMatch(step.definition, arguments.map(_argument).toList()),
      ];
      if (matches.isNotEmpty) return StepMatchResult(matches);
    }
    return const StepMatchResult([]);
  }

  MatchedArgument _argument(ce.Argument<Object?> argument) {
    final typeName = argument.parameterType.name ?? '';
    final isCustom = _customTypes.contains(typeName);
    return MatchedArgument(
      typeName: typeName,
      text: argument.group.value ?? '',
      value: isCustom ? null : argument.getValue(),
      isCustom: isCustom,
    );
  }
}

/// A definition with its compiled expression.
class _CompiledStep {
  final StepDefinition definition;
  final ce.Expression expression;

  const _CompiledStep(this.definition, this.expression);
}
