import 'dart:convert';
import 'dart:io';

import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_factory.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:bdd_flutter/src/feature/builder/domain/feature.dart';
import 'package:bdd_flutter/src/feature/builder/domain/manifest.dart';
import 'package:crypto/crypto.dart';

import '../constraints/file_extenstion.dart';
import '../extensions/string_x.dart';
import '../feature/logger/logger.dart';
import 'domain/cmd_flag.dart';

class BuildCommand {
  final CLILogger _logger;

  final ManifestManager _manifestManager;

  BuildCommand({
    CLILogger? logger,
    ManifestManager? manifestManager,
  })  : _logger = logger ?? CLILogger(),
        _manifestManager = manifestManager ?? ManifestManager();

  /// Executes the build command to generate test files from feature files
  Future<void> generate(List<CmdFlag> flags) async {
    final options = await _parseGeneratorOption(flags);
    final factory = BDDFactory.create(options);
    final manifest = await _manifestManager.readManifest();

    // Find all .feature files
    final features = Directory('test/').listSync(recursive: true).where((file) => file.path.endsWith('.feature')).toList();

    for (final feature in features) {
      await _processFeature(featurePath: feature.path, options: options, factory: factory, manifest: manifest);
    }

    // Update manifest
    manifest.lastGenerated = DateTime.now();
    await _manifestManager.writeManifest(manifest);
  }

  Future<void> _processFeature({
    required String featurePath,
    required BDDOptions options,
    required BDDFactory factory,
    required Manifest manifest,
  }) async {
    final ignoredFiles = options.ignoreFeatures;

    final featureFile = File(featurePath);
    if (ignoredFiles.contains(featurePath)) {
      _logger.logSkipping(featurePath, reason: 'ignored');
      return;
    }

    final featureFileName = featurePath.split('/').last.replaceAll('.feature', '');

    final featureContent = featureFile.readAsStringSync();
    final parsedFeature = await factory.featureBuilder.parseFeature(featureContent)
      ..setFileName(featureFileName);

    final lastModified = featureFile.lastModifiedSync();

    // Get paths for generated files
    final testFilePath = '${featurePath.replaceAll('.feature', '')}${FileExtension.generatedTest}';
    final scenariosFilePath = '${featurePath.replaceAll('.feature', '')}${FileExtension.generatedScenarios}';
    final testFile = File(testFilePath);
    final scenariosFile = File(scenariosFilePath);

    // Check if generated files exist
    final testFileExists = await testFile.exists();
    final scenariosFileExists = await scenariosFile.exists();
    final filesExist = testFileExists && scenariosFileExists;

    // Find existing feature entry
    final existingFeatureIndex = manifest.features.indexWhere((f) => f.path == featurePath);
    final existingFeature = existingFeatureIndex != -1 ? manifest.features[existingFeatureIndex] : null;

    if (options.force) {
      // Force regenerate everything
      _logger.logProcessing(featurePath, reason: 'force regenerate');
      await _generateFeatureFiles(factory, parsedFeature, featurePath);
      _updateManifestEntry(manifest, featurePath, lastModified, parsedFeature);
    } else if (options.newOnly) {
      // Only generate for new features
      if (existingFeature == null) {
        _logger.logProcessing(featurePath, reason: 'new feature');
        await _generateFeatureFiles(factory, parsedFeature, featurePath);
        _updateManifestEntry(manifest, featurePath, lastModified, parsedFeature);
      } else {
        _logger.logSkipping(featurePath, reason: 'existing feature');
      }
    } else {
      // Incremental update
      if (!filesExist) {
        // Files don't exist, regenerate everything
        _logger.logProcessing(featurePath, reason: 'missing generated files');
        await _generateFeatureFiles(factory, parsedFeature, featurePath);
        _updateManifestEntry(manifest, featurePath, lastModified, parsedFeature);
      } else if (existingFeature == null) {
        // Feature not in manifest, regenerate everything
        _logger.logProcessing(featurePath, reason: 'not in manifest');
        await _generateFeatureFiles(factory, parsedFeature, featurePath);
        _updateManifestEntry(manifest, featurePath, lastModified, parsedFeature);
      } else if (lastModified.isAfter(existingFeature.lastModified)) {
        // Feature modified, check for scenario changes
        _logger.logProcessing(featurePath, reason: 'modified since last generation');
        await _generateFeatureFiles(
          factory,
          parsedFeature,
          featurePath,
          existingScenarios: existingFeature.scenarios,
        );
        _updateManifestEntry(manifest, featurePath, lastModified, parsedFeature);
      } else {
        _logger.logSkipping(featurePath, reason: 'unchanged');
      }
    }
  }

  void _updateManifestEntry(
    Manifest manifest,
    String featurePath,
    DateTime lastModified,
    Feature parsedFeature,
  ) {
    final scenarios = _parseScenarios(parsedFeature);
    final testFile = '${featurePath.replaceAll('.feature', '')}${FileExtension.generatedTest}';

    final featureEntry = FeatureEntry(
      path: featurePath,
      lastModified: lastModified,
      testFile: testFile,
      scenarios: scenarios,
    );

    final existingIndex = manifest.features.indexWhere((f) => f.path == featurePath);
    if (existingIndex != -1) {
      manifest.features[existingIndex] = featureEntry;
      _logger.log('Updated manifest entry for: $featurePath');
    } else {
      manifest.features.add(featureEntry);
      _logger.log('Added new manifest entry for: $featurePath');
    }
  }

  List<ScenarioEntry> _parseScenarios(Feature parsedFeature) {
    final scenarios = <ScenarioEntry>[];
    var lineNumber = 1;
    for (final scenario in parsedFeature.scenarios) {
      final scenarioContent = scenario.toString();
      final hash = md5.convert(utf8.encode(scenarioContent)).toString();
      final startLine = lineNumber;
      final endLine = startLine + scenarioContent.split('\n').length - 1;
      final testMethod = 'test${scenario.name.replaceAll(' ', '')}';

      scenarios.add(ScenarioEntry(
        name: scenario.name,
        hash: hash,
        lineStart: startLine,
        lineEnd: endLine,
        testMethod: testMethod,
      ));

      lineNumber = endLine + 1;
    }
    return scenarios;
  }

  Future<void> _generateFeatureFiles(
    BDDFactory factory,
    Feature parsedFeature,
    String featurePath, {
    List<ScenarioEntry>? existingScenarios,
  }) async {
    final testFilePath = '${featurePath.replaceAll('.feature', '')}${FileExtension.generatedTest}';
    final scenariosFilePath = '${featurePath.replaceAll('.feature', '')}${FileExtension.generatedScenarios}';

    // Get current scenarios and their hashes
    final currentScenarios = _parseScenarios(parsedFeature);
    final changedScenarios = <ScenarioEntry>[];
    final newScenarios = <ScenarioEntry>[];

    if (existingScenarios != null) {
      // Find changed and new scenarios
      for (final current in currentScenarios) {
        final existing = existingScenarios.firstWhere(
          (s) => s.name == current.name,
          orElse: () => current,
        );

        if (existing.hash != current.hash) {
          changedScenarios.add(current);
          _logger.log('Scenario changed: ${current.name}');
        }
      }

      // Find new scenarios
      for (final current in currentScenarios) {
        if (!existingScenarios.any((s) => s.name == current.name)) {
          newScenarios.add(current);
          _logger.log('New scenario: ${current.name}');
        }
      }
    } else {
      // If no existing scenarios, all are new
      newScenarios.addAll(currentScenarios);
    }

    if (changedScenarios.isEmpty && newScenarios.isEmpty) {
      _logger.log('No changes detected in scenarios');
      return;
    }

    await _updateScenariosFile(factory, parsedFeature, scenariosFilePath, existingScenarios, changedScenarios, newScenarios);
    await _updateTestFile(factory, parsedFeature, testFilePath, existingScenarios, changedScenarios, newScenarios);
  }

  Future<void> _updateScenariosFile(
    BDDFactory factory,
    Feature parsedFeature,
    String scenariosFilePath,
    List<ScenarioEntry>? existingScenarios,
    List<ScenarioEntry> changedScenarios,
    List<ScenarioEntry> newScenarios,
  ) async {
    // Build scenarios file
    final scenarios = await factory.scenarioBuilder.buildScenarioFile(parsedFeature);
    final scenariosFile = File(scenariosFilePath);

    if (await scenariosFile.exists() && existingScenarios != null) {
      // Read existing file
      final existingContent = await scenariosFile.readAsString();
      final lines = existingContent.split('\n');

      // Update only changed scenarios
      for (final scenario in [...changedScenarios, ...newScenarios]) {
        // final startLine = scenario.lineStart - 1;
        // final endLine = scenario.lineEnd;

        // Find the scenario class in the existing content
        final scenarioClass = "class ${scenario.name.toScenarioClassName} {";
        final classStartIndex = lines.indexWhere((line) => line.contains(scenarioClass));

        if (classStartIndex != -1) {
          // Find the end of the class
          var classEndIndex = classStartIndex;
          while (classEndIndex < lines.length && !lines[classEndIndex].contains('}')) {
            classEndIndex++;
          }

          // Replace the scenario class content
          final newScenarioContent = scenarios.split('\n').where((line) => line.contains(scenarioClass)).join('\n');

          lines.removeRange(classStartIndex, classEndIndex + 1);
          lines.insert(classStartIndex, newScenarioContent);
        }
      }

      // Write updated content
      await scenariosFile.writeAsString(lines.join('\n'));
    } else {
      // Write new file
      await scenariosFile.writeAsString(scenarios);
    }

    _logger.log('Updated scenarios file: $scenariosFilePath');
  }

  Future<void> _updateTestFile(
    BDDFactory factory,
    Feature parsedFeature,
    String testFilePath,
    List<ScenarioEntry>? existingScenarios,
    List<ScenarioEntry> changedScenarios,
    List<ScenarioEntry> newScenarios,
  ) async {
    // Build test file
    final testFile = await factory.testFileBuilder.buildTestFile(parsedFeature);
    final testFileContent = File(testFilePath);

    if (await testFileContent.exists() && existingScenarios != null) {
      // Read existing file
      final existingContent = await testFileContent.readAsString();
      final lines = existingContent.split('\n');

      // Update only changed scenarios
      for (final scenario in [...changedScenarios, ...newScenarios]) {
        final testMethod = scenario.testMethod;
        final testStart = lines.indexWhere((line) => line.contains("$testMethod('${scenario.name}'"));

        if (testStart != -1) {
          // Find the end of the test
          var testEnd = testStart;
          while (testEnd < lines.length && !lines[testEnd].contains('});')) {
            testEnd++;
          }

          // Find the new test content
          final newTestContent = testFile.split('\n').where((line) => line.contains("$testMethod('${scenario.name}'")).join('\n');

          // Replace the test content
          lines.removeRange(testStart, testEnd + 1);
          lines.insert(testStart, newTestContent);
        }
      }

      // Write updated content
      await testFileContent.writeAsString(lines.join('\n'));
    } else {
      // Write new file
      await testFileContent.writeAsString(testFile);
    }
    _logger.log('Updated test file: $testFilePath');
  }

  Future<BDDOptions> _parseGeneratorOption(List<CmdFlag> flags) async {
    var options = await BDDOptions.fromConfig();

    for (final flag in flags) {
      switch (flag) {
        case CmdFlag.unitTest:
          options = options.copyWith(generateWidgetTests: false);
          break;
        case CmdFlag.reporter:
          options = options.copyWith(enableReporter: true);
          break;
        case CmdFlag.force:
          options = options.copyWith(force: true);
          break;
        case CmdFlag.newOnly:
          options = options.copyWith(newOnly: true);
          break;
        default:
          _logger.error('Invalid flag: ${flag.longForm}');
          break;
      }
    }

    return options;
  }
}
