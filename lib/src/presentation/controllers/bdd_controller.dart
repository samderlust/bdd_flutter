import 'dart:io';

import '../../domain/build_options.dart';
import '../../domain/decorator.dart';
import '../../domain/manifest.dart';
import '../../domain/scenario.dart';
import '../../infrastructure/parsers/config_parser.dart';
import '../../infrastructure/parsers/feature_parser.dart';
import '../../infrastructure/parsers/manifest_parser.dart';
import '../../infrastructure/builders/scenario_file_builder.dart';
import '../../infrastructure/builders/test_file_builder.dart';

class BDDController {
  final FeatureParser _featureParser;
  final ScenariosFileBuilder _scenarioFileBuilder;
  final TestFileBuilder _testFileBuilder;
  final ConfigParser _configParser;
  final ManifestParser _manifestParser;

  BDDController({
    FeatureParser? featureParser,
    ScenariosFileBuilder? scenarioFileBuilder,
    TestFileBuilder? testFileBuilder,
    ConfigParser? configParser,
    ManifestParser? manifestParser,
  })  : _featureParser = featureParser ?? FeatureParser(),
        _scenarioFileBuilder = scenarioFileBuilder ?? ScenariosFileBuilder(),
        _testFileBuilder = testFileBuilder ?? TestFileBuilder(),
        _configParser = configParser ?? ConfigParser(),
        _manifestParser = manifestParser ?? ManifestParser();

  Future<void> generateFeatureTestCases({BuildOptions options = const BuildOptions()}) async {
    // Load config
    final config = await _configParser.loadConfig();

    // Load existing manifest
    final manifest = await _manifestParser.loadManifest();

    final featureFiles = Directory('test/')
        .listSync(recursive: true)
        .where((file) => file.path.endsWith('.feature'));

    if (featureFiles.isEmpty) {
      stdout.writeln('No .feature files found in test/ directory.');
      return;
    }

    stdout.writeln('Found ${featureFiles.length} feature file(s).');

    final updatedFeatures = <ManifestFeature>[];
    int generated = 0;
    int skipped = 0;

    for (var featureFile in featureFiles) {
      final feature = await _featureParser.parseFeature(featureFile.path);

      // Skip features with @ignore decorator
      if (feature.decorators.hasIgnore) {
        stdout.writeln('  Skipped (@ignore): ${featureFile.path}');
        skipped++;
        continue;
      }

      // Skip features in ignore_features config
      if (config.ignoreFeatures.any((ignored) => featureFile.path.endsWith(ignored))) {
        stdout.writeln('  Skipped (config): ${featureFile.path}');
        skipped++;
        continue;
      }

      final existingManifestEntry = _manifestParser.findFeature(manifest, featureFile.path);

      // Check generation mode
      if (options.newOnly && existingManifestEntry != null) {
        stdout.writeln('  Skipped (existing): ${featureFile.path}');
        skipped++;
        // Keep existing manifest entry
        updatedFeatures.add(existingManifestEntry);
        continue;
      }

      if (!options.force && existingManifestEntry != null) {
        // Incremental mode: check if feature has changed
        final fileLastModified = featureFile.statSync().modified.toIso8601String();
        if (existingManifestEntry.lastModified == fileLastModified) {
          // Check if all scenario hashes match
          final currentHashes = feature.scenarios.map((s) => s.getHash).toSet();
          final manifestHashes = existingManifestEntry.scenarios.map((s) => s.hash).toSet();
          if (currentHashes.length == manifestHashes.length &&
              currentHashes.containsAll(manifestHashes)) {
            stdout.writeln('  Skipped (unchanged): ${featureFile.path}');
            skipped++;
            updatedFeatures.add(existingManifestEntry);
            continue;
          }
        }
      }

      // Generate files
      final scenarioContent = await _scenarioFileBuilder.buildScenarioFile(feature);
      final testContent = await _testFileBuilder.buildTestFile(feature);

      final scenarioPath = feature.path.replaceAll('.feature', '.bdd_scenarios.dart');
      final testPath = feature.path.replaceAll('.feature', '.bdd_test.dart');

      await File(scenarioPath).writeAsString(scenarioContent);
      await File(testPath).writeAsString(testContent);

      stdout.writeln('  Generated: $scenarioPath');
      stdout.writeln('  Generated: $testPath');
      generated++;

      // Build manifest entry for this feature
      updatedFeatures.add(ManifestFeature(
        path: featureFile.path,
        lastModified: featureFile.statSync().modified.toIso8601String(),
        testFile: testPath,
        scenarios: feature.scenarios.map((s) => ManifestScenario(
          name: s.name,
          hash: s.getHash,
          testMethod: 'test${s.className}',
        )).toList(),
      ));
    }

    // Save updated manifest
    final updatedManifest = Manifest(
      features: updatedFeatures,
    );
    await _manifestParser.saveManifest(updatedManifest);

    stdout.writeln('Done. Generated: $generated, Skipped: $skipped.');
  }
}
