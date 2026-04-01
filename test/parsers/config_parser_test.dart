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

      expect(config.testDir, equals('test/'));
      expect(config.generateWidgetTests, isTrue);
      expect(config.ignoreFeatures, isEmpty);
      expect(config.additionalImports, isEmpty);
      expect(config.scenarioSuffix, equals('Scenario'));
    });

    test('parses config file with all options', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('''
generate_widget_tests: false
ignore_features:
  - test/features/login.feature
  - test/features/signup.feature
''');

      final config = await parserInDir().loadConfig();

      expect(config.generateWidgetTests, isFalse);
      expect(config.ignoreFeatures, hasLength(2));
      expect(config.ignoreFeatures, contains('test/features/login.feature'));
      expect(config.ignoreFeatures, contains('test/features/signup.feature'));
    });

    test('returns defaults for empty config file', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('');

      final config = await parserInDir().loadConfig();

      expect(config.generateWidgetTests, isTrue);
    });

    test('handles partial config', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('''
generate_widget_tests: false
''');

      final config = await parserInDir().loadConfig();

      expect(config.generateWidgetTests, isFalse);
      expect(config.ignoreFeatures, isEmpty);
      expect(config.testDir, equals('test/'));
      expect(config.scenarioSuffix, equals('Scenario'));
    });

    test('parses test_dir option', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('''
test_dir: "integration_test/"
''');

      final config = await parserInDir().loadConfig();

      expect(config.testDir, equals('integration_test/'));
    });

    test('parses additional_imports option', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('''
additional_imports:
  - "package:mocktail/mocktail.dart"
  - "test/helpers/test_helpers.dart"
''');

      final config = await parserInDir().loadConfig();

      expect(config.additionalImports, hasLength(2));
      expect(config.additionalImports, contains('package:mocktail/mocktail.dart'));
      expect(config.additionalImports, contains('test/helpers/test_helpers.dart'));
    });

    test('parses scenario_suffix option', () async {
      Directory('${tempDir.path}/.bdd_flutter').createSync();
      File('${tempDir.path}/.bdd_flutter/config.yaml').writeAsStringSync('''
scenario_suffix: "Steps"
''');

      final config = await parserInDir().loadConfig();

      expect(config.scenarioSuffix, equals('Steps'));
    });
  });
}
