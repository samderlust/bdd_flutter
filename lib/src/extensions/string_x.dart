/// String utilities for name conversion in code generation.
extension StringX on String {
  /// Converts a space-separated string to PascalCase.
  ///
  /// Example: `"successful login"` -> `"SuccessfulLogin"`.
  String get name {
    return split(' ').where((word) => word.isNotEmpty).map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join('');
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
  /// Example: `"first_name"` -> `"firstName"`.
  String get snakeCaseToCamelCase {
    final parts = split('_');
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
