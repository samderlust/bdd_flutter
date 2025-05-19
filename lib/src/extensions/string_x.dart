extension StringX on String {
  String get name {
    return split(' ').where((word) => word.isNotEmpty).map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join('');
  }

  String get toScenarioClassName {
    return "${name}Scenario";
  }

  String get snakeCaseToCamelCase {
    return split('_').map((word) => word[0].toLowerCase() + word.substring(1).toLowerCase()).join('');
  }

  String get toSnakeCase {
    return split(' ').map((word) => word.toLowerCase()).join('_');
  }
}
