import '../../domain/step.dart';
import '../../domain/step_pattern.dart';
import '../../domain/value_type.dart';

/// Takes the values out of a step's text, the way Cucumber Expressions do.
///
/// A slot is:
/// - text in double quotes, including `"<column>"`: a `String`;
/// - a bare `<column>` placeholder whose column exists: typed from the
///   column's values;
/// - a number standing alone that Dart prints back unchanged: a `num`.
///   `3rd`, `09:00`, `$10.00`, `15%` and `1-second` stay part of the text.
class StepPatternParser {
  const StepPatternParser();

  static final RegExp _token = RegExp(
    r'"([^"]*)"' // quoted text
    r'|<([^<>]+)>' // placeholder
    r'|(?<![\w$.:,/-])(-?\d+(?:\.\d+)?)(?![\w:%,/-]|\.\d)', // standalone number
  );

  static final RegExp _singlePlaceholder = RegExp(r'^<([^<>]+)>$');

  /// The pattern of [step], with placeholder types from [columns].
  StepPattern parse(Step step, {Map<String, ValueType> columns = const {}}) {
    final key = StringBuffer();
    final nameText = StringBuffer();
    final slots = <StepSlot>[];
    var last = 0;
    for (final match in _token.allMatches(step.text)) {
      final slot = _slot(match, columns);
      if (slot == null) continue;
      final before = step.text.substring(last, match.start);
      key
        ..write(before)
        ..write('{${slot.type.marker}}');
      nameText.write('$before ');
      slots.add(slot);
      last = match.end;
    }
    final rest = step.text.substring(last);
    key.write(rest);
    nameText.write(rest);
    if (step.docString != null) key.write(' +docString');
    if (step.dataTable != null) key.write(' +dataTable');
    return StepPattern(
      key: key.toString(),
      nameText: nameText.toString(),
      slots: slots,
      hasDocString: step.docString != null,
      hasDataTable: step.dataTable != null,
    );
  }

  StepSlot? _slot(RegExpMatch match, Map<String, ValueType> columns) {
    final quoted = match.group(1);
    if (quoted != null) return _quotedSlot(quoted, columns);
    final placeholder = match.group(2);
    if (placeholder != null) return _placeholderSlot(placeholder, columns);
    return _numberSlot(match.group(3)!);
  }

  StepSlot _quotedSlot(String text, Map<String, ValueType> columns) {
    final name = _singlePlaceholder.firstMatch(text)?.group(1);
    return StepSlot(
      type: ValueType.string,
      template: text,
      placeholder: name != null && columns.containsKey(name) ? name : null,
    );
  }

  StepSlot? _placeholderSlot(String name, Map<String, ValueType> columns) {
    final type = columns[name];
    if (type == null) return null;
    return StepSlot(type: type, template: '<$name>', placeholder: name);
  }

  StepSlot? _numberSlot(String text) {
    if (ValueType.of(text) != ValueType.number) return null;
    return StepSlot(type: ValueType.number, template: text);
  }
}
