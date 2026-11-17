import 'package:bdd_flutter/src/domain/source_location.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/domain/step_definition.dart';
import 'package:bdd_flutter/src/domain/step_keyword_type.dart';
import 'package:bdd_flutter/src/domain/steps_class.dart';
import 'package:bdd_flutter/src/domain/value_type.dart';
import 'package:bdd_flutter/src/infrastructure/migration/expression_annotations.dart';
import 'package:bdd_flutter/src/infrastructure/steps/step_matcher.dart';
import 'package:bdd_flutter/src/infrastructure/steps/step_pattern_parser.dart';
import 'package:test/test.dart';

String _expression(String text, {Map<String, ValueType> columns = const {}, String? docString}) {
  final step = Step('Given', text, docString: docString);
  return ExpressionAnnotations.expressionOf(step, const StepPatternParser().parse(step, columns: columns));
}

void main() {
  group('ExpressionAnnotations.expressionOf', () {
    test('keeps 2.x types: numbers as {num}, quoted text as {string}', () {
      expect(_expression('I add 2 "apple" at 1.5 each'), 'I add {num} {string} at {num} each');
    });

    test('types outline placeholders from their columns', () {
      final columns = {'qty': ValueType.number, 'item': ValueType.string, 'on': ValueType.boolean};

      expect(_expression('I add <qty> "<item>"', columns: columns), 'I add {num} {string}');
      expect(_expression('I add <qty> <item>', columns: columns), 'I add {num} {}');
      expect(_expression('the flag is <on>', columns: columns), 'the flag is {bool}');
    });

    test('keeps literal numbers and escapes expression syntax', () {
      expect(_expression('the time is 09:00'), 'the time is 09:00');
      expect(_expression('I pick a/b (maybe) {x}'), r'I pick a\/b \(maybe\) \{x\}');
      expect(_expression(r'a back\slash'), r'a back\\slash');
    });

    test('leaves out the doc string marker', () {
      expect(_expression('the note:', docString: 'hi'), 'the note:');
    });

    test('matches the step it was made from, with the 2.x values', () {
      // Arrange
      const texts = [
        'I add 2 "apple" at 1.5 each',
        'I pick a/b (maybe) {x} at 09:00',
        r'a back\slash costs $10.00',
        'I increment the <counter>',
      ];

      for (final text in texts) {
        // Act
        final definition = StepDefinition(
          expression: _expression(text),
          ownerName: 'S',
          methodName: 'm',
          parameters: const [],
          location: const SourceLocation('s.dart', 1),
        );
        final matcher = StepMatcher.build(
          own: StepsClass(name: 'S', path: 's.dart', steps: [definition]),
        );

        // Assert
        expect(matcher.problems, isEmpty, reason: text);
        expect(matcher.match(text).single, isNotNull, reason: text);
      }
      final values = StepMatcher.build(
        own: StepsClass(
          name: 'S',
          path: 's.dart',
          steps: [
            StepDefinition(
              expression: _expression('I add 2 "apple" at 1.5 each'),
              ownerName: 'S',
              methodName: 'm',
              parameters: const [],
              location: const SourceLocation('s.dart', 1),
            ),
          ],
        ),
      ).match('I add 2 "apple" at 1.5 each').single!.arguments.map((a) => a.value);
      expect(values, [2, 'apple', 1.5]);
    });
  });

  group('ExpressionAnnotations.annotationNameFor', () {
    test('follows the keyword, And/But taking the previous one', () {
      expect(ExpressionAnnotations.annotationNameFor(StepKeywordType.context), 'Given');
      expect(ExpressionAnnotations.annotationNameFor(StepKeywordType.action), 'When');
      expect(ExpressionAnnotations.annotationNameFor(StepKeywordType.outcome), 'Then');
      expect(
        ExpressionAnnotations.annotationNameFor(StepKeywordType.conjunction, previous: StepKeywordType.outcome),
        'Then',
      );
      expect(ExpressionAnnotations.annotationNameFor(StepKeywordType.conjunction), 'StepDefinition');
      expect(ExpressionAnnotations.annotationNameFor(StepKeywordType.unknown), 'StepDefinition');
      expect(
        ExpressionAnnotations.annotationNameFor(StepKeywordType.unknown, previous: StepKeywordType.action),
        'When',
      );
    });
  });

  group('ExpressionAnnotations.annotationFor', () {
    test('writes a plain literal when it can', () {
      expect(ExpressionAnnotations.annotationFor('I add {num}'), "@StepDefinition('I add {num}')");
      expect(ExpressionAnnotations.annotationFor("it's {string}", annotation: 'Given'), '@Given("it\'s {string}")');
    });

    test('uses a raw string for backslashes and dollars', () {
      expect(ExpressionAnnotations.annotationFor(r'a\/b costs $1', annotation: 'When'), r"@When(r'a\/b costs $1')");
    });

    test('escapes when both quote kinds appear', () {
      expect(ExpressionAnnotations.annotationFor('''it's "x" \$1'''), r"""@StepDefinition('it\'s "x" \$1')""");
    });
  });
}
