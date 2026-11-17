/// One value a step's text supplies for a parameter of the matched
/// expression.
class MatchedArgument {
  /// The parameter type's name, e.g. `int`, `string`, `status`; empty for
  /// the anonymous `{}`.
  final String typeName;

  /// The matched text as written in the step, e.g. `"apple"` with quotes.
  final String text;

  /// The value the parameter type gives for [text]: `int`, `double`, `num`,
  /// `bool` or `String` for built-in types; `null` for custom types, which
  /// are converted by the user's method when the test runs.
  final Object? value;

  /// Whether the type is a custom `@ParameterType`.
  final bool isCustom;

  const MatchedArgument({required this.typeName, required this.text, required this.value, this.isCustom = false});
}
