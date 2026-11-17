import 'package:bdd_flutter/src/domain/parameter_type_definition.dart';
import 'package:bdd_flutter/src/domain/source_location.dart';
import 'package:bdd_flutter/src/domain/step_definition.dart';
import 'package:bdd_flutter/src/domain/steps_class.dart';
import 'package:bdd_flutter/src/infrastructure/steps/step_matcher.dart';
import 'package:test/test.dart';

const SourceLocation _location = SourceLocation('test/cart/cart_steps.dart', 1);

StepDefinition _step(String expression, String method, {String owner = 'CartSteps'}) {
  return StepDefinition(
    expression: expression,
    ownerName: owner,
    methodName: method,
    parameters: const [],
    location: _location,
  );
}

ParameterTypeDefinition _type(String name, String regex, {String dartType = 'Object'}) {
  return ParameterTypeDefinition(
    name: name,
    regex: regex,
    ownerName: 'CartSteps',
    methodName: name,
    dartType: dartType,
    location: _location,
  );
}

StepsClass _class(List<StepDefinition> steps, {String name = 'CartSteps', List<ParameterTypeDefinition>? types}) {
  return StepsClass(name: name, path: _location.path, steps: steps, parameterTypes: types ?? const []);
}

void main() {
  group('StepMatcher', () {
    test('matches built-in types and converts their values', () {
      // Arrange
      final matcher = StepMatcher.build(
        own: _class([_step('I add {int} {string} at {float} each, {word} and {}', 'iAdd')]),
      );

      // Act
      final result = matcher.match('I add 2 "red apple" at 1.5 each, fast and very well');

      // Assert
      final match = result.single!;
      expect(match.definition.methodName, 'iAdd');
      expect(match.arguments.map((a) => a.typeName), ['int', 'string', 'float', 'word', '']);
      expect(match.arguments.map((a) => a.value), [2, 'red apple', 1.5, 'fast', 'very well']);
      expect(match.arguments[1].text, '"red apple"');
      expect(match.arguments.any((a) => a.isCustom), isFalse);
    });

    test('supports optional text and alternatives', () {
      // Arrange
      final matcher = StepMatcher.build(own: _class([_step('I have {int} cucumber(s) in my belly/stomach', 'iHave')]));

      // Act & Assert
      expect(matcher.match('I have 1 cucumber in my stomach').single!.arguments.single.value, 1);
      expect(matcher.match('I have 5 cucumbers in my belly').single!.arguments.single.value, 5);
      expect(matcher.match('I have 5 cucumbers in my head').isUndefined, isTrue);
    });

    test('adds {num} and {bool} for 2.x signatures', () {
      // Arrange
      final matcher = StepMatcher.build(own: _class([_step('the price is {num} and paid is {bool}', 'thePrice')]));

      // Act
      final arguments = matcher.match('the price is 2 and paid is true').single!.arguments;

      // Assert
      expect(arguments.map((a) => a.typeName), ['num', 'bool']);
      expect(arguments.map((a) => a.value), [2, true]);
      expect(arguments.first.value, isA<num>());
    });

    test('passes custom types through as text for their method to convert', () {
      // Arrange
      final matcher = StepMatcher.build(
        own: _class(
          [_step('the order is {status}', 'theOrderIs'), _step('I pay {money}', 'iPay')],
          types: [_type('status', 'shipped|pending'), _type('money', r'\$\d+\.\d{2}')],
        ),
      );

      // Act
      final status = matcher.match('the order is shipped').single!.arguments.single;
      final money = matcher.match(r'I pay $10.00').single!.arguments.single;

      // Assert
      expect(status.isCustom, isTrue);
      expect(status.typeName, 'status');
      expect(status.text, 'shipped');
      expect(status.value, isNull);
      expect(money.text, r'$10.00');
      expect(matcher.match('the order is lost').isUndefined, isTrue);
    });

    test('lets shared classes use types declared anywhere', () {
      // Arrange
      final shared = _class([_step('the order is {status}', 'theOrderIs', owner: 'SharedSteps')], name: 'SharedSteps');
      final own = _class(const [], types: [_type('status', 'shipped|pending')]);

      // Act
      final result = StepMatcher.build(own: own, shared: [shared]).match('the order is pending');

      // Assert
      expect(result.single!.definition.ownerName, 'SharedSteps');
      expect(result.single!.arguments.single.isCustom, isTrue);
    });

    test("prefers the feature's own class over shared classes", () {
      // Arrange
      final own = _class([_step('I am logged in', 'ownLogin')]);
      final shared = _class([_step('I am logged in', 'sharedLogin', owner: 'AuthSteps')], name: 'AuthSteps');

      // Act
      final result = StepMatcher.build(own: own, shared: [shared]).match('I am logged in');

      // Assert
      expect(result.isAmbiguous, isFalse);
      expect(result.single!.definition.methodName, 'ownLogin');
    });

    test('falls back to shared classes when the own class has no match', () {
      // Arrange
      final shared = _class([_step('I am logged in', 'iAmLoggedIn', owner: 'AuthSteps')], name: 'AuthSteps');

      // Act
      final result = StepMatcher.build(own: _class(const []), shared: [shared]).match('I am logged in');

      // Assert
      expect(result.single!.definition.ownerName, 'AuthSteps');
    });

    test('reports several matches in the same group as ambiguous', () {
      // Arrange
      final matcher = StepMatcher.build(
        own: _class([_step('I have {int} apples', 'a'), _step('I have {} apples', 'b')]),
      );

      // Act
      final result = matcher.match('I have 3 apples');

      // Assert
      expect(result.isAmbiguous, isTrue);
      expect(result.single, isNull);
      expect(result.matches.map((m) => m.definition.methodName), ['a', 'b']);
    });

    test('reports matches in two shared classes as ambiguous', () {
      // Arrange
      final first = _class([_step('I wait', 'a', owner: 'A')], name: 'A');
      final second = _class([_step('I wait', 'b', owner: 'B')], name: 'B');

      // Act
      final result = StepMatcher.build(shared: [first, second]).match('I wait');

      // Assert
      expect(result.isAmbiguous, isTrue);
    });

    test('reports invalid expressions and unknown types without failing', () {
      // Arrange & Act
      final matcher = StepMatcher.build(
        own: _class([_step('the order is {colour}', 'a'), _step('a (b', 'b'), _step('ok', 'c')]),
      );

      // Assert
      expect(matcher.problems, hasLength(2));
      expect(matcher.problems.first.message, contains("Undefined parameter type 'colour'"));
      expect(matcher.match('ok').single!.definition.methodName, 'c');
    });

    test('reports custom types that clash with built-ins, repeat or have a broken regex', () {
      // Arrange & Act
      final matcher = StepMatcher.build(
        own: _class(
          const [],
          types: [_type('int', r'\d+'), _type('status', 'a'), _type('status', 'b'), _type('bad', '(')],
        ),
      );

      // Assert
      expect(matcher.problems.map((p) => p.message), [
        contains("Parameter type 'int'"),
        contains("Parameter type 'status'"),
        contains("Invalid regex for parameter type 'bad'"),
      ]);
    });

    test('treats a value its type cannot convert as no match', () {
      // Arrange
      final matcher = StepMatcher.build(own: _class([_step('the account {int} exists', 'a')]));

      // Act
      final result = matcher.match('the account 12345678901234567890123 exists');

      // Assert
      expect(result.isUndefined, isTrue);
    });

    test('matches the whole text only', () {
      // Arrange
      final matcher = StepMatcher.build(own: _class([_step('I wait', 'iWait')]));

      // Act & Assert
      expect(matcher.match('I wait a bit').isUndefined, isTrue);
      expect(matcher.match('then I wait').isUndefined, isTrue);
    });
  });
}
