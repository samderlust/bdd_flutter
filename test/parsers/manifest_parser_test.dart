import 'dart:io';

import 'package:bdd_flutter/src/domain/manifest.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/manifest_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bdd_manifest_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  ManifestParser parserInDir() {
    return ManifestParser(
      manifestDir: '${tempDir.path}/.bdd_flutter',
      manifestFile: '${tempDir.path}/.bdd_flutter/manifest.yaml',
    );
  }

  group('ManifestParser', () {
    test('returns empty manifest when file does not exist', () async {
      final manifest = await parserInDir().loadManifest();

      expect(manifest.version, equals('1.0'));
      expect(manifest.features, isEmpty);
    });

    test('saves and loads manifest round-trip', () async {
      final parser = parserInDir();
      final manifest = Manifest(
        features: [
          ManifestFeature(
            path: 'test/counter/counter.feature',
            lastModified: '2025-05-04T10:27:15.000',
            testFile: 'test/counter/counter.bdd_test.dart',
            scenarios: [
              ManifestScenario(
                name: 'Increment',
                hash: 'abc123',
                testMethod: 'testIncrementScenario',
              ),
            ],
          ),
        ],
      );

      await parser.saveManifest(manifest);

      expect(File('${tempDir.path}/.bdd_flutter/manifest.yaml').existsSync(), isTrue);

      final loaded = await parser.loadManifest();

      expect(loaded.version, equals('1.0'));
      expect(loaded.features, hasLength(1));
      expect(loaded.features.first.path, equals('test/counter/counter.feature'));
      expect(loaded.features.first.lastModified, equals('2025-05-04T10:27:15.000'));
      expect(loaded.features.first.testFile, equals('test/counter/counter.bdd_test.dart'));
      expect(loaded.features.first.scenarios, hasLength(1));
      expect(loaded.features.first.scenarios.first.name, equals('Increment'));
      expect(loaded.features.first.scenarios.first.hash, equals('abc123'));
    });

    test('findFeature returns matching feature', () {
      final parser = parserInDir();
      final manifest = Manifest(
        features: [
          ManifestFeature(path: 'test/a.feature', lastModified: '', testFile: ''),
          ManifestFeature(path: 'test/b.feature', lastModified: '', testFile: ''),
        ],
      );

      final found = parser.findFeature(manifest, 'test/b.feature');
      expect(found, isNotNull);
      expect(found!.path, equals('test/b.feature'));
    });

    test('findFeature returns null for missing feature', () {
      final parser = parserInDir();
      final manifest = Manifest(features: []);

      expect(parser.findFeature(manifest, 'test/missing.feature'), isNull);
    });

    test('round-trip preserves lastGenerated timestamp', () async {
      final parser = parserInDir();
      final original = Manifest(
        version: '1.0',
        lastGenerated: DateTime.utc(2025, 1, 1, 12, 30, 45),
        features: [
          ManifestFeature(
            path: 'test/login/login.feature',
            lastModified: '2025-01-01T00:00:00.000',
            testFile: 'test/login/login.bdd_test.dart',
            scenarios: [
              ManifestScenario(
                name: 'Successful login',
                hash: 'abc123',
                testMethod: 'successfulLogin',
              ),
            ],
          ),
        ],
      );

      await parser.saveManifest(original);
      final loaded = await parser.loadManifest();

      expect(loaded.lastGenerated, equals(original.lastGenerated));
    });

    test('scenario name with double quotes survives round-trip', () async {
      final parser = parserInDir();
      final manifest = Manifest(features: [
        ManifestFeature(
          path: 'test/a.feature',
          lastModified: '',
          testFile: 'test/a.bdd_test.dart',
          scenarios: [
            ManifestScenario(
              name: 'User sees "Welcome" screen',
              hash: 'x',
              testMethod: 'userSeesWelcomeScreen',
            ),
          ],
        ),
      ]);

      await parser.saveManifest(manifest);
      final loaded = await parser.loadManifest();

      expect(
        loaded.features.first.scenarios.first.name,
        equals('User sees "Welcome" screen'),
      );
    });

    test('scenario name with colon survives round-trip', () async {
      final parser = parserInDir();
      final manifest = Manifest(features: [
        ManifestFeature(
          path: 'test/b.feature',
          lastModified: '',
          testFile: 'test/b.bdd_test.dart',
          scenarios: [
            ManifestScenario(
              name: 'Login: valid credentials',
              hash: 'y',
              testMethod: 'loginValidCredentials',
            ),
          ],
        ),
      ]);

      await parser.saveManifest(manifest);
      final loaded = await parser.loadManifest();

      expect(
        loaded.features.first.scenarios.first.name,
        equals('Login: valid credentials'),
      );
    });

    test('scenario name with backslash and newline survives round-trip', () async {
      final parser = parserInDir();
      final manifest = Manifest(features: [
        ManifestFeature(
          path: 'test/c.feature',
          lastModified: '',
          testFile: 'test/c.bdd_test.dart',
          scenarios: [
            ManifestScenario(
              name: 'Path C:\\Users with\nnewline',
              hash: 'z',
              testMethod: 'pathBackslashNewline',
            ),
          ],
        ),
      ]);

      await parser.saveManifest(manifest);
      final loaded = await parser.loadManifest();

      expect(
        loaded.features.first.scenarios.first.name,
        equals('Path C:\\Users with\nnewline'),
      );
    });

    test('feature path with space survives round-trip', () async {
      final parser = parserInDir();
      final manifest = Manifest(features: [
        ManifestFeature(
          path: 'test/my feature dir/some_thing.feature',
          lastModified: '',
          testFile: 'test/my feature dir/some_thing.bdd_test.dart',
          scenarios: [],
        ),
      ]);

      await parser.saveManifest(manifest);
      final loaded = await parser.loadManifest();

      expect(
        loaded.features.first.path,
        equals('test/my feature dir/some_thing.feature'),
      );
    });

    test('handles multiple features with multiple scenarios', () async {
      final parser = parserInDir();
      final manifest = Manifest(
        features: [
          ManifestFeature(
            path: 'test/a.feature',
            lastModified: '2025-01-01T00:00:00.000',
            testFile: 'test/a.bdd_test.dart',
            scenarios: [
              ManifestScenario(name: 'S1', hash: 'h1', testMethod: 'm1'),
              ManifestScenario(name: 'S2', hash: 'h2', testMethod: 'm2'),
            ],
          ),
          ManifestFeature(
            path: 'test/b.feature',
            lastModified: '2025-01-02T00:00:00.000',
            testFile: 'test/b.bdd_test.dart',
            scenarios: [
              ManifestScenario(name: 'S3', hash: 'h3', testMethod: 'm3'),
            ],
          ),
        ],
      );

      await parser.saveManifest(manifest);
      final loaded = await parser.loadManifest();

      expect(loaded.features, hasLength(2));
      expect(loaded.features[0].scenarios, hasLength(2));
      expect(loaded.features[1].scenarios, hasLength(1));
      expect(loaded.features[1].scenarios.first.name, equals('S3'));
    });
  });
}
