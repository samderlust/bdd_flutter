import 'dart:io';

import '../../domain/build_options.dart';
import '../../domain/config.dart';
import '../../domain/feature.dart';
import '../../domain/manifest.dart';
import '../../domain/scenario.dart';
import '../../infrastructure/parsers/config_parser.dart';
import '../../infrastructure/parsers/feature_parser.dart';
import '../../infrastructure/parsers/manifest_parser.dart';
import '../../infrastructure/builders/scenario_file_builder.dart';
import '../../infrastructure/builders/test_file_builder.dart';

/// Orchestrates the BDD test generation pipeline.
///
/// Loads config and manifest, parses feature files, generates scenario
/// and test files, and updates the manifest. Supports incremental and
/// force generation modes.
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

  /// Generates test files from `.feature` files.
  ///
  /// In incremental mode (default), new scenarios are appended to existing
  /// scenario files and test files are regenerated. With [options.force],
  /// all files are regenerated from scratch.
  Future<void> generateFeatureTestCases({BuildOptions options = const BuildOptions()}) async {
    final config = await _configParser.loadConfig();
    final manifest = await _manifestParser.loadManifest();

    final testDir = Directory(config.testDir);
    if (!testDir.existsSync()) {
      stdout.writeln('Directory "${config.testDir}" not found.');
      return;
    }

    final featureFiles = testDir
        .listSync(recursive: true)
        .where((file) => file.path.endsWith('.feature'));

    if (featureFiles.isEmpty) {
      stdout.writeln('No .feature files found in "${config.testDir}".');
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

      if (options.force || existingEntry == null) {
        await _generateFull(feature, scenarioPath, testPath, config);
        stdout.writeln('  Generated: $scenarioPath');
        stdout.writeln('  Generated: $testPath');
        generated++;
        updatedFeatures.add(_buildManifestEntry(featureFile, feature, testPath, config));
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

      // Append new scenario classes to scenarios file
      final newScenarioContent = _scenarioFileBuilder.buildNewScenarios(
        feature,
        newScenarios,
        scenarioSuffix: config.scenarioSuffix,
      );
      final scenarioFile = File(scenarioPath);
      if (scenarioFile.existsSync()) {
        await scenarioFile.writeAsString(
          '${await scenarioFile.readAsString()}\n$newScenarioContent',
        );
      } else {
        await _generateFull(feature, scenarioPath, testPath, config);
        stdout.writeln('  Generated: $scenarioPath');
        stdout.writeln('  Generated: $testPath');
        generated++;
        updatedFeatures.add(_buildManifestEntry(featureFile, feature, testPath, config));
        continue;
      }

      // Test file is always fully regenerated
      final testContent = await _testFileBuilder.buildTestFile(
        feature,
        scenarioSuffix: config.scenarioSuffix,
      );
      await File(testPath).writeAsString(testContent);

      final newNames = newScenarios.map((s) => s.name).join(', ');
      stdout.writeln('  Appended new scenarios to: $scenarioPath ($newNames)');
      stdout.writeln('  Regenerated: $testPath');
      appended++;

      updatedFeatures.add(_buildManifestEntry(featureFile, feature, testPath, config));
    }

    final updatedManifest = Manifest(features: updatedFeatures);
    await _manifestParser.saveManifest(updatedManifest);

    final parts = <String>[];
    if (generated > 0) parts.add('Generated: $generated');
    if (appended > 0) parts.add('Appended: $appended');
    if (skipped > 0) parts.add('Skipped: $skipped');
    stdout.writeln('Done. ${parts.join(', ')}.');
  }

  Future<void> _generateFull(
    Feature feature,
    String scenarioPath,
    String testPath,
    BDDConfig config,
  ) async {
    final scenarioContent = await _scenarioFileBuilder.buildScenarioFile(
      feature,
      additionalImports: config.additionalImports,
      scenarioSuffix: config.scenarioSuffix,
    );
    final testContent = await _testFileBuilder.buildTestFile(
      feature,
      scenarioSuffix: config.scenarioSuffix,
    );
    await File(scenarioPath).writeAsString(scenarioContent);
    await File(testPath).writeAsString(testContent);
  }

  ManifestFeature _buildManifestEntry(
    FileSystemEntity featureFile,
    Feature feature,
    String testPath,
    BDDConfig config,
  ) {
    return ManifestFeature(
      path: featureFile.path,
      lastModified: featureFile.statSync().modified.toIso8601String(),
      testFile: testPath,
      scenarios: feature.scenarios
          .map((s) => ManifestScenario(
                name: s.name,
                hash: s.getHash,
                testMethod: 'test${s.classNameWithSuffix(config.scenarioSuffix)}',
              ))
          .toList(),
    );
  }
}
