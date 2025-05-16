import 'package:bdd_flutter/src/runner/domain/cmd_flag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CmdFlag', () {
    test('should create flag with correct properties', () {
      const flag = CmdFlag('--test', '-t', 'Test flag');
      expect(flag.longForm, equals('--test'));
      expect(flag.shortForm, equals('-t'));
      expect(flag.description, equals('Test flag'));
    });

    test('should create copy with modified properties', () {
      const original = CmdFlag('--test', '-t', 'Test flag');
      final copy = original.copyWith(
        text: '--new',
        shortText: '-n',
        description: 'New flag',
      );
      expect(copy.longForm, equals('--new'));
      expect(copy.shortForm, equals('-n'));
      expect(copy.description, equals('New flag'));
    });

    test('should maintain original properties when copying with null values', () {
      const original = CmdFlag('--test', '-t', 'Test flag');
      final copy = original.copyWith();
      expect(copy.longForm, equals(original.longForm));
      expect(copy.shortForm, equals(original.shortForm));
      expect(copy.description, equals(original.description));
    });

    test('should convert to string correctly', () {
      const flag = CmdFlag('--test', '-t', 'Test flag');
      expect(flag.toString(), equals('--test, -t, Test flag'));
    });
  });

  group('CmdFlag.fromString', () {
    test('should parse valid long form flag', () {
      final flag = CmdFlag.fromString('--help');
      expect(flag, equals(CmdFlag.help));
    });

    test('should parse valid short form flag', () {
      final flag = CmdFlag.fromString('-h');
      expect(flag, equals(CmdFlag.help));
    });

    test('should return invalid flag for unknown input', () {
      final flag = CmdFlag.fromString('--unknown');
      expect(flag.longForm, equals('--unknown'));
      expect(flag.shortForm, equals('--unknown'));
      expect(flag.description, equals('Invalid flag'));
    });

    test('should parse all predefined flags', () {
      for (final flag in CmdFlag.values) {
        expect(CmdFlag.fromString(flag.longForm), equals(flag));
        expect(CmdFlag.fromString(flag.shortForm), equals(flag));
      }
    });
  });

  group('CmdFlagValidator', () {
    test('should validate valid flags', () {
      final flags = [CmdFlag.help, CmdFlag.unitTest];
      expect(CmdFlagValidator.validate(flags), isNull);
    });

    test('should detect invalid flag', () {
      final flags = [CmdFlag.help, CmdFlag('--invalid', '-i', 'Invalid flag')];
      final error = CmdFlagValidator.validate(flags);
      expect(error, isNotNull);
      expect(error, contains('Invalid flag'));
    });

    test('should detect mutually exclusive flags', () {
      final flags = [CmdFlag.newOnly, CmdFlag.force];
      final error = CmdFlagValidator.validate(flags);
      expect(error, isNotNull);
      expect(error, contains('Cannot use --new with --force'));
    });

    test('should validate empty flag list', () {
      expect(CmdFlagValidator.validate([]), isNull);
    });

    test('should validate single valid flag', () {
      expect(CmdFlagValidator.validate([CmdFlag.help]), isNull);
    });
  });
}
