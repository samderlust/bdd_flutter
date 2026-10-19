import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/domain/value_type.dart';
import 'package:bdd_flutter/src/infrastructure/steps/step_pattern_parser.dart';
import 'package:test/test.dart';

void main() {
  const parser = StepPatternParser();

  String keyOf(String text, {Map<String, ValueType> columns = const {}}) {
    return parser.parse(Step('Given', text), columns: columns).key;
  }

  group('StepPatternParser', () {
    test('takes quoted text and numbers out of the step', () {
      final pattern = parser.parse(const Step('When', 'I add 2 "apple" at 1.5 each'));

      expect(pattern.key, 'I add {num} {string} at {num} each');
      expect(pattern.slots.map((s) => s.template), ['2', 'apple', '1.5']);
      expect(pattern.slots.map((s) => s.type), [ValueType.number, ValueType.string, ValueType.number]);
    });

    test('gives a plain step and an outline step the same key', () {
      final columns = {'quantity': ValueType.number, 'item': ValueType.string, 'price': ValueType.number};

      expect(
        keyOf('I add <quantity> "<item>" at <price> each', columns: columns),
        keyOf('I add 2 "apple" at 1.5 each'),
      );
    });

    test('names a quoted slot after its single placeholder', () {
      final pattern = parser.parse(
        const Step('Then', 'the stock of "<from>" is 3'),
        columns: {'from': ValueType.number},
      );

      expect(pattern.slots.first.placeholder, 'from');
      expect(pattern.slots.first.type, ValueType.string);
    });

    test('types a bare placeholder from its column', () {
      expect(keyOf('the flag is <on>', columns: {'on': ValueType.boolean}), 'the flag is {bool}');
    });

    test('leaves placeholders without a column as text', () {
      expect(keyOf('I increment the <counter>'), 'I increment the <counter>');
    });

    test('keeps numbers that are part of a word, time, price or unit', () {
      expect(keyOf('the 3rd refund is blocked'), 'the 3rd refund is blocked');
      expect(keyOf('the time is 09:00'), 'the time is 09:00');
      expect(keyOf(r'a price of $10.00'), r'a price of $10.00');
      expect(keyOf('a 15% discount'), 'a 15% discount');
      expect(keyOf('waits 1-second'), 'waits 1-second');
      expect(keyOf('types "r" 200ms later'), 'types {string} 200ms later');
    });

    test('keeps numbers that would lose characters', () {
      expect(keyOf('the code is 007'), 'the code is 007');
    });

    test('takes out negative numbers and numbers at the end of a sentence', () {
      expect(keyOf('the counter should have value -1'), 'the counter should have value {num}');
      expect(keyOf('the total is 2.'), 'the total is {num}.');
    });

    test('marks doc strings and data tables in the key', () {
      final pattern = parser.parse(
        const Step(
          'Given',
          'the products:',
          docString: '{}',
          dataTable: [
            ['a'],
          ],
        ),
      );

      expect(pattern.key, 'the products: +docString +dataTable');
      expect(pattern.hasDocString, isTrue);
      expect(pattern.hasDataTable, isTrue);
    });

    test('removes slots from the name text', () {
      final pattern = parser.parse(const Step('When', 'I add 2 "apple" at 1.5 each'));

      expect(pattern.nameText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty), ['I', 'add', 'at', 'each']);
    });
  });
}
