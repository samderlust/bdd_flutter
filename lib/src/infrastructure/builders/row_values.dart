import '../../extensions/string_x.dart';

/// The values of one Examples row, filled into a step's text, doc string
/// and data table. Outside a Scenario Outline the row is empty and text is
/// left as written.
class RowValues {
  /// Column name to value.
  final Map<String, String> row;

  const RowValues(this.row);

  /// [text] with every `<column>` of [row] replaced by its value. A
  /// placeholder with no value in [row] stays as written.
  String fill(String text) {
    var result = text;
    for (final entry in row.entries) {
      result = result.replaceAll('<${entry.key}>', entry.value);
    }
    return result;
  }

  /// The Dart literal for a doc string, with placeholders filled.
  String docStringLiteral(String docString) => fill(docString).toDartStringLiteral;

  /// The Dart literal for a data table, `List<List<String>>`, with
  /// placeholders filled.
  String dataTableLiteral(List<List<String>> rows) {
    final rowLiterals = rows.map((cells) => '[${cells.map((c) => fill(c).toDartStringLiteral).join(', ')}]');
    return '[${rowLiterals.join(', ')}]';
  }
}
