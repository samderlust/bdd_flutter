/// Represents a single step in a Gherkin scenario.
///
/// A step has a [keyword] (Given, When, Then, And) and [text] describing
/// the action. Parameters are denoted with angle brackets (e.g., `<value>`).
class Step {
  /// The Gherkin keyword: `Given`, `When`, `Then`, or `And`.
  final String keyword;

  /// The step text, potentially containing `<param>` placeholders.
  final String text;

  Step(this.keyword, this.text);

  @override
  String toString() {
    return '$keyword $text';
  }
}

/// Extension methods for [Step].
extension StepX on Step {
  /// The full step message (keyword + text).
  String get message => '$keyword $text';

  /// Converts the step text to a camelCase method name.
  ///
  /// Parameters like `<first_name>` are included as part of the name.
  /// Non-alphanumeric characters are stripped.
  String get methodName {
    var processedText = text;
    final paramRegex = RegExp(r'<(\w+)>');
    final paramMatches = paramRegex.allMatches(text);
    for (var match in paramMatches) {
      final paramName = match.group(1)!;
      processedText = processedText.replaceAll(match.group(0)!, paramName);
    }

    final words =
        processedText.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').split(' ').where((word) => word.isNotEmpty).toList();

    if (words.isEmpty) return 'unnamed';

    String result = words[0].toLowerCase() +
        words
            .skip(1)
            .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join('');

    // Strip leading digits to ensure a valid Dart identifier
    result = result.replaceFirst(RegExp(r'^[0-9]+'), '');
    if (result.isEmpty) return 'step';
    // Ensure first char is lowercase after stripping digits
    result = result[0].toLowerCase() + result.substring(1);
    return result;
  }
}
