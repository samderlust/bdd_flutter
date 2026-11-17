import 'source_location.dart';

/// A custom parameter type declared with `@ParameterType` on a static method.
class ParameterTypeDefinition {
  /// The name used in expressions, `{name}`.
  final String name;

  /// The regular expression a value must match.
  final String regex;

  /// The class or mixin that declares the method.
  final String ownerName;

  /// The static method that converts the matched text.
  final String methodName;

  /// The method's return type as written, e.g. `OrderStatus`.
  final String dartType;

  /// Where the annotation is.
  final SourceLocation location;

  const ParameterTypeDefinition({
    required this.name,
    required this.regex,
    required this.ownerName,
    required this.methodName,
    required this.dartType,
    required this.location,
  });
}
