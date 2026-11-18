import 'step_method.dart';

/// A suggested step definition for a step no definition matches.
class StepSnippet {
  /// The annotation name: `Given`, `When`, `Then` or `StepDefinition`.
  final String annotation;

  /// The Cucumber Expression that matches the step's text.
  final String expression;

  /// The method name before it is made unique in its class.
  final String methodName;

  /// The parameters: one per `{parameter}`, then the doc string and the
  /// data table.
  final List<StepParameter> parameters;

  const StepSnippet({
    required this.annotation,
    required this.expression,
    required this.methodName,
    required this.parameters,
  });

  /// Identifies snippets that one method can serve: the same expression
  /// and the same doc string and data table arguments.
  String get key => '$expression|${parameters.map((p) => p.dartType).join(',')}';
}
