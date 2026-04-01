/// String utilities for name conversion in code generation.
extension StringX on String {
  /// Converts a space-separated string to a valid PascalCase Dart identifier.
  ///
  /// Strips non-alphanumeric characters, removes leading digits,
  /// and prefixes with `X` if the result would otherwise be empty or start with a digit.
  ///
  /// Example: `"successful login"` -> `"SuccessfulLogin"`.
  /// Example: `"123 login"` -> `"X123Login"`.
  String get name {
    final sanitized = replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ');
    final words = sanitized.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'Unnamed';
    final result = words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join('');
    if (RegExp(r'^[0-9]').hasMatch(result)) return 'X$result';
    return result;
  }

  /// Converts to a scenario class name with the default "Scenario" suffix.
  ///
  /// Example: `"Increment"` -> `"IncrementScenario"`.
  String get toScenarioClassName => toClassName('Scenario');

  /// Converts to a class name with a custom [suffix].
  ///
  /// Example: `"Increment".toClassName("Steps")` -> `"IncrementSteps"`.
  String toClassName(String suffix) {
    return '$name$suffix';
  }

  /// Converts a snake_case string to camelCase.
  ///
  /// Handles leading/trailing underscores and filters empty segments.
  /// Example: `"first_name"` -> `"firstName"`.
  String get snakeCaseToCamelCase {
    final parts = split('_').where((word) => word.isNotEmpty).toList();
    if (parts.isEmpty) return this;
    return parts[0].toLowerCase() +
        parts.skip(1).map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join('');
  }

  /// Converts a space-separated string to snake_case.
  ///
  /// Example: `"Hello World"` -> `"hello_world"`.
  String get toSnakeCase {
    return split(' ').map((word) => word.toLowerCase()).join('_');
  }
}
