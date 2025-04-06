extension StringX on String {
  String get toMethodName {
    final words = replaceAll(RegExp(r'<[^>]+>'), '').split(' ');
    if (words.isEmpty) return '';

    return words[0].toLowerCase() +
        words
            .skip(1)
            .where((word) => word.isNotEmpty)
            .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join('');
  }

  String get name {
    return split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join('');
  }

  String get toClassName {
    return "${name}Scenario";
  }

  String get snakeCaseToCamelCase {
    return split('_')
        .map((word) => word[0].toLowerCase() + word.substring(1).toLowerCase())
        .join('');
  }
}
