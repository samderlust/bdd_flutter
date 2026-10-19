import '../../domain/step.dart';
import '../../domain/step_pattern.dart';
import '../../domain/value_type.dart';
import '../../extensions/string_x.dart';

/// The Dart arguments for calling [step]'s method, in parameter order:
/// slots, doc string, data table.
///
/// Inside a Scenario Outline, [row] fills `<column>` placeholders in slots,
/// doc strings and data tables. A placeholder with no value in [row] stays
/// as its `<column>` text.
List<String> stepArguments(Step step, StepPattern pattern, {Map<String, String> row = const {}}) {
  final docString = step.docString;
  final dataTable = step.dataTable;
  return [
    for (final slot in pattern.slots) _slotLiteral(slot, row),
    if (docString != null) _fill(docString, row).toDartStringLiteral,
    if (dataTable != null) _tableLiteral(dataTable, row),
  ];
}

String _slotLiteral(StepSlot slot, Map<String, String> row) {
  final value = _fill(slot.template, row);
  return slot.type == ValueType.string ? value.toDartStringLiteral : value;
}

String _tableLiteral(List<List<String>> rows, Map<String, String> row) {
  final rowLiterals = rows.map((cells) => '[${cells.map((c) => _fill(c, row).toDartStringLiteral).join(', ')}]');
  return '[${rowLiterals.join(', ')}]';
}

/// [text] with every `<column>` of [row] replaced by its value.
String _fill(String text, Map<String, String> row) {
  var result = text;
  for (final entry in row.entries) {
    result = result.replaceAll('<${entry.key}>', entry.value);
  }
  return result;
}
