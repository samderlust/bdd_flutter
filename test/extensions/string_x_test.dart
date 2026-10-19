import 'package:bdd_flutter/src/extensions/string_x.dart';
import 'package:test/test.dart';

void main() {
  group('StringX.name (PascalCase)', () {
    test('converts simple words', () {
      expect('successful login'.name, equals('SuccessfulLogin'));
    });

    test('handles single word', () {
      expect('login'.name, equals('Login'));
    });

    test('prefixes with X when starting with digit', () {
      expect('123 login'.name, equals('X123Login'));
    });

    test('prefixes with X when all digits', () {
      expect('123'.name, equals('X123'));
    });

    test('strips special characters', () {
      expect('hello-world'.name, equals('HelloWorld'));
    });

    test('strips exclamation and other punctuation', () {
      expect('with special!chars'.name, equals('WithSpecialChars'));
    });

    test('returns Unnamed for empty string', () {
      expect(''.name, equals('Unnamed'));
    });

    test('returns Unnamed for whitespace only', () {
      expect('   '.name, equals('Unnamed'));
    });

    test('handles mixed digits and words', () {
      expect('step 2 verify'.name, equals('Step2Verify'));
    });

    test('handles leading spaces', () {
      expect('  login page'.name, equals('LoginPage'));
    });

    test('handles multiple spaces between words', () {
      expect('login   page'.name, equals('LoginPage'));
    });
  });

  group('StringX.name with accents and other scripts', () {
    test('folds accents instead of splitting words', () {
      expect('Incrémenter'.name, equals('Incrementer'));
    });

    test('folds stacked Vietnamese diacritics', () {
      expect('Tiếng Việt'.name, equals('TiengViet'));
    });

    test('uses a stable hash for text without Latin letters', () {
      expect('カウンター'.name, equals('X${'カウンター'.shortHash}'));
      expect('カウンター'.name, matches(RegExp(r'^X[0-9a-f]{6}$')));
    });
  });

  group('StringX.shortHash', () {
    test('matches the 32-bit FNV-1a reference values', () {
      expect(''.shortHash, '811c9d');
      expect('a'.shortHash, 'e40c29');
      expect('foobar'.shortHash, 'bf9cf9');
    });

    test('hashes UTF-8 bytes, so non-Latin text is stable', () {
      expect('カウンター'.shortHash, 'カウンター'.shortHash);
      expect('カウンター'.shortHash, isNot('カウンタ'.shortHash));
    });
  });

  group('StringX.toCamelIdentifier', () {
    test('joins words in camelCase', () {
      expect('I add an item'.toCamelIdentifier(), equals('iAddAnItem'));
    });

    test('joins words around an apostrophe', () {
      expect("j'incrémente le compteur".toCamelIdentifier(), equals('jincrementeLeCompteur'));
    });

    test('keeps inner capitals and lowers all-caps words', () {
      expect('sends a syncNote request'.toCamelIdentifier(), equals('sendsASyncNoteRequest'));
      expect('JSON payload'.toCamelIdentifier(), equals('jsonPayload'));
    });

    test('prefixes a leading digit', () {
      expect('3rd refund'.toCamelIdentifier(), equals('step3rdRefund'));
      expect('1st'.toCamelIdentifier(prefix: 'value'), equals('value1st'));
    });

    test('suffixes reserved words and Object members', () {
      expect('return'.toCamelIdentifier(), equals('returnStep'));
      expect('to string'.toCamelIdentifier(), equals('toStringStep'));
      expect('tester'.toCamelIdentifier(), equals('testerStep'));
    });

    test('returns null when nothing is left', () {
      expect('カウンター'.toCamelIdentifier(), isNull);
      expect(' %% '.toCamelIdentifier(), isNull);
    });
  });

  group('StringX.toDartStringLiteral', () {
    test('wraps plain text in single quotes', () {
      expect('hello'.toDartStringLiteral, equals("'hello'"));
    });

    test('escapes quotes, dollar signs, backslashes and line breaks', () {
      expect("it's \$5 \\ ok\nnext".toDartStringLiteral, equals(r"'it\'s \$5 \\ ok\nnext'"));
    });
  });
}
