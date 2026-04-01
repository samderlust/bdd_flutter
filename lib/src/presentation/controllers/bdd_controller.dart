import 'dart:io';

import '../../domain/build_options.dart';
import '../../domain/feature.dart';
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
    final config = await _configParser.loadConfig();
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
    int appended = 0;
    int skipped = 0;

    for (var featureFile in featureFiles) {
      final feature = await _featureParser.parseFeature(featureFile.path);

      if (config.ignoreFeatures.any((ignored) => featureFile.path.endsWith(ignored))) {
        stdout.writeln('  Skipped (config): ${featureFile.path}');
        skipped++;
        continue;
      }

      final existingEntry = _manifestParser.findFeature(manifest, featureFile.path);
      final scenarioPath = feature.path.replaceAll('.feature', '.bdd_scenarios.dart');
      final testPath = feature.path.replaceAll('.feature', '.bdd_test.dart');

      // New-only mode: skip if already in manifest
      if (options.newOnly && existingEntry != null) {
        stdout.writeln('  Skipped (existing): ${featureFile.path}');
        skipped++;
        updatedFeatures.add(existingEntry);
        continue;
      }

      // Force mode: regenerate everything
      if (options.force || existingEntry == null) {
        await _generateFull(feature, scenarioPath, testPath);
        stdout.writeln('  Generated: $scenarioPath');
        stdout.writeln('  Generated: $testPath');
        generated++;
        updatedFeatures.add(_buildManifestEntry(featureFile, feature, testPath));
        continue;
      }

      // Incremental mode: check what changed
      final manifestHashes = existingEntry.scenarios.map((s) => s.hash).toSet();
      final currentScenarios = feature.scenarios.toList();
      final newScenarios = currentScenarios.where((s) => !manifestHashes.contains(s.getHash)).toList();

      if (newScenarios.isEmpty) {
        stdout.writeln('  Skipped (unchanged): ${featureFile.path}');
        skipped++;
        updatedFeatures.add(existingEntry);
        continue;
      }

      // Append new scenario classes to scenarios file (preserve existing implementations)
      final newScenarioContent = _scenarioFileBuilder.buildNewScenarios(feature, newScenarios);
      final scenarioFile = File(scenarioPath);
      if (scenarioFile.existsSync()) {
        await scenarioFile.writeAsString(
          '${await scenarioFile.readAsString()}\n$newScenarioContent',
        );
      } else {
        // File was deleted — full generate
        await _generateFull(feature, scenarioPath, testPath);
        stdout.writeln('  Generated: $scenarioPath');
        stdout.writeln('  Generated: $testPath');
        generated++;
        updatedFeatures.add(_buildManifestEntry(featureFile, feature, testPath));
        continue;
      }

      // Test file is always fully regenerated (no user code in it)
      final testContent = await _testFileBuilder.buildTestFile(feature);
      await File(testPath).writeAsString(testContent);

      final newNames = newScenarios.map((s) => s.name).join(', ');
      stdout.writeln('  Appended new scenarios to: $scenarioPath ($newNames)');
      stdout.writeln('  Regenerated: $testPath');
      appended++;

      updatedFeatures.add(_buildManifestEntry(featureFile, feature, testPath));
    }

    final updatedManifest = Manifest(features: updatedFeatures);
    await _manifestParser.saveManifest(updatedManifest);

    final parts = <String>[];
    if (generated > 0) parts.add('Generated: $generated');
    if (appended > 0) parts.add('Appended: $appended');
    if (skipped > 0) parts.add('Skipped: $skipped');
    stdout.writeln('Done. ${parts.join(', ')}.');
  }

  Future<void> _generateFull(Feature feature, String scenarioPath, String testPath) async {
    final scenarioContent = await _scenarioFileBuilder.buildScenarioFile(feature);
    final testContent = await _testFileBuilder.buildTestFile(feature);
    await File(scenarioPath).writeAsString(scenarioContent);
    await File(testPath).writeAsString(testContent);
  }

  ManifestFeature _buildManifestEntry(FileSystemEntity featureFile, Feature feature, String testPath) {
    return ManifestFeature(
      path: featureFile.path,
      lastModified: featureFile.statSync().modified.toIso8601String(),
      testFile: testPath,
      scenarios: feature.scenarios
          .map((s) => ManifestScenario(
                name: s.name,
                hash: s.getHash,
                testMethod: 'test${s.className}',
              ))
          .toList(),
    );
  }
}
