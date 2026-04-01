import 'dart:io';

import 'package:bdd_flutter/src/infrastructure/parsers/config_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bdd_config_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  ConfigParser parserInDir() {
    return ConfigParser(configFile: '${tempDir.path}/.bdd_flutter/config.yaml');
  }

  group('ConfigParser', () {
    test('returns defaults when config file does not exist', () async {
      final config = await parserInDir().loadConfig();

      expect(config.generateWidgetTests, isTrue);
      expect(config.enableReporter, isFalse);
      expect(config.ignoreFeatures, isEmpty);
    });

    test('parses config file with all options', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('''
generate_widget_tests: false
enable_reporter: true
ignore_features:
  - test/features/login.feature
  - test/features/signup.feature
''');

      final config = await parserInDir().loadConfig();

      expect(config.generateWidgetTests, isFalse);
      expect(config.enableReporter, isTrue);
      expect(config.ignoreFeatures, hasLength(2));
      expect(config.ignoreFeatures, contains('test/features/login.feature'));
      expect(config.ignoreFeatures, contains('test/features/signup.feature'));
    });

    test('returns defaults for empty config file', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('');

      final config = await parserInDir().loadConfig();

      expect(config.generateWidgetTests, isTrue);
      expect(config.enableReporter, isFalse);
    });

    test('handles partial config', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('''
enable_reporter: true
''');

      final config = await parserInDir().loadConfig();

      expect(config.generateWidgetTests, isTrue);
      expect(config.enableReporter, isTrue);
      expect(config.ignoreFeatures, isEmpty);
    });
  });
}
