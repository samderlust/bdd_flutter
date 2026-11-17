import '../../domain/step.dart';
import '../../domain/step_pattern.dart';
import '../../domain/value_type.dart';
import '../../extensions/string_x.dart';
import 'row_values.dart';

/// The Dart arguments for calling [step]'s method, in parameter order:
/// slots, doc string, data table.
///
/// Inside a Scenario Outline, [row] fills `<column>` placeholders in slots,
/// doc strings and data tables. A placeholder with no value in [row] stays
/// as its `<column>` text.
List<String> stepArguments(Step step, StepPattern pattern, {Map<String, String> row = const {}}) {
  final values = RowValues(row);
  final docString = step.docString;
  final dataTable = step.dataTable;
  return [
    for (final slot in pattern.slots) _slotLiteral(slot, values),
    if (docString != null) values.docStringLiteral(docString),
    if (dataTable != null) values.dataTableLiteral(dataTable),
  ];
}

String _slotLiteral(StepSlot slot, RowValues values) {
  final value = values.fill(slot.template);
  return slot.type == ValueType.string ? value.toDartStringLiteral : value;
}
