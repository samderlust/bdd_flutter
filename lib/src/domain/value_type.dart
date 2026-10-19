/// The Dart type of a value passed from a `.feature` file to a step method.
enum ValueType {
  /// Text, passed as `String`.
  string('String', 'string'),

  /// A number written exactly as Dart prints it, passed as `num`.
  number('num', 'num'),

  /// `true` or `false`, passed as `bool`.
  boolean('bool', 'bool');

  /// The Dart type used in generated parameter declarations.
  final String dartType;

  /// The marker used in a step pattern, e.g. `{num}`.
  final String marker;

  const ValueType(this.dartType, this.marker);

  /// The type of a single raw [value] from an Examples table.
  ///
  /// A value is a number only if Dart prints it back unchanged, so `02134`,
  /// `1.50` and `1e3` stay text and never lose characters.
  static ValueType of(String value) {
    if (value == 'true' || value == 'false') return ValueType.boolean;
    final number = num.tryParse(value);
    if (number != null && number.toString() == value) return ValueType.number;
    return ValueType.string;
  }

  /// The common type of all [values]: their shared type, or [string].
  static ValueType ofAll(Iterable<String> values) {
    final types = values.map(of).toSet();
    return types.length == 1 ? types.single : ValueType.string;
  }
}
