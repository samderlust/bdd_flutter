import 'dart:io';
import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_factory.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:bdd_flutter/src/feature/builder/domain/manifest.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../constraints/file_extenstion.dart';
import '../extensions/string_x.dart';
import '../feature/logger/logger.dart';

/// Executes the build command to generate test files from feature files
Future<void> generate(List<String> arguments) async {
  final logger = CLILogger();
  final options = await _parseConfig(arguments);
  final factory = BDDFactory.create(options);
  final manifestManager = ManifestManager();
  final manifest = await manifestManager.readManifest();

  // Find all .feature files
  final features = Directory('test/').listSync(recursive: true).where((file) => file.path.endsWith('.feature')).toList();

  for (final feature in features) {
    _processFeature(feature: feature, options: options, factory: factory, logger: logger, manifest: manifest);
  }

  // Update manifest
  manifest.lastGenerated = DateTime.now();
  await manifestManager.writeManifest(manifest);
}

void _processFeature({
  required FileSystemEntity feature,
  required BDDOptions options,
  required BDDFactory factory,
  required CLILogger logger,
  required Manifest manifest,
}) async {
  final ignoredFiles = options.ignoreFeatures;

  final featureFile = File(feature.path);
  if (ignoredFiles.contains(feature.path)) {
    logger.logSkipping(feature.path, reason: 'ignored');
    return;
  }

  final featureContent = featureFile.readAsStringSync();
  final parsedFeature = factory.featureBuilder.parseFeature(featureContent);
  final lastModified = featureFile.lastModifiedSync();

  // Get paths for generated files
  final testFilePath = '${feature.path.replaceAll('.feature', '')}${FileExtension.generatedTest}';
  final scenariosFilePath = '${feature.path.replaceAll('.feature', '')}${FileExtension.generatedScenarios}';
  final testFile = File(testFilePath);
  final scenariosFile = File(scenariosFilePath);

  // Check if generated files exist
  final testFileExists = await testFile.exists();
  final scenariosFileExists = await scenariosFile.exists();
  final filesExist = testFileExists && scenariosFileExists;

  // Find existing feature entry
  final existingFeatureIndex = manifest.features.indexWhere((f) => f.path == feature.path);
  final existingFeature = existingFeatureIndex != -1 ? manifest.features[existingFeatureIndex] : null;

  if (options.force) {
    // Force regenerate everything
    logger.logProcessing(feature.path, reason: 'force regenerate');
    await _generateFeatureFiles(factory, parsedFeature, feature.path);
    _updateManifestEntry(manifest, feature.path, lastModified, parsedFeature);
  } else if (options.newOnly) {
    // Only generate for new features
    if (existingFeature == null) {
      logger.logProcessing(feature.path, reason: 'new feature');
      await _generateFeatureFiles(factory, parsedFeature, feature.path);
      _updateManifestEntry(manifest, feature.path, lastModified, parsedFeature);
    } else {
      logger.logSkipping(feature.path, reason: 'existing feature');
    }
  } else {
    // Incremental update
    if (!filesExist) {
      // Files don't exist, regenerate everything
      logger.logProcessing(feature.path, reason: 'missing generated files');
      await _generateFeatureFiles(factory, parsedFeature, feature.path);
      _updateManifestEntry(manifest, feature.path, lastModified, parsedFeature);
    } else if (existingFeature == null) {
      // Feature not in manifest, regenerate everything
      logger.logProcessing(feature.path, reason: 'not in manifest');
      await _generateFeatureFiles(factory, parsedFeature, feature.path);
      _updateManifestEntry(manifest, feature.path, lastModified, parsedFeature);
    } else if (lastModified.isAfter(existingFeature.lastModified)) {
      // Feature modified, check for scenario changes
      logger.logProcessing(feature.path, reason: 'modified since last generation');
      await _generateFeatureFiles(
        factory,
        parsedFeature,
        feature.path,
        existingScenarios: existingFeature.scenarios,
      );
      _updateManifestEntry(manifest, feature.path, lastModified, parsedFeature);
    } else {
      logger.logSkipping(feature.path, reason: 'unchanged');
    }
  }
}

void _updateManifestEntry(
  Manifest manifest,
  String featurePath,
  DateTime lastModified,
  dynamic parsedFeature,
) {
  final logger = CLILogger();
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
    logger.log('Updated manifest entry for: $featurePath');
  } else {
    manifest.features.add(featureEntry);
    logger.log('Added new manifest entry for: $featurePath');
  }
}

List<ScenarioEntry> _parseScenarios(dynamic parsedFeature) {
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

Future<void> _generateFeatureFiles(BDDFactory factory, dynamic parsedFeature, String featurePath, {List<ScenarioEntry>? existingScenarios}) async {
  final logger = CLILogger();
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
        logger.log('Scenario changed: ${current.name}');
      }
    }

    // Find new scenarios
    for (final current in currentScenarios) {
      if (!existingScenarios.any((s) => s.name == current.name)) {
        newScenarios.add(current);
        logger.log('New scenario: ${current.name}');
      }
    }
  } else {
    // If no existing scenarios, all are new
    newScenarios.addAll(currentScenarios);
  }

  if (changedScenarios.isEmpty && newScenarios.isEmpty) {
    logger.log('No changes detected in scenarios');
    return;
  }

  // Build scenarios file
  final scenarios = await factory.scenarioBuilder.buildScenarioFile(parsedFeature);
  final scenariosFile = File(scenariosFilePath);

  if (await scenariosFile.exists() && existingScenarios != null) {
    // Read existing file
    final existingContent = await scenariosFile.readAsString();
    final lines = existingContent.split('\n');

    // Update only changed scenarios
    for (final scenario in [...changedScenarios, ...newScenarios]) {
      final startLine = scenario.lineStart - 1;
      final endLine = scenario.lineEnd;

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
  logger.log('Updated scenarios file: $scenariosFilePath');

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
  logger.log('Updated test file: $testFilePath');
}

/// Parse configuration from .bdd_flutter/config.yaml and command line arguments
Future<BDDOptions> _parseConfig(List<String> arguments) async {
  // Start with default values from config file
  var options = await BDDOptions.fromConfig();

  // Override with command line arguments
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    switch (arg) {
      case '--no-widget-tests':
        options = options.copyWith(generateWidgetTests: false);
        break;
      case '--enable-reporter':
        options = options.copyWith(enableReporter: true);
        break;
      case '--ignore':
        if (i + 1 < arguments.length) {
          final newIgnores = List<String>.from(options.ignoreFeatures)..add(arguments[i + 1]);
          options = options.copyWith(ignoreFeatures: newIgnores);
          i++; // Skip the next argument as it's the feature to ignore
        }
        break;
      case '--force':
        options = options.copyWith(force: true);
        break;
      case '--new-only':
        options = options.copyWith(newOnly: true);
        break;
    }
  }

  return options;
}
