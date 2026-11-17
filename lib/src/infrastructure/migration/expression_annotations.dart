import '../../domain/step.dart';
import '../../domain/step_keyword_type.dart';
import '../../domain/step_pattern.dart';
import '../../domain/value_type.dart';

/// Turns 2.x step patterns into Cucumber Expressions and step annotations,
/// for `migrate`.
///
/// The expression keeps the method's 2.x signature: numbers become
/// `{num}`, `true`/`false` columns `{bool}`, quoted text `{string}`, and a
/// bare `<column>` of text `{}`. Literal text is escaped so `(`, `{` and `/`
/// keep their meaning.
class ExpressionAnnotations {
  const ExpressionAnnotations._();

  static final RegExp _marker = RegExp(r'\{(num|string|bool)\}');
  static final RegExp _special = RegExp(r'[(){}/\\]');

  /// The expression matching [step], whose 2.x pattern is [pattern].
  static String expressionOf(Step step, StepPattern pattern) {
    final key = pattern.key.replaceFirst(RegExp(r'( \+docString)?( \+dataTable)?$'), '');
    final buffer = StringBuffer();
    var last = 0;
    var slot = 0;
    for (final match in _marker.allMatches(key)) {
      buffer
        ..write(_escape(key.substring(last, match.start)))
        ..write(_parameter(step, pattern.slots[slot++]));
      last = match.end;
    }
    buffer.write(_escape(key.substring(last)));
    return buffer.toString();
  }

  static String _parameter(Step step, StepSlot slot) {
    return switch (slot.type) {
      ValueType.number => '{num}',
      ValueType.boolean => '{bool}',
      ValueType.string => step.text.contains('"${slot.template}"') ? '{string}' : '{}',
    };
  }

  static String _escape(String text) => text.replaceAllMapped(_special, (m) => '\\${m[0]}');

  /// The annotation for [expression], e.g. `@When('I add {num}')`, with
  /// the expression as a Dart literal that keeps every character: a raw
  /// string when it holds `\` or `$`.
  static String annotationFor(String expression, {String annotation = 'StepDefinition'}) {
    return '@$annotation(${_literal(expression)})';
  }

  /// The annotation name for a step of [type]: `Given`, `When` or `Then`;
  /// `And`/`But`/`*` (and unknown keywords) take [previous], the type of the
  /// step before them.
  static String annotationNameFor(StepKeywordType type, {StepKeywordType? previous}) {
    final resolved = isConjunction(type) ? previous : type;
    return switch (resolved) {
      StepKeywordType.context => 'Given',
      StepKeywordType.action => 'When',
      StepKeywordType.outcome => 'Then',
      _ => 'StepDefinition',
    };
  }

  /// Whether a step of [type] continues the step before it.
  static bool isConjunction(StepKeywordType type) {
    return type == StepKeywordType.conjunction || type == StepKeywordType.unknown;
  }

  static String _literal(String text) {
    final raw = text.contains(r'\') || text.contains(r'$');
    if (!text.contains("'")) return "${raw ? 'r' : ''}'$text'";
    if (!text.contains('"')) return '${raw ? 'r' : ''}"$text"';
    final escaped = text.replaceAll(r'\', r'\\').replaceAll(r'$', r'\$').replaceAll("'", r"\'");
    return "'$escaped'";
  }
}
