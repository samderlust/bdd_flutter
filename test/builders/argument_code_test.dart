import 'package:bdd_flutter/src/domain/matched_argument.dart';
import 'package:bdd_flutter/src/domain/parameter_type_definition.dart';
import 'package:bdd_flutter/src/domain/source_location.dart';
import 'package:bdd_flutter/src/infrastructure/builders/argument_code.dart';
import 'package:test/test.dart';

MatchedArgument _arg(String type, String text, Object? value) {
  return MatchedArgument(typeName: type, text: text, value: value);
}

void main() {
  group('argumentCode', () {
    test('writes built-in values as literals', () {
      expect(argumentCode(_arg('int', '2', 2)), '2');
      expect(argumentCode(_arg('int', '-3', -3)), '-3');
      expect(argumentCode(_arg('float', '1.5', 1.5)), '1.5');
      expect(argumentCode(_arg('float', '1', 1.0)), '1.0');
      expect(argumentCode(_arg('num', '2', 2)), '2');
      expect(argumentCode(_arg('bool', 'true', true)), 'true');
      expect(argumentCode(_arg('biginteger', '12', BigInt.from(12))), "BigInt.parse('12')");
    });

    test('escapes strings', () {
      expect(argumentCode(_arg('string', '"it\'s"', "it's")), r"'it\'s'");
      expect(argumentCode(_arg('word', r'$5', r'$5')), r"'\$5'");
      expect(argumentCode(_arg('', 'a b', 'a b')), "'a b'");
    });

    test('calls the parameter type method for custom types', () {
      // Arrange
      const type = ParameterTypeDefinition(
        name: 'money',
        regex: r'\$\d+',
        ownerName: 'SharedSteps',
        methodName: 'parseMoney',
        dartType: 'Money',
        location: SourceLocation('test/shared_steps.dart', 3),
      );
      const argument = MatchedArgument(typeName: 'money', text: r'$10', value: null, isCustom: true);

      // Act
      final code = argumentCode(argument, customType: type);

      // Assert
      expect(code, r"SharedSteps.parseMoney('\$10')");
    });
  });
}
