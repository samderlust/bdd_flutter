extension StringX on String {
  String get name {
    return split(' ').where((word) => word.isNotEmpty).map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join('');
  }

  String get toScenarioClassName {
    return "${name}Scenario";
  }

  String get snakeCaseToCamelCase {
    final parts = split('_');
    if (parts.isEmpty) return this;
    return parts[0].toLowerCase() +
        parts.skip(1).map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join('');
  }

  String get toSnakeCase {
    return split(' ').map((word) => word.toLowerCase()).join('_');
  }
}
