import 'package:bdd_flutter/src/domain/parameter_type_definition.dart';
import 'package:bdd_flutter/src/domain/source_location.dart';
import 'package:bdd_flutter/src/domain/step.dart';
import 'package:bdd_flutter/src/domain/step_keyword_type.dart';
import 'package:bdd_flutter/src/domain/unresolved_reason.dart';
import 'package:bdd_flutter/src/domain/unresolved_step.dart';
import 'package:bdd_flutter/src/infrastructure/builders/snippet_code.dart';
import 'package:bdd_flutter/src/infrastructure/steps/snippet_generator.dart';
import 'package:test/test.dart';

UnresolvedStep _undefined(Step step, {StepKeywordType? type}) {
  return UnresolvedStep(
    step: step,
    text: step.text,
    reason: UnresolvedReason.undefined,
    keywordType: type ?? step.keywordType,
  );
}

void main() {
  group('SnippetGenerator', () {
    test('turns numbers and quoted text into parameters', () {
      // Arrange
      final generator = SnippetGenerator.build(const []);
      const step = Step('When', 'I add 2 "apple" at 1.5 each', keywordType: StepKeywordType.action);

      // Act
      final snippet = generator.snippetFor(_undefined(step));

      // Assert
      expect(snippet.annotation, 'When');
      expect(snippet.expression, 'I add {int} {string} at {float} each');
      expect(snippet.methodName, 'iAddAtEach');
      expect(snippet.parameters.map((p) => p.declaration), ['int number', 'String text', 'double value']);
    });

    test('names parameters after the words around them when a rule applies', () {
      // Arrange
      final generator = SnippetGenerator.build(const []);
      String names(String text) =>
          generator.snippetFor(_undefined(Step('When', text))).parameters.map((p) => p.declaration).join(', ');

      // Act & Assert
      expect(names('I apply the coupon "SAVE10" for 3 days'), 'String coupon, int days');
      expect(names('I pick the "red" colour'), 'String colour');
      expect(names('I pick the "red" gift wrap for her'), 'String giftWrap');
      expect(names('the cart has 2 items and 1 bag'), 'int items, int bag');
      expect(names('I am logged in as "ann"'), 'String text');
      expect(names('I pay 2.5 each'), 'double value');
      expect(names('the price "a" "b"'), 'String price, String text');
    });

    test('keeps names unique when the words repeat', () {
      // Arrange
      final generator = SnippetGenerator.build(const []);

      // Act
      final snippet = generator.snippetFor(_undefined(const Step('When', 'I wait 2 days then 3 days')));

      // Assert
      expect(snippet.parameters.map((p) => p.name), ['days', 'days2']);
    });

    test("uses the user's parameter types", () {
      // Arrange
      const state = ParameterTypeDefinition(
        name: 'state',
        regex: 'open|closed',
        ownerName: 'CartSteps',
        methodName: 'state',
        dartType: 'CartState',
        location: SourceLocation('cart_steps.dart', 1),
      );
      final generator = SnippetGenerator.build([state]);

      // Act
      final snippet = generator.snippetFor(_undefined(const Step('Then', 'the cart is open')));

      // Assert
      expect(snippet.expression, 'the cart is {state}');
      expect(snippet.parameters.single.declaration, 'CartState state');
    });

    test('adds the doc string and data table, takes the keyword the conjunction continues, escapes text', () {
      // Arrange
      final generator = SnippetGenerator.build(const []);
      const step = Step(
        'And',
        'the (new) note:',
        docString: 'hi',
        dataTable: [
          ['a'],
        ],
      );

      // Act
      final snippet = generator.snippetFor(_undefined(step, type: StepKeywordType.context));

      // Assert
      expect(snippet.annotation, 'Given');
      expect(snippet.expression, r'the \(new) note:');
      expect(snippet.methodName, 'theNewNote');
      expect(snippet.parameters.map((p) => p.declaration), ['String docString', 'List<List<String>> dataTable']);
      expect(snippetCode(snippet, 'theNewNote').first, r"@Given(r'the \(new) note:')");
    });
  });
}
