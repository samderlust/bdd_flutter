import 'step_keyword_type.dart';

/// Represents a single step in a Gherkin scenario.
///
/// A step has a [keyword] (Given, When, Then, And, ...) and [text] describing
/// the action. In a Scenario Outline the text can hold `<column>` placeholders.
class Step {
  /// The Gherkin keyword as written, e.g. `Given`, `And`, `But` or `*`.
  final String keyword;

  /// The step text, potentially containing `<column>` placeholders.
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

  const Step(this.keyword, this.text, {this.keywordType = StepKeywordType.unknown, this.docString, this.dataTable});

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
  /// The full step message (keyword + text).
  String get message => '$keyword $text';
}
