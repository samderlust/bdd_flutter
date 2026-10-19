import 'value_type.dart';

/// A value taken out of a step's text and passed to its method.
///
/// `I add 2 "apple"` has two slots: the number `2` and the quoted `apple`.
class StepSlot {
  /// The Dart type of the value.
  final ValueType type;

  /// The slot's text as written, without surrounding quotes. It can hold
  /// `<column>` placeholders, which are filled per example row.
  final String template;

  /// The column name when the slot is exactly one placeholder, e.g. `item`
  /// for `"<item>"`; used to name the method parameter.
  final String? placeholder;

  const StepSlot({required this.type, required this.template, this.placeholder});
}

/// The shape of a step once its values are taken out.
///
/// Steps with the same [key] share one generated method:
/// `I add 2 "apple"` and `I add <qty> "<item>"` both have the key
/// `I add {num} {string}`.
class StepPattern {
  /// The step text with each slot replaced by its type marker, plus markers
  /// for an attached doc string or data table.
  final String key;

  /// The step text with every slot removed; the method name is built from it.
  final String nameText;

  /// The values taken out of the text, in order.
  final List<StepSlot> slots;

  /// Whether the step has a doc string, passed as `String docString`.
  final bool hasDocString;

  /// Whether the step has a data table, passed as `List<List<String>> dataTable`.
  final bool hasDataTable;

  const StepPattern({
    required this.key,
    required this.nameText,
    required this.slots,
    this.hasDocString = false,
    this.hasDataTable = false,
  });
}
