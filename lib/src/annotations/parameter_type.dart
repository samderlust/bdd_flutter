/// Defines a custom parameter type for Cucumber Expressions.
///
/// Put it on a static method that takes the matched text and returns the
/// value passed to step methods:
///
/// ```dart
/// @ParameterType(r'shipped|pending|cancelled')
/// static OrderStatus status(String value) => OrderStatus.values.byName(value);
///
/// @Given('the order is {status}')
/// Future<void> theOrderIs(OrderStatus status) async { ... }
/// ```
///
/// The type's name is the method's name unless [name] is given. The
/// generated test calls the method with the matched text, e.g.
/// `CartSteps.status('shipped')`.
///
/// [regex] and [name] must be string literals.
class ParameterType {
  /// The regular expression a value of this type must match.
  final String regex;

  /// The name used in expressions, `{name}`; the method's name when null.
  final String? name;

  /// Defines a parameter type matching [regex].
  const ParameterType(this.regex, {this.name});
}
