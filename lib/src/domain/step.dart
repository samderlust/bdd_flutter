import '../extensions/string_x.dart';
import 'step_keyword_type.dart';

/// Represents a single step in a Gherkin scenario.
///
/// A step has a [keyword] (Given, When, Then, And) and [text] describing
/// the action. Parameters are denoted with angle brackets (e.g., `<value>`).
class Step {
  /// The Gherkin keyword as written, e.g. `Given`, `And`, `But` or `*`.
  final String keyword;

  /// The step text, potentially containing `<param>` placeholders.
  final String text;

  /// The role of the step, independent of spoken language.
  ///
  /// `And`, `But` and `*` are [StepKeywordType.conjunction]: they continue
  /// the step before them.
  final StepKeywordType keywordType;

  /// Content of a doc string (`"""` block) attached to the step, if any.
  final String? docString;

  /// Rows of a data table attached to the step, if any. The first row is
  /// the header row as written; bdd_flutter does not treat it specially.
  final List<List<String>>? dataTable;

  const Step(
    this.keyword,
    this.text, {
    this.keywordType = StepKeywordType.unknown,
    this.docString,
    this.dataTable,
  });

  /// Part of the scenario hash input. Steps without a doc string or data
  /// table produce the same string as before these were supported, so their
  /// hashes do not change.
  @override
  String toString() {
    final buffer = StringBuffer('$keyword $text');
    if (docString != null) buffer.write(' docString: $docString');
    if (dataTable != null) buffer.write(' dataTable: $dataTable');
    return buffer.toString();
  }
}

/// Extension methods for [Step].
extension StepX on Step {
  /// Distinct `<param>` names in the order they first appear in [text].
  ///
  /// A placeholder used twice becomes one method parameter.
  List<String> get placeholders {
    return RegExp(r'<(\w+)>').allMatches(text).map((m) => m.group(1)!).toSet().toList();
  }

  /// Parameter declarations for the generated step method, after `tester`.
  ///
  /// Placeholders come first, in text order, then `docString`, then
  /// `dataTable`.
  List<String> get parameterDeclarations {
    return [
      for (final name in placeholders) 'String ${name.snakeCaseToCamelCase}',
      if (docString != null) 'String docString',
      if (dataTable != null) 'List<List<String>> dataTable',
    ];
  }

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
