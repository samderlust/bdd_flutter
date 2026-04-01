/// A step is a keyword and a text
class Step {
  /// The keyword of the step
  final String keyword;

  /// The text of the step
  final String text;

  Step(this.keyword, this.text);

  @override
  String toString() {
    return '$keyword $text';
  }
}

extension StepX on Step {
  String get message => '$keyword $text';
  String get methodName {
    // First, replace parameters with their names
    var processedText = text;
    final paramRegex = RegExp(r'<(\w+)>');
    final paramMatches = paramRegex.allMatches(text);
    for (var match in paramMatches) {
      final paramName = match.group(1)!;
      processedText = processedText.replaceAll(match.group(0)!, paramName);
    }

    // Split into words and process
    final words = processedText.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').split(' ').where((word) => word.isNotEmpty).toList();

    if (words.isEmpty) return '';

    // Convert to camelCase
    return words[0].toLowerCase() +
        words
            .skip(1)
            .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join('');
  }
}
