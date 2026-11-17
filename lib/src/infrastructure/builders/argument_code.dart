import '../../domain/matched_argument.dart';
import '../../domain/parameter_type_definition.dart';
import '../../extensions/string_x.dart';

/// The Dart code passing [argument] to a step method.
///
/// Built-in values become literals: `2`, `1.5`, `true`, `'apple'`. A custom
/// type becomes a call to its `@ParameterType` method with the matched text,
/// e.g. `CartSteps.status('shipped')`; [customType] is that type's
/// definition.
String argumentCode(MatchedArgument argument, {ParameterTypeDefinition? customType}) {
  if (customType != null) {
    return '${customType.ownerName}.${customType.methodName}(${argument.text.toDartStringLiteral})';
  }
  return switch (argument.value) {
    final double value => _doubleLiteral(value),
    final num value => value.toString(),
    final bool value => value.toString(),
    final BigInt value => 'BigInt.parse(${value.toString().toDartStringLiteral})',
    final String value => value.toDartStringLiteral,
    _ => argument.text.toDartStringLiteral,
  };
}

/// `1.0` rather than `1`, so the literal is a `double`.
String _doubleLiteral(double value) {
  final text = value.toString();
  return text.contains('.') || text.contains('e') ? text : '$text.0';
}
